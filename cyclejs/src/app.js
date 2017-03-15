import {div} from '@cycle/dom'
import xs from 'xstream'
import debounce from 'xstream/extra/debounce'
import {html} from 'snabbdom-jsx'


const xx = "fixed"

function AutoComplete(props) {

    const data = (props.data || []).map((x, index) => <tr>
        <td className={xx+index}>{x}</td>
    </tr>)

    const input = (props.value) ?
        <input type="text" id="autocomplete-input" className="autocomplete" value={props.value}/> :
        <input type="text" id="autocomplete-input" className="autocomplete"/>;

    return (<div className="container">
        {input}
        <table className="highlight">
            <tbody>
            {data}
            </tbody>
        </table>
    </div>)
}


function appAtomStreams({DOM,HTTP}) {
    const http$ = HTTP.select('results')
        .flatten()
        .map(res => res.body.results)
        .startWith([])

    const staticInputStream$ = DOM
        .select(".autocomplete")
        .events("input")
        .map(ev => ev.target.value)
        .startWith("");

    const dynamicInputStream$ = http$.map(x => {
        const indexes = [];
        for (var i = 0; i < x.length; i++) {
            indexes.push(i)
        }

        return indexes.map(x => DOM.select("." + xx + x).events("click"))
            .reduce((x, y) => xs.merge(x, y), xs.never())
            .map(ev => ev.srcElement.innerText)
            .take(1)

    }).flatten();


    return {http$, staticInputStream$, dynamicInputStream$};
}


function appWriteToWorld({http$, staticInputStream$, dynamicInputStream$}) {

    const httpSinkStream$ = staticInputStream$
        .filter(x => x != "")
        .map(x => {
            return {
                url: './search/' + x,
                category: 'results',
                method: 'GET'
            }
        });

    const vdom$ = xs.merge(staticInputStream$, dynamicInputStream$, http$)
        .map(z => {
            return (typeof(z) == 'string') ? <AutoComplete value={z}/> :
                <AutoComplete data={z}/>
        });

    return {httpSinkStream$, vdom$};
}


export function App(sources) {

    const {vdom$, httpSinkStream$} = appWriteToWorld(appAtomStreams(sources));

    const sinks = {
        DOM: vdom$,
        HTTP: httpSinkStream$
    };
    return sinks
}
