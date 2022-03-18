{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE RecordWildCards #-}

module Main
  ( main,
  )
where

import Api (API, api)
import Control.Exception.Safe (MonadThrow)
import Control.Monad.IO.Class
  ( MonadIO,
    liftIO,
  )
import Control.Monad.Logger (runStderrLoggingT, LoggingT (LoggingT))
import Control.Monad.Reader
  ( MonadReader,
    ReaderT,
    ask,
    runReaderT,
  )
import Data.Function ((&))
import Data.Pool (Pool)
import qualified Database.Persist.Sql as PSql
import qualified Database.Persist.Sqlite as PSqlite
import qualified Network.Wai.Handler.Warp as Warp
import Network.Wai.Middleware.Cors
  ( cors,
    corsRequestHeaders,
    simpleCorsResourcePolicy,
  )
import Network.Wai.Middleware.Servant.Options (provideOptions)
import Servant.API ((:<|>) (..))
import qualified Servant.Server as Server
import System.IO
  ( BufferMode (LineBuffering),
    hSetBuffering,
    stdout,
  )
import Types (migrateAll)
import UnliftIO (MonadUnliftIO)
import UnliftIO.Resource (runResourceT)
import Data.Data (Data, Typeable)
import qualified System.Console.CmdArgs as A
import System.Console.CmdArgs ((&=))
import Data.String (IsString(fromString))
import Control.Monad (when)

data Args = Args
    { listen_port :: Int,
      listen_address :: String
    } deriving (Show, Data, Typeable)

getArgs :: IO (Args, A.Verbosity)
getArgs = do
  a <- A.cmdArgs $ Args
       { listen_port = 8080 &= A.help "Port to bind to (default 8080)" &= A.typ "NUMBER"
       , listen_address = "127.0.0.1" &= A.help "Interface to bind to (default 127.0.0.1)" &= A.typ "INTERFACE"
       }
       &= A.verbosity
       &= A.program "Backend"
  v <- A.getVerbosity
  return (a, v)


main :: IO ()
main = do
  hSetBuffering stdout LineBuffering
  (args@Args{..}, verbosity) <- getArgs

  when (verbosity /= A.Quiet) $
    putStrLn $ "Listening on " <> listen_address <> ":" <> show listen_port
  pool <- runResourceT $ runLogging (verbosity == A.Loud) $ PSqlite.createSqlitePool "sqlite.db" 5
  runDB pool $ PSqlite.runMigration migrateAll
  Warp.runSettings (settings args (verbosity == A.Loud)) $ app Options {dbPool = pool}
  where
    settings Args{..} verbose =
      Warp.defaultSettings
        & Warp.setPort listen_port
        & Warp.setHost (fromString listen_address)
        & Warp.setOnOpen
          ( if not verbose
            then \_ -> return True
            else \sockaddr -> do
              putStrLn $ "New connection from " <> show sockaddr
              return True
          )
        & Warp.setLogger
          ( if not verbose
            then \_ _ _ -> return ()
            else \request status fileSize ->
              putStrLn $
                ">> request: "
                  <> show request
                  <> "\n>> status: "
                  <> show status
                  <> "\n>> file size: "
                  <> show fileSize
          )

    runLogging :: MonadIO m => Bool -> LoggingT m a -> m a
    runLogging False = \(LoggingT f) -> f $ \_ _ _ _ -> return ()
    runLogging True = runStderrLoggingT

newtype App a = App
  { runApp :: ReaderT Options IO a
  }
  deriving (Monad, Functor, Applicative, MonadReader Options, MonadIO, MonadThrow)

data Options = Options
  { dbPool :: Pool PSql.SqlBackend
  }

runDB :: MonadUnliftIO m => Pool PSql.SqlBackend -> (ReaderT PSql.SqlBackend m a) -> (m a)
runDB = flip PSql.runSqlPool

app :: Options -> Server.Application
app options =
  cors (const $ Just policy) $
    provideOptions api $
      Server.serve api $
        Server.hoistServer api (readerToHandler options) server
  where
    policy =
      simpleCorsResourcePolicy
        { corsRequestHeaders = ["content-type"]
        }

readerToHandler :: Options -> App a -> Server.Handler a
readerToHandler options r = liftIO $ runReaderT (runApp r) options

server :: Server.ServerT API App
server = list :<|> add :<|> remove
  where
    list = do
      Options {dbPool} <- ask
      liftIO $ runDB dbPool $ PSql.selectList [] []
    add item = do
      Options {dbPool} <- ask
      liftIO $ runDB dbPool $ PSql.insert item
    remove itemId = do
      Options {dbPool} <- ask
      liftIO $ runDB dbPool $ PSql.delete itemId
