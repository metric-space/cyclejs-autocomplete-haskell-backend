import {div} from '@cycle/dom'
import xs from 'xstream'
import debounce from 'xstream/extra/debounce'
import {html} from 'snabbdom-jsx'


const xx = "fixed"

function AutoComplete(props){

  const condition = (props.data.length == 1 && props.value == props.data[0])

  const data = condition? [] : (props.data || []).map((x,index) => <tr><td className={xx+index}>{x}</td></tr>)
  
  return (<div className="container">
	     <input type="text" id="autocomplete-input" className="autocomplete" value={props.value} />
	     <table className="highlight">
	      <tbody>
	       {data}
              </tbody>
	     </table>
	  </div>)
}

export function App (sources) {

  const http$ = sources.HTTP.select('results')
          .flatten()
          .map(res => res.body.results)
	  .startWith([])
	  .debug()

  const inputStream$ = sources
          .DOM
	  .select(".autocomplete")
	  .events("input")
	  .map(ev => ev.target.value)
	  .startWith("")

  const chickenStream$ = http$.map(x => {
        const indexes = []
	console.log(x.length)
        for (var i = 0; i < x.length ; i++ ){
             indexes.push(i)
        }
   
        return indexes.map(x => sources.DOM.select("."+xx+x).events("click"))
	              .reduce((x,y) => xs.merge(x,y), xs.never())
	              .map(ev => ev.srcElement.innerText)
                      .take(1)

   }).flatten()


   const mergedStream$ =  xs.merge(inputStream$, chickenStream$);

  const httpSinkStream$ = mergedStream$
        .filter(x => x != "")
        .map(x => {
            return {
                url: 'http://localhost:3000/search/' + x,
                category: 'results',
                method: 'GET' }
	})

  const vdom$ =  xs.combine(mergedStream$,http$)
          .map(z => {
	     return <AutoComplete data={z[1]} value={z[0]} />
           })
  
  const sinks = {
    DOM:  vdom$,
    HTTP: httpSinkStream$
  }
  return sinks
}
