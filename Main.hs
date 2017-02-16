{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
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

-- check if default exists
-- if not create file
getTrie :: IO (Either String STrie)
getTrie = doesFileExist dictionaryFile >>=
              (\x -> case x of False -> return $ Left "Dictionary File is missing!!!"
                               True -> doesFileExist defaultFileName >>=
                                       (\y -> case y of True ->  (Right . read) <$> (readFile defaultFileName) 
                                                        False -> listIntoTrie . lines <$> readFile dictionaryFile 
                                                                 >>= (\z -> writeFile defaultFileName (show z)
                                                                           >> return (Right z))))
-- damn there has to be a mempty for Result
main = do
         trie <- getTrie
         case trie of (Left x) -> putStrLn x 
                      (Right y) -> scotty 3000 $ get "/:word" $ param "word" 
                                                  >>= (\x -> if x == "" 
                                                               then json (Result {results = []})
                                                               else  json (Result {results = (autoComplete x y)}))

