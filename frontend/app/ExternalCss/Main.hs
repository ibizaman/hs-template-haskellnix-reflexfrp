module Main (main) where

import qualified App
import           Data.Map   (Map)
import           Data.Text  (Text)
import           Reflex.Dom ((=:))
import qualified Reflex.Dom as Dom


main :: IO ()
main = Dom.mainWidgetWithHead
       (do
         Dom.el "title" $ Dom.text "Template Project"
         stylesheet_ "css/main.css"
       )
       App.run

stylesheet_ :: Dom.DomBuilder t m => Text -> m ()
stylesheet_ l = Dom.elAttr "link" ss $ pure ()
  where
    ss :: Map Text Text
    ss = "rel"  =: "stylesheet"
      <> "type" =: "text/css"
      <> "href" =: l
