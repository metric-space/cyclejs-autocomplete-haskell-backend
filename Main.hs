{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE BangPatterns #-}
 
import Web.Scotty
import Trie
import System.Directory
import Data.Aeson (ToJSON,)
import GHC.Generics
import Network.Wai.Middleware.Static

data Result = Result { results :: [String] } deriving (Show, Generic)

instance ToJSON Result

dictionaryFile :: String
dictionaryFile = "dictionary.txt"

staticDirectory :: String
staticDirectory = "/static"


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
                  (\z -> do
                           let content = listIntoTrie $ lines z
                           return (Right content))


-- damn there has to be a mempty for Result
autoCompletePath :: String -> STrie -> ActionM () 
autoCompletePath x y = if x == "" 
                        then json (Result {results = []}) 
                        else  json (Result {results = (take 10 (autoComplete x y))})

-- server routes
routes :: String -> STrie -> ScottyM ()
routes x y = do
             middleware $ staticPolicy (noDots >-> addBase (x ++ staticDirectory))
             get "/" $ file "./static/index.html"
             get "/search/:word" $ param "word" >>= ((flip autoCompletePath) y)

main = do
       cwd <- getCurrentDirectory 
       getTrie >>= either putStrLn (\x -> scotty 3000 (routes cwd x)) 
