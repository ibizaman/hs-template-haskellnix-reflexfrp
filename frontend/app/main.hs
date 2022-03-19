{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE KindSignatures            #-}
{-# LANGUAGE NamedFieldPuns            #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE RankNTypes                #-}
{-# LANGUAGE RecordWildCards           #-}
{-# LANGUAGE RecursiveDo               #-}
{-# LANGUAGE ScopedTypeVariables       #-}

module Main where

import           Api               (API)
import           Control.Monad.Fix (MonadFix)
import           Data.Kind         (Type)
import           Data.Map          (Map)
import qualified Data.Map          as Map
import           Data.Proxy        (Proxy (Proxy))
import qualified Data.Set          as Set
import           Data.Text         (Text, pack, unpack)
import           Map               (dynamicMap)
import qualified Reflex            as R
import qualified Reflex.Dom        as Dom
import           Servant.API       ((:<|>) (..))
import qualified Servant.Reflex    as SR
import           Types             (Entity, Item (..), ItemId, itemListToMap)

main :: IO ()
main = Dom.mainWidget run

run ::
  ( Dom.DomBuilder t m,
    SR.SupportsServantReflex t m,
    Dom.MonadHold t m,
    Dom.PostBuild t m,
    MonadFix m
  ) =>
  m ()
run = do
  settings <- settingsTab $ SR.BasePath "http://127.0.0.1:8080"
  mainTab settings

settingsTab ::
  ( Dom.DomBuilder t m
  ) =>
  SR.BaseUrl ->
  m (Dom.Dynamic t SR.BaseUrl)
settingsTab defUrl = Dom.el "div" $ do
  Dom.text "Backend address:"
  fmap SR.BasePath . Dom.value <$> Dom.inputElement Dom.def { Dom._inputElementConfig_initialValue = SR.showBaseUrl defUrl }


data APIRecord t m = APIRecord
  { apiList :: SR.SupportsServantReflex t m =>
      Dom.Event t () ->
      m (Dom.Event t (SR.ReqResult () [Entity Item]))
  , apiAdd ::
      SR.SupportsServantReflex t m =>
      Dom.Dynamic t (Either Text Item) ->
      Dom.Event t Item ->
      m (Dom.Event t (SR.ReqResult Item ItemId))
  , apiRemove ::
      SR.SupportsServantReflex t m =>
      Dom.Dynamic t (Either Text ItemId) ->
      Dom.Event t ItemId ->
      m (Dom.Event t (SR.ReqResult ItemId ()))
  }

buildAPI :: Dom.Dynamic t SR.BaseUrl -> APIRecord t m
buildAPI url =
  let
    apiList :<|> apiAdd :<|> apiRemove =
      SR.client
        (Proxy :: Proxy API)
        (Proxy :: Proxy (m :: Type -> Type))
        (Proxy :: Proxy tag)
        url
  in
    APIRecord {..}

mainTab ::
  ( Dom.DomBuilder t m,
    SR.SupportsServantReflex t m,
    Dom.MonadHold t m,
    Dom.PostBuild t m,
    MonadFix m
  ) =>
  Dom.Dynamic t SR.BaseUrl ->
  m ()
mainTab url = Dom.el "div" $
  let
    api = buildAPI url
  in do
    newItemEvent <- addWidget api
    _ <- listWidget api newItemEvent
    return ()



-- | Widget that maintains a list of item from the backend.
listWidget ::
  ( SR.SupportsServantReflex t m,
    Dom.DomBuilder t m,
    Dom.MonadHold t m,
    Dom.PostBuild t m,
    MonadFix m
  ) =>
  APIRecord t m ->
  Dom.Event t (Map ItemId Item) ->
  m ()
listWidget APIRecord{..} newEvent = do
  rec butn <- Dom.button "Refresh"
      onload <- R.getPostBuild
      replaceEvent :: (R.Event t (Map ItemId Item)) <-
        fmap itemListToMap <$> R.fmapMaybe SR.reqSuccess <$> apiList (R.leftmost [onload, butn])
      itemMap :: R.Dynamic t (Map.Map ItemId Item) <-
        dynamicMap Map.empty replaceEvent newEvent deleteEvent
      deleteEvent' :: R.Dynamic t (Map.Map ItemId (R.Event t ItemId)) <-
        Dom.el "ul" $
          Dom.listWithKey itemMap $
            \itemId item -> Dom.el "li" $ do
              Dom.dynText $ fmap (pack . itemName) item
              delbutn <- Dom.button "X"
              R.fmapMaybe (fmap snd . success)
                <$> apiRemove
                  (R.constDyn $ Right itemId)
                  (R.tagPromptlyDyn (R.constDyn itemId) delbutn)
      let deleteEvent =
            R.switch . R.current $
              fmap
                (R.mergeWith (<>) . fmap (fmap Set.singleton) . Map.elems)
                deleteEvent'
  return ()

-- | Widget that adds a item to the backend.
addWidget ::
  ( SR.SupportsServantReflex t m,
    Dom.DomBuilder t m
  ) =>
  APIRecord t m ->
  m (Dom.Event t (Map ItemId Item))
addWidget APIRecord{apiAdd} = Dom.el "div" $ do
  uName <- fmap (Item . unpack) . Dom.value <$> Dom.inputElement Dom.def
  butn <- Dom.button "Add Item"
  fmap (uncurry Map.singleton) <$> R.fmapMaybe success <$> apiAdd (fmap Right uName) (R.tagPromptlyDyn uName butn)

success :: SR.ReqResult a k -> Maybe (k, a)
success (SR.ResponseSuccess v tag _) = Just (tag, v)
success _                            = Nothing
