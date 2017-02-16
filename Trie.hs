-- taken from gist: https://gist.github.com/orclev/1929451
-- the Author (git user name: ) orclev

module Trie (STrie, emptyTrie, insert, autoComplete) where

import Data.Maybe
import Control.Monad (liftM)
import Data.List (isPrefixOf)
import qualified Data.Map as M
import qualified Data.Foldable as F

-- | Trie container data type
data Trie a = Trie { value    :: Maybe a
                   , children :: M.Map Char (Trie a) }
              deriving (Show, Read)

-- | Convenience name for our autocompletion trie
type STrie = Trie (String, Bool)

-- | Mark this value as the end of a word
setEndOfWord :: Maybe (String, Bool) -> Maybe (String, Bool)
setEndOfWord = liftM update
  where
    update (s, _) = (s, True)

{-| Convenience function, simply reverses 
 the order of foldr's arguments -}
ifold :: F.Foldable t => (a -> b -> b) -> t a -> b -> b
ifold = flip . F.foldr

{-| Foldable instance for Trie. Folds over the 
 contents of the trie. -}
instance F.Foldable Trie where
    foldr f b t | isJust (value t) 
                      = let thisNode = f (fromJust . value $ t) b
                            childNodes = ifold f
                        in F.foldr childNodes thisNode (children t)
                | otherwise           
                      = F.foldr (ifold f) b (children t)

-- | Convenience function to construct an empty trie
emptyTrie :: STrie
emptyTrie = Trie { value = Nothing
                 , children = M.empty }

{-| Convenience function to construct a new 
  autocompletion trie with a String in it -}
trie :: String -> STrie
trie k = emptyTrie { value = Just (k, False) }

-- Insert a String into the autocompletion trie
insert :: String -> STrie -> STrie
insert []     t = t { value = setEndOfWord $ value t }
insert (k:ks) t = let ts = children t
                      childNode = maybe (trie [k]) 
                                        (trie . (++[k]) . fst) 
                                        (value t)
                      newChildren = M.insert k childNode ts
                  in case M.lookup k ts of
                         Nothing -> t { children = M.insert k (insert ks childNode) newChildren }
                         Just t' -> t { children = M.insert k (insert ks t') ts }

-- Find the node that matches this string if any
find :: String -> STrie -> Maybe (String, Bool)
find s t = findPrefix s t >>= value

-- Get all the prefixes that are in this trie
allPrefixes :: STrie -> [String]
allPrefixes = map fst . filter snd . F.toList

findPrefix :: String -> STrie -> Maybe STrie
findPrefix []     t = Just t
findPrefix (k:ks) t = case M.lookup k (children t) of
                          Nothing -> Nothing
                          Just t' -> findPrefix ks t'

-- Get all the prefixes that start with this string
autoComplete :: String -> STrie -> [String]
autoComplete s t = maybe [] allPrefixes $ findPrefix s t

