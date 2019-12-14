module GEval.EvaluationScheme
  (EvaluationScheme(..),
   evaluationSchemeMetric,
   applyPreprocessingOperations,
   evaluationSchemeName,
   evaluationSchemePriority,
   PreprocessingOperation(..))
  where

import GEval.Metric

import Text.Regex.PCRE.Heavy
import Text.Regex.PCRE.Light.Base (Regex(..))
import Data.Text (Text(..), concat, toLower, toUpper, pack, unpack, words, unwords)
import Data.List (intercalate, break, sort)
import Data.Either
import Data.Maybe (fromMaybe, catMaybes)
import qualified Data.ByteString.UTF8 as BSU


data EvaluationScheme = EvaluationScheme Metric [PreprocessingOperation]
  deriving (Eq)

data PreprocessingOperation = RegexpMatch Regex
                              | LowerCasing
                              | UpperCasing
                              | Sorting
                              | SetName Text
                              | SetPriority Int
  deriving (Eq)

leftParameterBracket :: Char
leftParameterBracket = '<'

rightParameterBracket :: Char
rightParameterBracket = '>'

instance Read EvaluationScheme where
  readsPrec _ s = [(EvaluationScheme metric ops, theRest)]
    where (metricS, opS) = break (== ':') s
          metric = read metricS
          (ops, theRest) = case opS of
            "" -> ([], "")
            (_:opS') -> readOps opS'

readOps :: String -> ([PreprocessingOperation], String)
readOps ('l':theRest) = (LowerCasing:ops, theRest')
    where (ops, theRest') = readOps theRest
readOps ('u':theRest) = (UpperCasing:ops, theRest')
    where (ops, theRest') = readOps theRest
readOps ('m':theRest) = handleParametrizedOp (RegexpMatch . (fromRight undefined) . ((flip compileM) []) . BSU.fromString) theRest
readOps ('S':theRest) = (Sorting:ops, theRest')
    where (ops, theRest') = readOps theRest
readOps ('N':theRest) = handleParametrizedOp (SetName . pack) theRest
readOps ('P':theRest) = handleParametrizedOp (SetPriority . read) theRest
readOps s = ([], s)

handleParametrizedOp :: (String -> PreprocessingOperation) -> String -> ([PreprocessingOperation], String)
handleParametrizedOp constructor (leftParameterBracket:theRest) =
  case break (== rightParameterBracket) theRest of
    (s, []) -> ([], s)
    (param, (_:theRest')) -> let (ops, theRest'') = readOps theRest'
                            in ((constructor param):ops, theRest'')
handleParametrizedOp _ s = ([], s)

instance Show EvaluationScheme where
  show (EvaluationScheme metric operations) = (show metric) ++ (if null operations
                                                                then ""
                                                                else ":" ++ (Prelude.concat (map show operations)))

evaluationSchemeName :: EvaluationScheme -> String
evaluationSchemeName scheme@(EvaluationScheme metric operations) = fromMaybe (show scheme) (findNameSet operations)

evaluationSchemePriority scheme@(EvaluationScheme _ operations) = fromMaybe defaultPriority (findPrioritySet operations)
  where defaultPriority = 1

findNameSet :: [PreprocessingOperation] -> Maybe String
findNameSet ops = case names of
  [] -> Nothing
  _ -> Just $ intercalate " " names
  where names = catMaybes $ map extractName ops
        extractName (SetName n) = Just (unpack n)
        extractName _ = Nothing

findPrioritySet :: [PreprocessingOperation] -> Maybe Int
findPrioritySet [] = Nothing
findPrioritySet ((SetPriority p):_) = Just p
findPrioritySet (_:ops) = findPrioritySet ops

evaluationSchemeMetric :: EvaluationScheme -> Metric
evaluationSchemeMetric (EvaluationScheme metric _) = metric

instance Show PreprocessingOperation where
  show (RegexpMatch (Regex _ regexp)) = parametrizedOperation "m" (BSU.toString regexp)
  show LowerCasing = "l"
  show UpperCasing = "u"
  show Sorting = "S"
  show (SetName t) = parametrizedOperation "N" (unpack t)
  show (SetPriority p) = parametrizedOperation "P" (show p)

parametrizedOperation :: String -> String -> String
parametrizedOperation opCode opArg = opCode ++ [leftParameterBracket] ++ opArg ++ [rightParameterBracket]

applyPreprocessingOperations :: EvaluationScheme -> Text -> Text
applyPreprocessingOperations (EvaluationScheme _ operations) t = foldl (flip applyPreprocessingOperation) t operations

applyPreprocessingOperation :: PreprocessingOperation -> Text -> Text
applyPreprocessingOperation (RegexpMatch regex) = Data.Text.concat . (map fst) . (scan regex)
applyPreprocessingOperation LowerCasing = toLower
applyPreprocessingOperation UpperCasing = toUpper
applyPreprocessingOperation Sorting = Data.Text.unwords . sort . Data.Text.words
applyPreprocessingOperation (SetName _) = id
applyPreprocessingOperation (SetPriority _) = id
