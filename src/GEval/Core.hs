module GEval.Core
    ( geval,
      gevalCore,
      Metric(..),
      MetricValue,
      GEvalSpecification(..),
      GEvalOptions(..),
      GEvalException(..),
      defaultGEvalSpecification,
      defaultOutDirectory,
      defaultTestName,
      defaultOutFile,
      defaultExpectedFile,
      defaultMetric,
      getExpectedDirectory,
      configFileName
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

import qualified Data.List.Split as DLS

import GEval.BLEU

type MetricValue = Double

data Metric = RMSE | MSE | BLEU
              deriving (Show, Read)

defaultOutDirectory = "."
defaultTestName = "test-A"
defaultOutFile = "out.tsv"
defaultExpectedFile = "expected.tsv"

defaultMetric :: Metric
defaultMetric = RMSE

configFileName :: FilePath
configFileName = "config.txt"

data GEvalSpecification = GEvalSpecification
                          { gesOutDirectory :: FilePath,
                            gesExpectedDirectory :: Maybe FilePath,
                            gesTestName :: String,
                            gesOutFile :: String,
                            gesExpectedFile :: String,
                            gesMetric :: Metric }

getExpectedDirectory :: GEvalSpecification -> FilePath
getExpectedDirectory spec = fromMaybe outDirectory $ gesExpectedDirectory spec
                            where outDirectory = gesOutDirectory spec

data GEvalOptions = GEvalOptions
                    { geoInit :: Bool,
                      geoSpec :: GEvalSpecification }


data GEvalException = NoExpectedFile FilePath
                      | NoOutFile FilePath
                      | NoExpectedDirectory FilePath
                      | NoOutDirectory FilePath
                      | NoExpectedTestDirectory FilePath
                      | NoOutTestDirectory FilePath
                      | FileAlreadyThere FilePath

instance Exception GEvalException

instance Show GEvalException where
  show (NoExpectedFile filePath) = somethingWrongWithFilesMessage "No file with the expected results" filePath
  show (NoOutFile filePath) = somethingWrongWithFilesMessage "No file with the test results" filePath
  show (NoExpectedDirectory filePath) = somethingWrongWithFilesMessage "No directory with the expected results" filePath
  show (NoOutDirectory filePath) = somethingWrongWithFilesMessage "No directory with the test results" filePath
  show (NoExpectedTestDirectory filePath) = somethingWrongWithFilesMessage "No test subdirectory with the expected results" filePath
  show (NoOutTestDirectory filePath) = somethingWrongWithFilesMessage "No test subdirectory with the results obtained" filePath
  show (FileAlreadyThere filePath) = somethingWrongWithFilesMessage "File already there" filePath

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


geval :: GEvalSpecification -> IO (MetricValue)
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
         expectedDirectory = getExpectedDirectory gevalSpec
         outDirectory = gesOutDirectory gevalSpec
         testName = gesTestName gevalSpec
         metric = gesMetric gevalSpec

gevalCore :: Metric -> String -> String -> IO (MetricValue)
gevalCore RMSE expectedFilePath outFilePath = do
  mse <- gevalCore MSE expectedFilePath outFilePath
  return $ mse ** 0.5

gevalCore metric expectedFilePath outFilePath = do
  unlessM (D.doesFileExist expectedFilePath) $ throwM $ NoExpectedFile expectedFilePath
  unlessM (D.doesFileExist outFilePath) $ throwM $ NoOutFile outFilePath
  gevalCore' metric expectedFilePath outFilePath

gevalCore' :: Metric -> String -> String -> IO (MetricValue)
gevalCore' MSE = gevalCore'' outParser outParser itemError averageC id
  where outParser = getValue . TR.double

gevalCore' BLEU = gevalCore'' (Prelude.map Prelude.words . DLS.splitOn "\t" . unpack) (Prelude.words . unpack) bleuCombine bleuAgg bleuFinal
  where bleuFinal (p1, p2, p3, p4, rl, l1, l2, l3, l4) = ((p1 /. l1) * (p2 /. l2) * (p3 /. l3) * (p4 /. l4)) ** 0.25 * (brevityPenalty l1 rl)
        bleuCombine (refs, sen) = bleuStep refs sen
        bleuAgg = CC.foldl bleuFuse (0, 0, 0, 0, 0,  0, 0, 0, 0)
        bleuFuse (a1, a2, a3, a4, a5, a6, a7, a8, a9) (b1, b2, b3, b4, b5, b6, b7, b8, b9) = (a1+b1, a2+b2, a3+b3, a4+b4, a5+b5, a6+b6, a7+b7, a8+b8, a9+b9)
        brevityPenalty c r
          | c >= r = 1.0
          | otherwise = exp (1.0 - (r /. c))

(/.) :: Int -> Int -> Double
x /. 0 = 1.0
x /. y = (fromIntegral x) / (fromIntegral y)

gevalCore'' :: (Text -> a) -> (Text -> b) -> ((a, b) -> c) -> (Sink c (ResourceT IO) d) -> (d -> Double ) -> String -> String -> IO (MetricValue)
gevalCore'' expParser outParser itemStep aggregator finalStep expectedFilePath outFilePath = do
  v <- runResourceT $
    (getZipSource $ (,)
       <$> ZipSource (items expectedFilePath expParser)
       <*> ZipSource (items outFilePath outParser))
     $$ (CL.map itemStep
         =$ aggregator)
  return $ finalStep v

averageC :: MonadResource m => Sink Double m Double
averageC = getZipSink
    $ (\total count -> total / fromIntegral count)
  <$> ZipSink CC.sum
  <*> ZipSink CC.length

items :: MonadResource m => String -> (Text -> a) -> Source m a
items filePath parser =
  CB.sourceFile filePath
  $= (CT.decode CT.utf8
      =$= CT.lines
      =$= CL.map parser)

itemError :: (Double, Double) -> Double
itemError (exp, out) = (exp-out)**2

getValue :: Either String (Double, Text) -> Double
getValue (Right (x, _)) = x
