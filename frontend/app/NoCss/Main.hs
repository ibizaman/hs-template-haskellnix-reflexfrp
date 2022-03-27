module Main (main) where

import qualified App
import qualified Reflex.Dom as Dom

main :: IO ()
main = Dom.mainWidget App.run
