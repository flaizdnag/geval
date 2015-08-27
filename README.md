# GEval

GEval is a library (and a stand-alone tool) for evaluating the results
of solutions to machine learning challenges as defined on the Gonito
platform.

Note that GEval is only about machine learning evaluation. No actual
machine learning algorithms are available here.

## Installing

You need [Haskell Stack](https://github.com/commercialhaskell/stack),
then install GEval with:

    git clone https://github.com/filipg/geval
    cd geval
    stack setup
    stack install

By default, `geval` library is installed in `$HOME/.local/bin`, so in
order to run `geval` you need to either add `$HOME/.local/bin` to
`$PATH` or to type:

    PATH="$HOME/.local/bin" geval ...

## Preparing a Gonito challenge

### Directory structure of a Gonito challenge

A definition of a Gonito challenge should be put in a separate
directory. Such a directory should
have the following structure:

* `README.md` — description of a challenge in Markdown, the first header
  will be used as the challenge title, the first paragraph — as its short
  description
* `config.txt` — simple configuration file with options the same as
  the ones accepted by `geval` binary (see below), usually just a
  metric is specified here (e.g. `--metric BLEU`), also non-default
  file names could be given here (e.g. `--test-name test-B` for a
  non-standard test subdirectory)
* `train/` — subdirectory with training data (if training data are
  supplied for a given Gonito challenge at all)
* `train/train.tsv` — the usual name of the training data file (this
  name is not required and could be more than one file), the first
  column is the target (predicted) value, the other columns represent
  features, no header is assumed
* `dev-0/` — subdirectory with a development set (a sample test set,
  which won't be used for the final evaluation)
* `dev-0/in.tsv` — input data (the same format as `train/train.tsv`,
  but without the first column)
* `dev-0/expected.tsv` — values to be guessed (note that `paste
  dev-0/expected.tsv dev-0/in.tsv` should give the same format as
  `train/train.tsv`)
* `dev-1/`, `dev-2`, ... — other dev sets (if supplied)
* `test-A/` — subdirectory with the test set
* `test-A/in.tsv` — test input (the same format as `dev-0/in.tsv`)
* `test-A/expected.tsv` — values to be guessed (the same format as
  `dev-0/expected.tsv`), note that this file should be “hidden” by the
  organisers of a Gonito challenge, see notes on the structure of
  commits below
* `test-B`, `test-C`, ... — other alternative test sets (if supplied)

### Initiating a Gonito challenge with geval

You can use `geval` to initiate a Gonito challenge:

    geval --init --expected-directory my-challenge

(This will generate a sample toy challenge about guessing planet masses).

A metric (other than the default `RMSE` — root-mean-square error) can
be given to generate another type of toy challenge:

    geval --init --expected-directory my-machine-translation-challenge --metric BLEU

### Preparing a Git repository

Gonito platform expects a Git repository with a challenge to be
submitted. The suggested way to do this is as follows:

1. Prepare a branch with all the files _without_
   `test-A/expected.tsv`. This branch will be cloned by people taking
   up the challenge.
2. Prepare a separate branch (or even a repo) with
   `test-A/expected.tsv` added. This branch should be accessible by
   Gonito platform, but should be kept “hidden” for regular users (or
   at least they should be kindly asked not to peek there). It is
   recommended (though not obligatory) that this branch contain all
   the source codes and data used to generate the train/dev/test sets.
   (Use [git-annex](https://git-annex.branchable.com/) if you have really big files there.)

Branch (1) should be the parent of the branch (2), for instance, the
repo (for the toy “planets” challenge) could be created as follows:

    geval --init --expected-directory planets
    cd planets
    git init
    git add .gitignore config.txt README.md train/train.tsv dev-0/{in,expected}.tsv test-A/in.tsv
    git commit -m 'init challenge'
    git remote add origin git@github.com:filipg/planets
    git push origin master
    git branch dont-peek-here
    git checkout dont-peek-here
    git add test-A/expected.tsv
    git commit -m 'with expected results'
    git push origin dont-peek-here

## Taking up a Gonito challenge

Clone the repo with a challenge, as given on the Gonito web-site, e.g.
for the toy “planets” challenge (as generated with `geval --init`):

    git clone https://github.com/filipg/planets

Now use the train data and whatever machine learning tools you like to
guess the values for the dev set and the test set, put them,
respectively, as:

* `dev-0/out.tsv`
* `test-A/out.tsv`

(These files must have exactly the same number of lines as,
respectively, `dev-0/in.tsv` and `test-0/in.tsv`. They should contain
only the predicted values.)

Check the result for the dev set with `geval`:

    geval --test-name dev-0

(the current directory is assumed for `--out-directory` and `--expected-directory`).

If you'd like and if you have access to the test set results, you can
“cheat” and check the results for the test set:

    cd ..
    git clone https://github.com/filipg/planets planets-secret --branch dont-peek-here
    cd planets
    geval --expected-directory ../planets-secret

### Uploading your results to Gonito platform

Uploading is via Git — commit your “out” files and push the commit to
your own repo. On Gonito you are encouraged to share your code, so
be nice and commit also your source codes.

    git remote add mine git@github.com:johnsmith/planets-johnsmith
    git add {dev-0,test-A}/out.tsv
    git add Makefile magic-bullet.py ... # whatever scripts/source codes you have
    git commit -m 'my solution to the challenge'
    git push mine master

Then let Gonito pull them and evaluate your results.

## `geval` options

    geval [--init] [--out-directory OUT-DIRECTORY]
          [--expected-directory EXPECTED-DIRECTORY] [--test-name NAME]
          [--out-file OUT] [--expected-file EXPECTED] [--metric METRIC]

    -h,--help                Show this help text
    --init                   Init a sample Gonito challenge rather than run an
                             evaluation
    --out-directory OUT-DIRECTORY
                             Directory with test results to be
                             evaluated (default: ".")
    --expected-directory EXPECTED-DIRECTORY
                             Directory with expected test results (the same as
                             OUT-DIRECTORY, if not given)
    --test-name NAME         Test name (i.e. subdirectory with results or expected
                             results) (default: "test-A")
    --out-file OUT           The name of the file to be
                             evaluated (default: "out.tsv")
    --expected-file EXPECTED The name of the file with expected
                             results (default: "expected.tsv")
    --metric METRIC          Metric to be used - RMSE, MSE or BLEU (default: RMSE)

If you need another metric, let me know, or do it yourself!
