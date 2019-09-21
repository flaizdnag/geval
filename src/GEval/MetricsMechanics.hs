{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE UndecidableInstances #-}

module GEval.MetricsMechanics
  where

import Data.Singletons.TH

import GEval.Metric

import Data.Text
import Data.Text.Read as TR
import qualified Data.List.Split as DLS
import Data.Attoparsec.Text (parseOnly)
import Data.Maybe (catMaybes)

import Control.Monad ((<=<))

import GEval.Annotation (Annotation, ObtainedAnnotation, parseAnnotations, parseObtainedAnnotations)
import GEval.Clippings (Clipping, ClippingSpec, LabeledClipping, lineClippingsParser, lineClippingSpecsParser, lineLabeledClippingsParser)
import GEval.BIO (TaggedEntity, parseBioSequenceIntoEntities, parseBioSequenceIntoEntitiesWithoutNormalization)
import GEval.LogLossHashed (parseWordSpecs, wordSpecToPair)
import GEval.ProbList (ProbList(..), parseIntoProbList, WordWithProb(..))

-- | Helper type so that singleton can be used.
-- | (The problem is that some metrics are parametrized by Double
-- | Word32 and this is not handled by the singleton libary.)
singletons [d|data AMetric = ARMSE | AMSE | APearson | ASpearman | ABLEU | AGLEU | AWER | AAccuracy | AClippEU
                             | AFMeasure | AMacroFMeasure | ANMI
                             | ALogLossHashed | ACharMatch | AMAP | ALogLoss | ALikelihood
                             | ABIOF1 | ABIOF1Labels | ATokenAccuracy | ALikelihoodHashed | AMAE | ASMAPE | AMultiLabelFMeasure
                             | AMultiLabelLogLoss | AMultiLabelLikelihood
                             | ASoftFMeasure | AProbabilisticMultiLabelFMeasure | AProbabilisticSoftFMeasure | ASoft2DFMeasure
                             deriving (Eq)
             |]

-- | Convert a metric to a helper type without parameters
toHelper :: Metric -> AMetric
toHelper RMSE = ARMSE
toHelper MSE = AMSE
toHelper Pearson = APearson
toHelper Spearman = ASpearman
toHelper BLEU = ABLEU
toHelper GLEU = AGLEU
toHelper WER = AWER
toHelper Accuracy = AAccuracy
toHelper ClippEU = AClippEU
toHelper (FMeasure _) = AFMeasure
toHelper (MacroFMeasure _) = AMacroFMeasure
toHelper NMI = ANMI
toHelper (LogLossHashed _) = ALogLossHashed
toHelper CharMatch = ACharMatch
toHelper MAP = AMAP
toHelper LogLoss = ALogLoss
toHelper Likelihood = ALikelihood
toHelper BIOF1 = ABIOF1
toHelper BIOF1Labels = ABIOF1Labels
toHelper TokenAccuracy = ATokenAccuracy
toHelper (LikelihoodHashed _) = ALikelihoodHashed
toHelper MAE = AMAE
toHelper SMAPE = ASMAPE
toHelper (MultiLabelFMeasure _) = AMultiLabelFMeasure
toHelper MultiLabelLogLoss = AMultiLabelLogLoss
toHelper MultiLabelLikelihood = AMultiLabelLikelihood
toHelper (SoftFMeasure _) = ASoftFMeasure
toHelper (ProbabilisticMultiLabelFMeasure _) = AProbabilisticMultiLabelFMeasure
toHelper (ProbabilisticSoftFMeasure _) = AProbabilisticSoftFMeasure
toHelper (Soft2DFMeasure _) = ASoft2DFMeasure

type family ParsedInputType (t :: AMetric) :: * where
  ParsedInputType ACharMatch = Text
  ParsedInputType _ = ()

type family ParsedExpectedType (t :: AMetric) :: * where
  ParsedExpectedType ARMSE     = Double
  ParsedExpectedType AMSE      = Double
  ParsedExpectedType APearson  = Double
  ParsedExpectedType ASpearman = Double
  ParsedExpectedType ABLEU     = [[String]]
  ParsedExpectedType AGLEU     = [[String]]
  ParsedExpectedType AWER      = [String]
  ParsedExpectedType AAccuracy = Text
  ParsedExpectedType AClippEU  = [ClippingSpec]
  ParsedExpectedType AFMeasure = Bool
  ParsedExpectedType AMacroFMeasure = Maybe Text
  ParsedExpectedType ASoftFMeasure = [Annotation]
  ParsedExpectedType AProbabilisticMultiLabelFMeasure = [Text]
  ParsedExpectedType AProbabilisticSoftFMeasure = [Annotation]
  ParsedExpectedType ASoft2DFMeasure = [LabeledClipping]
  ParsedExpectedType ANMI = Text
  ParsedExpectedType ALogLossHashed = Text
  ParsedExpectedType ALikelihoodHashed = Text
  ParsedExpectedType ACharMatch = Text
  ParsedExpectedType AMAP = [String]
  ParsedExpectedType ALogLoss = Double
  ParsedExpectedType ALikelihood = Double
  ParsedExpectedType ABIOF1 = [TaggedEntity]
  ParsedExpectedType ABIOF1Labels = [TaggedEntity]
  ParsedExpectedType ATokenAccuracy = [Text]
  ParsedExpectedType AMAE = Double
  ParsedExpectedType ASMAPE = Double
  ParsedExpectedType AMultiLabelFMeasure = [Text]
  ParsedExpectedType AMultiLabelLogLoss = [Text]
  ParsedExpectedType AMultiLabelLikelihood = [Text]

expectedParser :: SAMetric t -> Text -> Either String (ParsedExpectedType t)
expectedParser SARMSE = doubleParser
expectedParser SAMSE = doubleParser
expectedParser SAPearson = doubleParser
expectedParser SASpearman = doubleParser
expectedParser SABLEU = alternativeSentencesParser
expectedParser SAGLEU = alternativeSentencesParser
expectedParser SAWER = intoStringWords
expectedParser SAAccuracy = onlyStrip
expectedParser SAClippEU = controlledParse lineClippingSpecsParser
expectedParser SAFMeasure = zeroOneParser
expectedParser SAMacroFMeasure = justStrip
expectedParser SASoftFMeasure = parseAnnotations
expectedParser SAProbabilisticMultiLabelFMeasure = intoWords
expectedParser SAProbabilisticSoftFMeasure = parseAnnotations
expectedParser SASoft2DFMeasure = controlledParse lineLabeledClippingsParser
expectedParser SANMI = Right . id
expectedParser SALogLossHashed = onlyStrip
expectedParser SALikelihoodHashed = onlyStrip
expectedParser SACharMatch = Right
expectedParser SAMAP = splitByTabs
expectedParser SALogLoss = doubleParser
expectedParser SALikelihood = doubleParser
expectedParser SABIOF1 = parseBioSequenceIntoEntities
expectedParser SABIOF1Labels = parseBioSequenceIntoEntitiesWithoutNormalization
expectedParser SATokenAccuracy = intoWords
expectedParser SAMAE = doubleParser
expectedParser SASMAPE = doubleParser
expectedParser SAMultiLabelFMeasure = intoWords
expectedParser SAMultiLabelLogLoss = intoWords
expectedParser SAMultiLabelLikelihood = intoWords

type family ParsedOutputType (t :: AMetric) :: * where
  ParsedOutputType ABLEU = [Text]
  ParsedOutputType AGLEU = [Text]
  ParsedOutputType AClippEU = [Clipping]
  ParsedOutputType AMacroFMeasure = Maybe Text
  ParsedOutputType ASoftFMeasure = [ObtainedAnnotation]
  ParsedOutputType AProbabilisticSoftFMeasure = [ObtainedAnnotation]
  ParsedOutputType AProbabilisticMultiLabelFMeasure = [WordWithProb]
  ParsedOutputType t = ParsedExpectedType t

outputParser :: SAMetric t -> Text -> Either String (ParsedOutputType t)
outputParser SARMSE = expectedParser SARMSE
outputParser SAMSE = expectedParser SARMSE
outputParser SAPearson = expectedParser SAPearson
outputParser SASpearman = expectedParser SASpearman
outputParser SABLEU = intoWords
outputParser SAGLEU = intoWords
outputParser SAWER = expectedParser SAWER
outputParser SAAccuracy = expectedParser SAAccuracy
outputParser SAClippEU = controlledParse lineClippingsParser
outputParser SAFMeasure = probToZeroOneParser
outputParser SAMacroFMeasure = Right . predictedParser . strip
outputParser SASoftFMeasure = parseObtainedAnnotations
outputParser SAProbabilisticMultiLabelFMeasure = (Right . (\(ProbList es) -> es) . parseIntoProbList)
outputParser SAProbabilisticSoftFMeasure = parseObtainedAnnotations
outputParser SASoft2DFMeasure = expectedParser SASoft2DFMeasure
outputParser SANMI = expectedParser SANMI
outputParser SALogLossHashed = onlyStrip
outputParser SALikelihoodHashed = onlyStrip
outputParser SACharMatch = Right
outputParser SAMAP = splitByTabs
outputParser SALogLoss = doubleParser
outputParser SALikelihood = doubleParser
outputParser SABIOF1 = parseBioSequenceIntoEntities
outputParser SABIOF1Labels = parseBioSequenceIntoEntitiesWithoutNormalization
outputParser SATokenAccuracy = intoWords
outputParser SAMAE = doubleParser
outputParser SASMAPE = doubleParser
outputParser SAMultiLabelFMeasure = intoWords
outputParser SAMultiLabelLogLoss = intoWords
outputParser SAMultiLabelLikelihood = intoWords


doubleParser = getValue . TR.double

intoWords = Right . Data.Text.words

intoStringWords = Right . Prelude.words . unpack

alternativeSentencesParser = Right . Prelude.map Prelude.words . DLS.splitOn "\t" . unpack

onlyStrip = Right . strip

justStrip = Right . Just . strip

predictedParser got =
  -- first try to parse what we got as a probability distribution
  -- (like the one used for Likelikehood/LogLossHashed metric)
  case parseWordSpecs got of
    Right wordSpecs -> if Prelude.null pairs
                      then Nothing
                      else Just $ snd $ Prelude.maximum pairs
      where pairs = catMaybes $ Prelude.map wordSpecToPair wordSpecs
    Left _ -> Just got

splitByTabs = Right . DLS.splitOn "\t" . unpack

zeroOneParser = expected <=< (getValue . TR.decimal)
  where expected 1 = Right True
        expected 0 = Right False
        expected _ = Left "expected 0 or 1"

probToZeroOneParser = detected <=< (getValue . TR.double)
  where -- output value could be a probability (for compatibility with other measures)
        detected prob
          | prob >= 0.0 && prob < detectionThreshold = Right False
          | prob >= detectionThreshold && prob <= 1.0 = Right True
          | otherwise = Left "expected probability"
        detectionThreshold = 0.5

getValue :: Num a => Either String (a, Text) -> Either String a
getValue (Right (x, reminder)) =
  if Data.Text.null reminder || Data.Text.head reminder == '\t'
  then Right x
  else Left "number expected"
getValue (Left s) = Left s

controlledParse parser t =
  case parseOnly parser t of
    (Right v) -> Right v
    (Left _) -> Left "cannot parse line"
