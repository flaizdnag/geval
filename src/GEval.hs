module GEval
    ( geval,
      gevalCore,
      Metric(..),
      GEvalSpecification(..),
      GEvalOptions(..),
      defaultGEvalSpecification,
      defaultOutDirectory,
      defaultTestName,
      defaultOutFile,
      defaultExpectedFile,
      defaultMetric
    ) where

import Data.Conduit
import Data.Conduit.Combinators as CC
import qualified Data.Conduit.Binary as CB
import qualified Data.Conduit.Text as CT
import Control.Monad.Trans.Resource
import qualified Data.Conduit.List as CL
import Data.Text
import Data.Text.Read as TR
import Control.Applicative
import Control.Exception
import Control.Conditional (unlessM)
import qualified System.Directory as D

import System.FilePath
import Data.Maybe

data Metric = MSE | BLEU
              deriving (Show, Read)

defaultOutDirectory = "."
defaultTestName = "test-A"
defaultOutFile = "out.tsv"
defaultExpectedFile = "expected.tsv"

defaultMetric :: Metric
defaultMetric = MSE


data GEvalSpecification = GEvalSpecification
                          { gesOutDirectory :: String,
                            gesExpectedDirectory :: Maybe String,
                            gesTestName :: String,
                            gesOutFile :: String,
                            gesExpectedFile :: String,
                            gesMetric :: Metric }

data GEvalOptions = GEvalOptions
                    { geoInit :: Bool,
                      geoSpec :: GEvalSpecification }


data GEvalException = NoExpectedFile FilePath
                      | NoOutFile FilePath
                      | NoExpectedDirectory FilePath
                      | NoOutDirectory FilePath
                      | NoExpectedTestDirectory FilePath
                      | NoOutTestDirectory FilePath

instance Exception GEvalException

instance Show GEvalException where
  show (NoExpectedFile filePath) = somethingWrongWithFilesMessage "No file with the expected results" filePath
  show (NoOutFile filePath) = somethingWrongWithFilesMessage "No file with the test results" filePath
  show (NoExpectedDirectory filePath) = somethingWrongWithFilesMessage "No directory with the expected results" filePath
  show (NoOutDirectory filePath) = somethingWrongWithFilesMessage "No directory with the test results" filePath
  show (NoExpectedTestDirectory filePath) = somethingWrongWithFilesMessage "No test subdirectory with the expected results" filePath
  show (NoOutTestDirectory filePath) = somethingWrongWithFilesMessage "No test subdirectory with the results obtained" filePath


somethingWrongWithFilesMessage :: String -> FilePath -> String
somethingWrongWithFilesMessage msg filePath = Prelude.concat
                                [ msg, ": `", filePath, "`" ]

defaultGEvalSpecification = GEvalSpecification {
  gesOutDirectory = defaultOutDirectory,
  gesExpectedDirectory = Nothing,
  gesTestName = defaultTestName,
  gesOutFile = defaultOutFile,
  gesExpectedFile = defaultExpectedFile,
  gesMetric = defaultMetric }


geval :: GEvalSpecification -> IO (Double)
geval gevalSpec = do
  unlessM (D.doesDirectoryExist outDirectory) $ throwM $ NoOutDirectory outDirectory
  unlessM (D.doesDirectoryExist expectedDirectory) $ throwM $ NoExpectedDirectory expectedDirectory
  unlessM (D.doesDirectoryExist outTestDirectory) $ throwM $ NoOutTestDirectory outTestDirectory
  unlessM (D.doesDirectoryExist expectedTestDirectory) $ throwM $ NoExpectedTestDirectory expectedTestDirectory
  gevalCore metric expectedFilePath outFilePath
   where expectedFilePath = expectedTestDirectory </> (gesExpectedFile gevalSpec)
         outFilePath = outTestDirectory </> (gesOutFile gevalSpec)
         expectedTestDirectory = expectedDirectory </> testName
         outTestDirectory = outDirectory </> testName
         expectedDirectory = fromMaybe outDirectory $ gesExpectedDirectory gevalSpec
         outDirectory = gesOutDirectory gevalSpec
         testName = gesTestName gevalSpec
         metric = gesMetric gevalSpec

gevalCore :: Metric -> String -> String -> IO (Double)
gevalCore MSE expectedFilePath outFilePath = do
  unlessM (D.doesFileExist expectedFilePath) $ throwM $ NoExpectedFile expectedFilePath
  unlessM (D.doesFileExist outFilePath) $ throwM $ NoOutFile outFilePath
  mse <- runResourceT $
    (getZipSource $ (,)
       <$> ZipSource (items expectedFilePath)
       <*> ZipSource (items outFilePath))
     $$ (CL.map itemError
         =$ averageC)
  return $ mse ** 0.5

averageC :: MonadResource m => Sink Double m Double
averageC = getZipSink
    $ (\total count -> total / fromIntegral count)
  <$> ZipSink CC.sum
  <*> ZipSink CC.length

items :: MonadResource m => String -> Source m Double
items filePath =
  CB.sourceFile filePath
  $= (CT.decode CT.utf8
      =$= CT.lines
      =$= CL.map TR.double
      =$= CC.map getValue)


itemError :: (Double, Double) -> Double
itemError (exp, out) = (exp-out)**2

getValue :: Either String (Double, Text) -> Double
getValue (Right (x, _)) = x
