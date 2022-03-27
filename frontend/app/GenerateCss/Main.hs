{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE RecordWildCards    #-}

module Main (main) where

import           Control.Monad          (when)
import           Css                    (css, render)
import           Data.Data              (Data, Typeable)
import qualified Data.Text.Lazy         as T
import           System.Console.CmdArgs ((&=))
import qualified System.Console.CmdArgs as A
import           System.Directory       (createDirectoryIfMissing,
                                         doesFileExist)
import           System.FilePath        (takeDirectory)

data Args = Args
    { output_file :: FilePath
    , overwrite   :: Bool
    } deriving (Show, Data, Typeable)

getArgs :: IO Args
getArgs = A.cmdArgs $ Args
          { output_file = "css/main.css" &= A.help "Output file for css"
          , overwrite = False &= A.help "Overwrite file"
          }
          &= A.program "Generate CSS for ExternalCss"

main :: IO ()
main = do
  Args{..} <- getArgs
  let dir_ = takeDirectory output_file
  createDirectoryIfMissingWithParent dir_
  guardOverwrite overwrite output_file
  let content_ = render css
  writeFile output_file (T.unpack content_)

guardOverwrite :: Bool -> FilePath -> IO ()
guardOverwrite overwrite output_file = do
  exists <- doesFileExist output_file
  when (not overwrite && exists) $ do
    error $ "File " <> output_file <> " exists already, use --overwrite to overwrite it"

createDirectoryIfMissingWithParent :: FilePath -> IO ()
createDirectoryIfMissingWithParent = createDirectoryIfMissing True
