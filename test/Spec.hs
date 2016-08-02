import Test.Hspec

import GEval.Core
import GEval.OptionsParser
import GEval.BLEU
import GEval.PrecisionRecall
import Options.Applicative
import qualified Test.HUnit as HU

main :: IO ()
main = hspec $ do
  describe "root mean square error" $ do
    it "simple test" $ do
      geval (defaultGEvalSpecification {gesExpectedDirectory=Just "test/rmse-simple/rmse-simple", gesOutDirectory="test/rmse-simple/rmse-simple-solution"}) `shouldReturnAlmost` 0.64549722436790
  describe "mean square error" $ do
    it "simple test with arguments" $
      runGEvalTest "mse-simple" `shouldReturnAlmost` 0.4166666666666667
  describe "BLEU" $ do
    it "trivial example from Wikipedia" $
      runGEvalTest "bleu-trivial" `shouldReturnAlmost` 0.0
    it "complex example" $
      runGEvalTest "bleu-complex" `shouldReturnAlmost` 0.6211
    it "perfect translation" $
      runGEvalTest "bleu-perfect" `shouldReturnAlmost` 1.0000
  describe "Accuracy" $ do
    it "simple example" $
      runGEvalTest "accuracy-simple" `shouldReturnAlmost` 0.6
  describe "precision count" $ do
    it "simple test" $ do
      precisionCount [["Alice", "has", "a", "cat" ]] ["Ala", "has", "cat"] `shouldBe` 2
    it "none found" $ do
      precisionCount [["Alice", "has", "a", "cat" ]] ["for", "bar", "baz"] `shouldBe` 0
    it "multiple values" $ do
      precisionCount [["bar", "bar", "bar", "bar", "foo", "xyz", "foo"]] ["foo", "bar", "foo", "baz", "bar", "foo"] `shouldBe` 4
    it "multiple refs" $ do
      precisionCount [["foo", "baz"], ["bar"], ["baz", "xyz"]]  ["foo", "bar", "foo"] `shouldBe` 2
  describe "reading options" $ do
    it "can get the metric" $ do
      extractMetric "bleu-complex" `shouldReturn` (Just BLEU)
  describe "error handling" $ do
    it "too few lines are handled" $ do
      runGEvalTest "error-too-few-lines" `shouldThrow` (== TooFewLines)
    it "too many lines are handled" $ do
      runGEvalTest "error-too-many-lines" `shouldThrow` (== TooManyLines)
    it "empty output is handled" $ do
      runGEvalTest "empty-output" `shouldThrow` (== EmptyOutput)
    it "unexpected data is handled" $
      runGEvalTest "unexpected-data" `shouldThrow` (== UnexpectedData "input does not start with a digit")
    it "unwanted data is handled" $
      runGEvalTest "unwanted-data" `shouldThrow` (== UnexpectedData "number expected")
  describe "precision and recall" $ do
    it "null test" $ do
      precision neverMatch ['a', 'b', 'c'] [0, 1, 2, 3, 4, 5] `shouldBeAlmost` 0.0
      recall neverMatch ['a', 'b', 'c'] [0, 1, 2, 3, 4, 5] `shouldBeAlmost` 0.0
      f1Measure neverMatch ['a', 'b', 'c'] [0, 1, 2, 3, 4, 5] `shouldBeAlmost` 0.0
    it "basic test" $ do
      precision testMatchFun ['a', 'b', 'c'] [0, 1, 2, 3, 4, 5] `shouldBeAlmost` 0.3333333333333333
      recall testMatchFun ['a', 'b', 'c'] [0, 1, 2, 3, 4, 5] `shouldBeAlmost` 0.66666666666666666
      f1Measure testMatchFun ['a', 'b', 'c'] [0, 1, 2, 3, 4, 5] `shouldBeAlmost` 0.444444444444444
    it "perfect result" $ do
      precision alwaysMatch ['a', 'b', 'c'] [0, 1, 2] `shouldBeAlmost` 1.0
      recall alwaysMatch ['a', 'b', 'c'] [0, 1, 2] `shouldBeAlmost` 1.0
      f1Measure alwaysMatch ['a', 'b', 'c'] [0, 1, 2] `shouldBeAlmost` 1.0
    it "full match" $ do
      precision alwaysMatch ['a', 'b', 'c'] [0, 1, 2, 3, 4, 5] `shouldBeAlmost` 0.5
      recall alwaysMatch ['a', 'b', 'c'] [0, 1, 2, 3, 4, 5] `shouldBeAlmost` 1.0
      f1Measure alwaysMatch ['a', 'b', 'c'] [0, 1, 2, 3 , 4, 5] `shouldBeAlmost` 0.66666666666666


neverMatch :: Char -> Int -> Bool
neverMatch _ _ = False

alwaysMatch :: Char -> Int -> Bool
alwaysMatch _ _ = True

testMatchFun :: Char -> Int -> Bool
testMatchFun 'a' 1 = True
testMatchFun 'a' 2 = True
testMatchFun 'a' 3 = True
testMatchFun 'b' 1 = True
testMatchFun 'c' 1 = True
testMatchFun _ _ = False

extractVal :: (Either (ParserResult GEvalOptions) (Maybe MetricValue)) -> IO MetricValue
extractVal (Right (Just val)) = return val

runGEvalTest testName = (runGEval [
  "--expected-directory",
  "test/" ++ testName ++ "/" ++ testName,
  "--out-directory",
  "test/" ++ testName ++ "/" ++ testName ++ "-solution"]) >>= extractVal

extractMetric :: String -> IO (Maybe Metric)
extractMetric testName = do
  result <- getOptions ["--expected-directory", "test/" ++ testName ++ "/" ++ testName]
  return $ case result of
   Left _ -> Nothing
   Right opts -> Just $ gesMetric $ geoSpec opts

class AEq a where
    (=~) :: a -> a -> Bool

instance AEq Double where
    x =~ y = abs ( x - y ) < (1.0e-4 :: Double)

(@=~?) :: (Show a, AEq a) => a -> a -> HU.Assertion
(@=~?) actual expected = expected =~ actual HU.@? assertionMsg
    where
      assertionMsg = "Expected : " ++ show expected ++
                     "\nActual   : " ++ show actual

shouldBeAlmost got expected = got @=~? expected

shouldReturnAlmost :: (AEq a, Show a, Eq a) => IO a -> a -> Expectation
shouldReturnAlmost action expected = action >>= (@=~? expected)
