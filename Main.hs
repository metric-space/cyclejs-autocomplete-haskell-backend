{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE BangPatterns #-}
 
import Web.Scotty
import Trie
import System.Directory
import Data.Aeson (ToJSON,)
import GHC.Generics

data Result = Result { results :: [String] } deriving (Show, Generic)

instance ToJSON Result

defaultFileName :: String
defaultFileName = "trie.txt"

dictionaryFile :: String
dictionaryFile = "dictionary.txt"

listIntoTrie :: [String] -> STrie
listIntoTrie =  foldr (\x a -> insert x a ) emptyTrie 

-- convenience function
getFile :: String -> IO (Either String String)
getFile fileName = doesFileExist dictionaryFile >>= 
                      (\x -> case x of False -> return (Left $ fileName ++ " Not found!")
                                       True ->  Right <$> readFile fileName)

-- check if default exists
-- if not create file
getTrie :: IO (Either String STrie)
getTrie = getFile dictionaryFile >>= 
              either 
                  (return . Left)
                  (\z -> getFile defaultFileName >>= 
                           either 
                             (\_ -> do
                                     let content = listIntoTrie $ lines z
                                     writeFile defaultFileName (show content)
                                     return (Right content))
                             (\g -> do
                                     let !stuff = read g
                                     return (Right stuff)))


-- damn there has to be a mempty for Result
autoCompletePath :: String -> STrie -> ActionM () 
autoCompletePath x y = if x == "" 
                        then json (Result {results = []}) 
                        else  json (Result {results = (autoComplete x y)})

-- server routes
routes :: STrie -> ScottyM ()
routes x = get "/:word" $ param "word" >>= ((flip autoCompletePath) x)

main = getTrie >>= either putStrLn (\x -> scotty 3000 (routes x)) 
