# GEval

GEval is a Haskell library and a stand-alone tool for evaluating the
results of solutions to machine learning challenges as defined in the
[Gonito](https://gonito.net) platform. Also, could be used outside the
context of Gonito.net challenges, assuming the test data is given in
simple TSV (tab-separated values) files.

Note that GEval is only about machine learning evaluation. No actual
machine learning algorithms are available here.

The official repository is `git://gonito.net/geval`, browsable at
<https://gonito.net/gitlist/geval.git/>.

## Installing

### The easy way: just download the fully static GEval binary

(Assuming you have a 64-bit Linux.)

    wget https://gonito.net/get/bin/geval
    chmod u+x geval
    ./geval --help

#### On Windows

For Windows, you should use Windows PowerShell.

	wget https://gonito.net/get/bin/geval

Next, you should go to the folder where you download `geval` and right-click to `geval` file.
Go to `Properties` and in the section `Security` grant full access to the folder.

Or you should use `icacls "folder path to geval" /grant USER:<username>`

This is a fully static binary, it should work on any 64-bit Linux or 64-bit Windows.

### Build from scratch

You need [Haskell Stack](https://github.com/commercialhaskell/stack).
You could install Stack with your package manager or with:

    curl -sSL https://get.haskellstack.org/ | sh

When you've got Haskell Stack, install GEval with:

    git clone git://gonito.net/geval
    cd geval
    stack setup
    stack test
    stack install

(Note that when you're running Haskell Stack for the first time it
will take some time and a couple of gigabytes on your disk.)

By default, `geval` binary is installed in `$HOME/.local/bin`, so in
order to run `geval` you need to either add `$HOME/.local/bin` to
`$PATH` in your configuration or to type:

    PATH="$HOME/.local/bin" geval ...

In Windows you should add new global variable with name 'geval' and path should be the same as above.

### Troubleshooting

If you see a message like this:

    Configuring lzma-0.0.0.3...
    clang: warning: argument unused during compilation: '-nopie' [-Wunused-command-line-argument]
    Cabal-simple_mPHDZzAJ_2.0.1.0_ghc-8.2.2: Missing dependency on a foreign
    library:
    * Missing (or bad) header file: lzma.h
    This problem can usually be solved by installing the system package that
    provides this library (you may need the "-dev" version). If the library is
    already installed but in a non-standard location then you can use the flags
    --extra-include-dirs= and --extra-lib-dirs= to specify where it is.
    If the header file does exist, it may contain errors that are caught by the C
    compiler at the preprocessing stage. In this case, you can re-run configure
    with the verbosity flag -v3 to see the error messages.

it means that you need to install lzma library on your operating
system. The same might go for pkg-config. On macOS (it's more likely
to happen on macOS, as these packages are usually installed out of the box on Linux), you need to run:

    brew install xz
    brew install pkg-config

In case the lzma package is not installed on your Linux, you need to run (assuming Debian/Ubuntu):

    sudo apt-get install pkg-config liblzma-dev libpq-dev libpcre3-dev

#### Windows issues

If you see this message on Windows during executing `stack test` command:

	In the dependencies for geval-1.21.1.0:
	    unix needed, but the stack configuration has no specified version
	In the dependencies for lzma-0.0.0.3:
	    lzma-clib needed, but the stack configuration has no specified version

You should replace `unix` with `unix-compat` in `geval.cabal` file,
because `unix` package is not supported for Windows.

And you should add `lzma-clib-5.2.2` and `unix-compat-0.5.2` to section extra-deps in `stack.yaml` file.

If you see message about missing pkg-config on Windpws you should download two packages from the site:
http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/
These packages are:
		- pkg-config (the newest version)
		- gettext-runtime (the newest version)
Extract `pkg-config.exe` file in Windows PATH
Extract init.dll file from gettext-runtime

You should also download from http://ftp.gnome.org/pub/gnome/binaries/win32/glib/2.28 glib package
and extract libglib-2.0-0.dll file.

All files you should put for example in `C:\MinGW\bin` directory.

## Quick tour

Let's use GEval to evaluate machine translation (MT) systems (but keep
in mind than GEval could be used for many other machine learning task
types). We start with a simple evaluation, but then we switch to what
might be called black-box debugging of ML models.

First, we will run GEval on WMT-2017, a German-to-English machine
translation challenge repackaged for [Gonito.net](https://gonito.net)
platform and [available there](https://gonito.net/challenge-readme/wmt-2017) (though, in a moment you'll see it can be
run on other test sets, not just the ones conforming to specific
Gonito.net standards). Let's download one of the solutions, it's just
available via git, so you don't have to click anywhere, just type:

    git clone git://gonito.net/wmt-2017 -b submission-01229 --single-branch

Let's step into the repo and run GEval (I assume you added `geval`
path to `$PATH`, so that you could just use `geval` instead of
`/full/path/to/geval`):

    cd wmt-2017
    geval

Well, something apparently went wrong:

    geval: No file with the expected results: `./test-A/expected.tsv`

The problem is that the official test set is hidden from you (although
you can find it if you are determined...) You should try running GEval
on the dev set instead:

    geval -t dev-0

and you'll see the result — 0.27358 in
[BLEU metric](https://en.wikipedia.org/wiki/BLEU), which is the
default metric for the WMT-2017 challenge. GEval could do the
evaluation using other metrics, in case of machine translation,
(Google) GLEU (alternative to BLEU), WER (word-error rate) or simple
accuracy (which could be interpreted as sentence-recognition rate
here) might make sense:

    geval -t dev-0 --metric GLEU --metric WER --metric Accuracy

After a moment, you'll see the results:

    BLEU	0.27358
    GLEU	0.31404
    WER	0.55201
    Accuracy	0.01660

The results do not look good anyway and I'm not talking about
Accuracy, which, even for a good MT (or even a human), will be low (as
it measures how many translations are exactly the same as the golden
standard), but rather about BLEU which is not impressive for this
particular task. Actually, it's no wonder as the system we're
evaluating now is a very simple neural machine translation baseline.
Out of curiosity, let's have a look at the worst items, i.e. sentences
for which the GLEU metric is the lowest (GLEU is better than BLEU for
item-per-item evaluation); it's easy with GEval:

    geval -t dev-0 --alt-metric GLEU --line-by-line --sort | head -n 10

    0.0	Tanzfreudiger Nachwuchs gesucht	Dance-crazy youths wanted	Dance joyous offspring sought
    0.0	Bulgarische Gefängnisaufseher protestieren landesweit	Bulgaria 's Prison Officers Stage National Protest	Bulgarian prison guards protest nationwide
    0.0	Schiffe der Küstenwache versenkt	Coastguard ships sunk	Coast Guard vessels sinking
    0.0	Gebraucht kaufen	Buying used	Needed buy
    0.0	Mieten	Renting	Rentals
    0.0	E-Books	E-books	E-Books
    0.021739130434782608	Auch Reservierungen in Hotels gehen deutlich zurück.	There is even a marked decline in the number of hotel reservations .	Reservations also go back to hotels significantly .
    0.023809523809523808	Steuerbelastung von Geschäftsleuten im Raum Washington steigt mit der wirtschaftlichen Erholung	Washington-area business owners " tax burden mounts as economy rebounds	Tax burden of businessmen in the Washington area rises with economic recovery
    0.03333333333333333	Verwunderte Ärzte machten Röntgenaufnahmen seiner Brust und setzen Pleurakathether an, um Flüssigkeit aus den Lungen zu entnehmen und im Labor zu testen.	Puzzled doctors gave him chest X-rays , and administered pleural catheters to draw off fluid from the lungs and send it for assessment .	At the end of his life , she studied medicine at the time .
    0.03333333333333333	Die Tradition der Schulabschlussbälle in den USA wird nun auf die Universitäten übertragen, wo Freshmen Auftritte mit dem Privatflugzeug angeboten werden.	US prom culture hits university life with freshers offered private jet entrances	The tradition of school leavers in the U.S. is now transferred to universities , where freshmen are offered appearances with the private plane .

Well, this way, we found some funny utterances for which even a single
word was recovered, but could we get more insight?

The good news is that you could use GEval to debug the MT system in a
black-box manner to order to find its weak points -- --worst-features is the
option to do this:

    geval -t dev-0 --alt-metric GLEU --worst-features | head -n 10

This command will find the top 10 "worst" features (in either input,
expected output or actual output), i.e. the features which correlate
with low GLEU values in the most significant way.

    exp:"	346	0.27823151	0.00000909178949766883
    out:&apos;&apos;	348	0.28014113	0.00002265047322460752
    exp:castle	23	0.20197660	0.00006393156973075869
    exp:be	191	0.27880383	0.00016009575605100586
    exp:road	9	0.16307514	0.00025767878872874620
    exp:out	78	0.26033671	0.00031551452260174863
    exp:(	52	0.25348798	0.00068739029500072100
    exp:)	52	0.25386216	0.00071404713888387060
    exp:club	28	0.22958093	0.00078051481428704770
    out:`	9	0.17131601	0.00079873676961809170

How to read the output like this?

1. The feature (i.e. a word or token) found, prepended with a
qualifier: `exp` for the expected output, `out` — the actul output,
`in` — input.
2. Number of occurrences.
3. The mean score for all items (in our examples: sentences) with a given feature.
For instance, the average GLEU score for sentences for which a double quote is expected
is 0.27823151. At first glance, it does not seem much worse than the general score
(0.30514), but actually…
4. … it's highly significant. The probability to get it by chance
(according to the [Mann-Whitney _U_ test](https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test))
is extremely low (_p_ = 0.000009).

But why were double quotes so problematic in German-English
translation?! Well, look at the second-worst feature — `&apos;&apos;`
in the _output_! Oops, it seems like a very stupid mistake with
post-processing was done and no double quote was correctly generated,
which decreased the score a little for each sentence in which the
quote was expected.

When I fixed this simple bug, the BLUE metric increased from 0.27358
to [0.27932](https://gonito.net/q/433e8cfdc4b5e20e276f4ddef5885c5ed5947ae5)!

What about the third item — the word _castle_ in the expected output? Let's
have a look at the examples with this word using `--line-by-line` option combined with grep:

    geval -t dev-0 --alt-metric GLEU --line-by-line --sort | grep 'castle' | head -n 5

    0.0660377358490566	Eine Wasserburg, die bei unserer nächsten Aufgabe gesucht wird, ist allerdings in der Höhe eher selten zu finden.	A moated castle , which we looked for as part of our next challenge , is , of course , rather hard to find way up high .	However , a watershed that is being sought in our next assignment is rather rare .
    0.07142857142857142	Ziehen die Burgvereine bald wieder an einem Strang?	Will the Burgvereine ( castle clubs ) get back together again ?	Do the Burgundy clubs join forces soon ?
    0.11290322580645161	Zuletzt gab es immer wieder Zwist zwischen den beiden Wolfratshauser Burgvereinen.	Recently there have been a lot of disputes between both of the castle groups in Wolfratshausen .	Last but not least , there has been a B.A. between the two Wolfratshauser Burgundy .
    0.11650485436893204	Während die Burgfreunde um den plötzlich verstorbenen Richard Dimbath bis zuletzt einen Wiederaufbau der Burg am Bergwald im Auge hatten, steht für den Burgverein um Sjöberg die "Erschließung und Erlebbarmachung" des Geländes an vorderster Stelle.	Whereas the castle friends , and the recently deceased Richard Dimbath right up until the bitter end , had their eyes on reconstructing the castle in the mountain forest , the castle club , with Sjöberg , want to " develop and bring the premises to life " in its original place .	While the castle fans were aware of the sudden death of Richard Dimbath until the end of a reconstruction of the castle at Bergwald , the Burgverein around Sjöberg is in the vanguard of the `` development and adventure &apos;&apos; of the area .
    0.1206896551724138	Auf der Hüpfburg beim Burggartenfest war am Sonnabend einiges los.	Something is happening on the bouncy castle at the Burggartenfest ( castle garden festival ) .On the edge of the castle there was a lot left at the castle castle .

Well, now it is not as simple as the problem with double quotes. It
seems that "castle" German is full of compounds which are hard for the
MT system analysed, in particular the word _Burgverein_ makes the
system trip up. You might try to generalise this insight and improve
your system or you might not. It might be considered an issue in the
test set rather than in the system being evaluated. (Is it OK that we
have so many sentences with _Burgverein_ in the test set?)

But do you need to represent your test set a Gonito challenge to run GEval? Actually no,
I'll show this by running GEval directly on WMT-2018. First, let's download the files:

    wget http://data.statmt.org/wmt17/translation-task/wmt17-submitted-data-v1.0.tgz
    tar vxf wmt17-submitted-data-v1.0.tgz

and run GEval for one of the submissions (UEdin-NMT):

    geval --metric BLEU --precision 4 --tokenizer 13a \
        -i wmt17-submitted-data/txt/sources/newstest2017-deen-src.de \
        -o wmt17-submitted-data/txt/system-outputs/newstest2017/de-en/newstest2017.uedin-nmt.4723.de-en \
        -e wmt17-submitted-data/txt/references/newstest2017-deen-ref.en

    0.3512

where `-i` stands for the input file, `-o` — output file, `-e` — file with expected (reference) data.

Note the tokenization, in order to properly calculate
BLEU (or GLEU) the way it was done within the official WMT-2017
challenge, you need to tokenize the expected output and the actual
output of your system using the right tokenizer. (The test set packaged
for Gonito.net challenge were already tokenized.)

Let's evaluate another system:

    geval --metric BLEU --precision 4 --tokenizer 13a \
        -i wmt17-submitted-data/txt/sources/newstest2017-deen-src.de \
        -o wmt17-submitted-data/txt/system-outputs/newstest2017/de-en/newstest2017.LIUM-NMT.4733.de-en \
        -e wmt17-submitted-data/txt/references/newstest2017-deen-ref.en

    0.3010

In general, LIUM is much worse than UEdin, but were there any utterance for which UEdin is worse than LIUM?
You could use `--diff` option to find this:

    geval --metric GLEU --precision 4 --tokenizer 13a \
        -i wmt17-submitted-data/txt/sources/newstest2017-deen-src.de \
        -o wmt17-submitted-data/txt/system-outputs/newstest2017/de-en/newstest2017.uedin-nmt.4723.de-en \
        --diff wmt17-submitted-data/txt/system-outputs/newstest2017/de-en/newstest2017.LIUM-NMT.4733.de-en \
        -e wmt17-submitted-data/txt/references/newstest2017-deen-ref.en -s | head -n 10

The above command will print out the 10 sentences for which the difference between UEdin and LIUM is the largest:

    -0.5714285714285714	Hier eine Übersicht:	Here is an overview:	Here is an overview:	Here's an overview:
    -0.5714285714285714	Eine Generation protestiert.	A generation is protesting.	A generation is protesting.	A generation protesting.
    -0.5333333333333333	"Die ersten 100.000 Euro sind frei."	"The first 100,000 euros are free."	"The first 100.000 euros are free."	'the first £100,000 is free. '
    -0.5102564102564102	Bald stehen neue Container in der Wasenstraße	New containers will soon be located in Wasenstraße	New containers will soon be available on Wasenstraße	Soon, new containers are in the water road
    -0.4736842105263158	Als gefährdet gelten auch Arizona und Georgia.	Arizona and Georgia are also at risk.	Arizona and Georgia are also at risk.	Arizona and Georgia are also considered to be at risk.
    -0.4444444444444445	Das ist alles andere als erholsam.	This is anything but relaxing.	That is anything but relaxing.	This is far from relaxing.
    -0.4285714285714286	Ein Haus bietet Zuflucht.	One house offers refuge.	A house offers refuge.	A house offers sanctuary.
    -0.42307692307692313	Weshalb wir Simone, Gabby und Laurie brauchen	Why we need Simone, Gabby and Laurie	Why we need Simone, Gabby and Laurie	Why We Need Simone, Gabby and Laurie
    -0.4004524886877827	Der Mann soll nicht direkt angesprochen werden.	The man should not be approached.	The man should not be addressed directly.	The man is not expected to be addressed directly.
    -0.3787878787878788	Aber es lässt sich ja nicht in Abrede stellen, dass die Attentäter von Ansbach und Würzburg Flüchtlinge waren.	But it cannot be denied that the perpetrators of the attacks in Ansbach and Würzburg were refugees.	But it cannot be denied that the perpetrators of Ansbach and Würzburg were refugees.	But there is no denying that the bombers of Ansbach and Würzburg were refugees.

The columns goes as follows:

1. the difference between the two systems (GLEU "delta")
2. input
3. expected output (reference translation)
4. the output from LIUM
5. the output from UEdint

Hmmm, turning 100.000 euros into £100,000 is no good…

You could even get the list of the "most worsening" features between
LIUM and UEdin, the features which were "hard" for UEdin, even though they were
easy for UEdin:

    geval --metric GLEU --precision 4 --tokenizer 13a \
      -i wmt17-submitted-data/txt/sources/newstest2017-deen-src.de \
      -o wmt17-submitted-data/txt/system-outputs/newstest2017/de-en/newstest2017.uedin-nmt.4723.de-en \
      --most-worsening-features wmt17-submitted-data/txt/system-outputs/newstest2017/de-en/newstest2017.LIUM-NMT.4733.de-en \
      -e wmt17-submitted-data/txt/references/newstest2017-deen-ref.en | head -n 10

    exp:euros	31	-0.06468724	0.00001097343184385749
    in<1>:Euro	31	-0.05335673	0.00002829695624789508
    exp:be	296	0.02055637	0.00037328997500381740
    exp:Federal	12	-0.05291327	0.00040500816936872160
    exp:small	21	-0.02880722	0.00081606196875884380
    exp:turnover	9	-0.09234316	0.00096449582346370200
    out:$	36	-0.01926724	0.00101954071759940870
    out:interior	6	-0.07061411	0.00130090392961781970
    exp:head	17	-0.03205283	0.00159684081554980080
    exp:will	187	0.01737604	0.00168212689205692070

Hey, UEdin, you have a problem with euros… is it due to Brexit?

## Another example

Let us download a Gonito.net challenge:

    git clone git://gonito.net/sentiment-by-emoticons

The task is to predict the sentiment of a Polish short text -- whether
it is positive or negative (or to be precise: to guess whether a
positive or negative emoticon was used). The train set is given
in the `train/train.tsv.xz` file, each item is given in a separate file,
have a look at the first 5 items:

    xzcat train/train.tsv.xz | head -n 5

Now let's try to evaluate some solution to this challenge. Let's fetch it:

    git fetch git://gonito.net/sentiment-by-emoticons submission-01865 --single-branch
    git reset --hard FETCH_HEAD

and now run geval:

    geval -t dev-0

(You need to run `dev-0` test as the expected results for the `test-A`
test is hidden from you.) The evaluation result is 0.47481. This might
be hard to interpret, so you could try other metrics.

    geval -t dev-0 --metric Accuracy --metric Likelihood

So now you can see that the accuracy is over 78% and the likelihood
(i.e. the geometric mean of probabilities of the correct classes) is 0.62.

## Yet another example

    geval --metric MultiLabel-F1 -e https://gonito.net/gitlist/poleval-2018-ner.git/raw/submission-02284/dev-0/expected.tsv -o https://gonito.net/gitlist/poleval-2018-ner.git/raw/submission-02284/dev-0/out.tsv -i https://gonito.net/gitlist/poleval-2018-ner.git/raw/submission-02284/dev-0/in.tsv -w | head -n 100

    exp:persName.addName	40	0.57266043	0.00000000000000045072
    exp:persName	529	0.87944043	0.00000000000026284497
    out:persName	526	0.89273910	0.00000000000189290814
    exp:orgName	259	0.85601779	0.00000000009060752668
    exp:1	234	0.81006729	0.00000004388133229664
    exp:persName.forename	369	0.89791618	0.00000071680839330093
    out:persName.surname	295	0.91783693	0.00000383192943077228
    exp:placeName.region	32	0.83566990	0.00000551293116462680
    out:5	82	0.85116074	0.00000607788112334637
    exp:geogName	73	0.77593244	0.00000632581466839333
    exp:placeName.settlement	167	0.87590291	0.00000690938211727142
    exp:3	76	0.82971415	0.00000814340048123796
    exp:6	75	0.89089104	0.00001275304858586339
    out:persName.forename	362	0.92159232	0.00001426230958467042
    exp:5	80	0.88315404	0.00002873600974251028
    out:6	73	0.88823384	0.00004347998129569157
    out:placeName.country	117	0.91174320	0.00005844859302012576
    exp:27	14	0.89859509	0.00010111139128096410
    out:2	106	0.87870029	0.00012339467984127947
    exp:2	106	0.89150352	0.00013927462137254036
    out:placeName.settlement	161	0.91193317	0.00015801636090376342
    exp:10	55	0.88490168	0.00019500445941971885
    out:10	55	0.88952978	0.00020384459146120533
    out:27	13	0.83260073	0.00022093811378190520
    exp:11	50	0.91544979	0.00022538447932126170
    exp:persName.surname	284	0.94568239	0.00029790914546478866
    out:geogName	68	0.87991682	0.00033570934160678480
    exp:25	14	0.83275422	0.00034911992940182120
    exp:20	23	0.86023258	0.00037403771750947510
    out:orgName	228	0.93054071	0.00041409255783249570
    exp:placeName.bloc	4	0.25000000	0.00058004178654680340
    out:placeName	4	0.45288462	0.00079963839942791270
    exp:placeName	4	0.55288462	0.00090031630413270230
    exp:placeName.district	6	0.54575163	0.00093126444116410190
    out:25	13	0.84259978	0.00098291350949343270
    exp:18	33	0.90467916	0.00099014945726474700
    exp:placeName.country	111	0.92607628	0.00103154555626810890
    out:persName.addName	16	0.85999111	0.00103238048710726150
    exp:1,2,3	11	0.71733569	0.00104285196244713480
    exp:9	70	0.89791862	0.00109937869723650940
    out:1,2,3	11	0.75929374	0.00112334313326076900
    out:15	30	0.90901990	0.00132066041179418900
    exp:15	30	0.91710071	0.00139871001216425860
    out:14	48	0.90205283	0.00145838060555712980
    out:36	6	0.74672188	0.00146644432521086550
    exp:26	14	0.86061091	0.00169416966498835550
    out:26	14	0.86434574	0.00172101465871527430
    in<1>:Chrystus	6	0.86234615	0.00178789911479861950
    out:9	69	0.89843853	0.00182996622711856130
    exp:26,27	4	0.86532091	0.00187926423000622310
    out:26,27	4	0.86532091	0.00187926423000622310
    out:4	87	0.89070069	0.00193025851603233500
    out:18	32	0.91509324	0.00208916541118153300
    exp:14	47	0.89135689	0.00247634067123241170
    exp:8	71	0.91390223	0.00248155467568570200
    out:3	67	0.89624455	0.00251005273204463700
    exp:13,14,15	7	0.69047619	0.00264339993981820200
    out:11	46	0.94453652	0.00300877389223088140
    exp:13	39	0.89762050	0.00304040573378035300
    exp:25,26	7	0.72969188	0.00305728291769260170
    in<1>:ku	3	0.64285714	0.00409664186965377500
    exp:24	13	0.84446849	0.00422204049045033550
    in<1>:Szkole	3	0.69841270	0.00459053755028235000
    in<1>:gmina	3	0.72619048	0.00471502973611559400
    out:23,24,25,26,27	3	0.74444444	0.00478548560174827300
    exp:35	3	0.73479853	0.00479495029982456600
    out:35	3	0.73479853	0.00479495029982456600
    out:20	20	0.91318903	0.00505032866577808350
    in<1>:SJL	6	0.40000000	0.00510505196247920600
    exp:36	5	0.84704664	0.00533176800260401500
    exp:23	17	0.88215614	0.00535729183315928400
    out:13	38	0.90181485	0.00563103165587168000
    in<1>:przykład	12	0.63611111	0.00619614049735634600
    in<1>:"	184	0.89698360	0.00671336491979657000
    exp:22	18	0.86584897	0.00678536930472158100
    exp:5,6	21	0.92398078	0.00701181665145694000
    exp:32	11	0.87372682	0.00725144019981003500
    in<1>:bycia	4	0.25000000	0.00765937730815748400
    exp:4	84	0.90829786	0.00781071034965166500
    exp:7	69	0.87580842	0.00825171941550910600
    in<1>:11	6	0.68919969	0.00833858334198865600
    exp:17	35	0.92766981	0.00901683910684479200
    in<1>:Ochlapusem	2	0.00000000	0.00911768813656929300
    in<1>:Wydra	2	0.00000000	0.00911768813656929300
    in<1>:molo	2	0.00000000	0.00911768813656929300
    in<1>:samą	2	0.00000000	0.00911768813656929300
    out:placeName.region	23	0.89830894	0.00950994259651506200
    out:1	206	0.91410839	0.01028654356654566000
    out:25,26	6	0.78464052	0.01052324370840473200
    in<1>:wynikiem	2	0.25000000	0.01083031507722793800
    in<1>:czci	2	0.28571429	0.01131535182961013700
    in<1>:obejrzał	2	0.33333333	0.01146449651732581700
    exp:2,3,4,5,6	2	0.36666667	0.01174236718700471900
    exp:12	48	0.91708259	0.01199411048538193800
    in<1>:przyszedł	4	0.61666667	0.01206312763924867500
    in<1>:zachowania	2	0.45000000	0.01231568593500110600
    in<1>:Bacha	2	0.41666667	0.01343470684272302300
    in<1>:grobu	4	0.74166667	0.01357123871263958600
    in<1>:Brytania	2	0.53333333	0.01357876718525224600
    in<1>:rewolucja	2	0.53333333	0.01357876718525224600

## Handling headers

When dealing with TSV files, you often face a dilemma whether to add a
header with field names as the first line of a TSV file or not:

* a header makes a TSV more readable to humans, especially when you use tools like [Visidata](https://www.visidata.org/),
  and when there is a lot of input columns (features)
* … but, on the other hand, makes it much cumbersome to process with textutils (cat, sort, shuf, etc.) or similar tools.

GEval can handle TSV with _and_ without headers. By default,
headerless TSV are assumed, but you can specify column names for
input and output/expected files with, respectively, `--in-header
in-header.tsv` and `--out-header out-header.tsv` option.

A header file (`in-header.tsv` or `out-header.tsv`) should be a one-line TSV line with column names.
(Why this way? Because now you can combine this easily with data using, for instance, `cat in-header.tsv dev-0/in.tsv`.)

Now GEval will work as follows:

* when reading a file it will first check whether the first field in
  the first line is the same as the first column name, if it is the
  case, it will assume the given TSV file contains a header line (just make sure
  this string is specific enough and won't mix up with data!),
* otherwise, it will assume it is a headerless file,
* anyway, the column names will be used for human-readable output, for
  instance, when listing worst features.

## Preparing a Gonito challenge

### Directory structure of a Gonito challenge

A definition of a [Gonito](https://gonito.net) challenge should be put in a separate
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
* `in-header.tsv` — one-line TSV file with column names for input data (features),
* `out-header.tsv` — one-line TSV file with column names for output/expected data, usually just one label,
* `train/` — subdirectory with training data (if training data are
  supplied for a given Gonito challenge at all)
* `train/in.tsv` — the input data for the training set
* `train/expected.tsv` —  the target values
* `dev-0/` — subdirectory with a development set (a sample test set,
  which won't be used for the final evaluation)
* `dev-0/in.tsv` — input data
* `dev-0/expected.tsv` — values to be guessed
* `dev-1/`, `dev-2`, ... — other dev sets (if supplied)
* `test-A/` — subdirectory with the test set
* `test-A/in.tsv` — test input (the same format as `dev-0/in.tsv`)
* `test-A/expected.tsv` — values to be guessed (the same format as
  `dev-0/expected.tsv`), note that this file should be “hidden” by the
  organisers of a Gonito challenge, see notes on the structure of
  commits below
* `test-B`, `test-C`, ... — other alternative test sets (if supplied)

### Initiating a Gonito challenge with geval

You can use `geval` to initiate a [Gonito](https://gonito.net) challenge:

    geval --init --expected-directory my-challenge --metric RMSE

(This will generate a sample toy challenge about guessing planet masses).

Of course, any other metric can
be given to generate another type of toy challenge:

    geval --init --expected-directory my-machine-translation-challenge --metric BLEU

### Preparing a Git repository

[Gonito](https://gonito.net) platform expects a Git repository with a
challenge to be submitted. The suggested way to do this will be
presented as a [Makefile](https://en.wikipedia.org/wiki/Makefile), but
of course you could use any other scripting language and the commands
should be clear if you know Bash and some basic facts about Makefiles:

* a Makefile consists of rules, each rule specifies how to build a _target_ out of _dependencies_ using
  shell commands
* `$@` is the (first) target, whereas `$<` — the first dependency
* the indentation should be done with TABs, not spaces!

```
SHELL=/bin/bash

# no not delete intermediate files
.SECONDARY:

# the directory where the challenge will be created
output_directory=...

# let's define which files are necessary, other files will be created if needed;
# we'll compress the input files with xz and leave `expected.tsv` files uncompressed
# (but you could decide otherwise)
all: $(output_directory)/train/in.tsv.xz $(output_directory)/train/expected.tsv \
     $(output_directory)/dev-0/in.tsv.xz $(output_directory)/dev-0/expected.tsv \
     $(output_directory)/test-A/in.tsv.xz $(output_directory)/test-A/expected.tsv \
     $(output_directory)/README.md \
     $(output_directory)/in-header.tsv \
     $(output_directory)/out-header.tsv
    # always validate the challenge
    geval --validate --expected-directory $(output_directory)

# we need to replace the default README.md, we assume that it
# is kept as challenge-readme.md in the repo with this Makefile;
# note that the title from README.md will be taken as the title of the challenge
# and the first paragraph — as a short description
$(output_directory)/README.md: challenge-readme.md $(output_directory)/config.txt
    cp $< $@

# prepare header files (see above section on headers)
$(output_directory)/in-header.tsv: in-header.tsv $(output_directory)/config.txt
    cp $< $@

$(output_directory)/out-header.tsv: out-header.tsv $(output_directory)/config.txt
    cp $< $@

$(output_directory)/config.txt:
    mkdir -p $(output_directory)
    geval --init --expected-directory $(output_directory) --metric MAIN_METRIC --metric AUXILIARY_METRIC --precision N --gonito-host https://some.gonito.host.net
    # `geval --init` will generate a toy challenge for a given metric(s)
    # ... but we remove the `in/expected.tsv` files just in case
    # (we will overwrite this with our data anyway)
    rm -f $(output_directory)/{train,dev-0,test-A}/{in,expected}.tsv
    rm $(output_directory)/{README.md,in-header.tsv,out-header.tsv}

# a "total" TSV containing all the data, we'll split it later
all-data.tsv.xz: prepare.py some-other-files
    # the data are generated using your script, let's say prepare.py and
    # some other files (of course, it depends on your task);
    # the file will be compressed with xz
    ./prepare.py some-other-files | xz > $@

# and now the challenge files, note that they will depend on config.txt so that
# the challenge skeleton is generated first

# The best way to split data into train, dev-0 and test-A set is to do it in a random,
# but _stable_ manner, the set into which an item is assigned should depend on the MD5 sum
# of some field in the input data (a field unlikely to change). Let's assume
# that you created a script `filter.py` that takes as an argument a regular expression that will be applied
# to the MD5 sum (written in the hexadecimal format).

$(output_directory)/train/in.tsv.xz $(output_directory)/train/expected.tsv: all-data.tsv.xz filter.py $(output_directory)/config.txt
    # 1. xzcat for decompression
    # 2. ./filter.py will select 14/16=7/8 of items in a stable random manner
    # 3. tee >(...) is Bash magic to fork the ouptut into two streams
    # 4. cut will select the columns
    # 5. xz will compress it back
    xzcat $< | ./filter.py '[0-9abcd]$' | tee >(cut -f 1 > $(output_directory)/train/expected.tsv) | cut -f 2- | xz > $@

$(output_directory)/dev-0/in.tsv.xz $(output_directory)/dev-0/expected.tsv: all-data.tsv.xz filter.py $(output_directory)/config.txt
    # 1/16 of items goes to dev-0 set
    xzcat $< | ./filter.py 'e$' | tee >(cut -f 1 > $(output_directory)/dev-0/expected.tsv) | cut -f 2- | xz > $@

$(output_directory)/test-A/in.tsv.xz $(output_directory)/test-A/expected.tsv: all-data.tsv.xz filter.py $(output_directory)/config.txt
    # (other) 1/16 of items goes to test-A set
    xzcat $< | ./filter.py 'f$' | tee >(cut -f 1 > $(output_directory)/test-A/expected.tsv) | cut -f 2- | xz > $@

# wiping out the challenge, if you are desperate
clean:
    rm -rf $(output_directory)
```

Now let's do the git stuff, we will:

1. prepare a branch (say `master`) with all the files _without_
   `test-A/expected.tsv`, this branch will be cloned by people taking
   up the challenge.
2. prepare a separate branch (or could be a repo, we'll use the branch `dont-peek`) with
   `test-A/expected.tsv` added; this branch should be accessible by
   Gonito platform, but should be kept “hidden” for regular users (or
   at least they should be kindly asked not to peek there).

Branch (1) should be the parent of the branch (2), for instance, the
repo (for the toy “planets” challenge) could be created as follows:

    cd planets  # output_directory in the Makefile above
    git init
    git add .gitignore config.txt README.md {train,dev-0}/{in.tsv.xz,expected.tsv} test-A/in.tsv.xz
    git commit -m 'init challenge'
    git remote add origin ssh://gitolite@gonito.net/planets # some repo you have access
    git push origin master
    git checkout -b dont-peek
    git add test-A/expected.tsv
    git commit -m 'hidden data'
    git push origin dont-peek

## Taking up a Gonito challenge

Clone the repo with a challenge, as given on the [Gonito](https://gonito.net) web-site, e.g.
for the toy “planets” challenge (as generated with `geval --init`):

    git clone git://gonito.net/planets

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
    git clone git://gonito.net/planets planets-secret --branch dont-peek
    cd planets
    geval --expected-directory ../planets-secret

### Uploading your results to Gonito platform

Uploading is via Git — commit your “out” files and push the commit to
your own repo. On [Gonito](https://gonito.net) you are encouraged to share your code, so
be nice and commit also your source codes.

    git remote add mine git@github.com/johnsmith/planets-johnsmith
    git add {dev-0,test-A}/out.tsv
    git add Makefile magic-bullet.py ... # whatever scripts/source codes you have
    git commit -m 'my solution to the challenge'
    git push mine master

Then let Gonito pull them and evaluate your results, either manually clicking
"submit" at the Gonito website or using `--submit` option (see below).

### Submitting a solution to a Gonito platform with GEval

A solution to a machine learning challenge can be submitted with the
special `--submit` option:

    geval --submit --gonito-host HOST --token TOKEN

where:

* _HOST_ is the name of the host with a Gonito platform
* _TOKEN_ is a special per-user authorization token (can be copied
  from "your account" page)

_HOST_ must be given when `--submit` is used (unless the creator of the challenge
put `--gonito-host` option in the `config.txt` file, note that in such a case using
`--gonito-host` option will result in an error).

If _TOKEN_ was not given, GEval attempts to read it from the `.token`
file, and if the `.token` file does not exist, the user is asked to
type it (and then the token is cached in `.token` file).

GEval with `--submit` does not commit or push changes, this needs to
be done before running `geval --submit`. On the other hand, GEval will
check whether the changes were committed and pushed.

Note that using `--submit` option for the main instance at
<https://gonito.net> is usually **NOT** needed, as the git
repositories are configured there in such a way that an evaluation is
triggered with each push anyway.

## `geval` options

```
geval - stand-alone evaluation tool for tests in Gonito platform

Usage: geval ([--init] | [-v|--version] | [-l|--line-by-line] |
             [-w|--worst-features] | [-d|--diff OTHER-OUT] |
             [-m|--most-worsening-features ARG] | [-j|--just-tokenize] |
             [-S|--submit]) ([-s|--sort] | [-r|--reverse-sort])
             [--out-directory OUT-DIRECTORY]
             [--expected-directory EXPECTED-DIRECTORY] [-t|--test-name NAME]
             [-o|--out-file OUT] [-e|--expected-file EXPECTED]
             [-i|--input-file INPUT] [-a|--alt-metric METRIC]
             [-m|--metric METRIC] [-p|--precision NUMBER-OF-FRACTIONAL-DIGITS]
             [-T|--tokenizer TOKENIZER] [--gonito-host GONITO_HOST]
             [--token TOKEN]
  Run evaluation for tests in Gonito platform

Available options:
  -h,--help                Show this help text
  --init                   Init a sample Gonito challenge rather than run an
                           evaluation
  -v,--version             Print GEval version
  -l,--line-by-line        Give scores for each line rather than the whole test
                           set
  -w,--worst-features      Print a ranking of worst features, i.e. features that
                           worsen the score significantly. Features are sorted
                           using p-value for the Mann-Whitney U test comparing the
                           items with a given feature and without it. For each
                           feature the number of occurrences, average score and
                           p-value is given.
  -d,--diff OTHER-OUT      Compare results of evaluations (line by line) for two
                           outputs.
  -m,--most-worsening-features ARG
                           Print a ranking of the "most worsening" features,
                           i.e. features that worsen the score the most when
                           comparing outputs from two systems.
  -j,--just-tokenize       Just tokenise standard input and print out the tokens
                           (separated by spaces) on the standard output. rather
                           than do any evaluation. The --tokenizer option must
                           be given.
  -S,--submit              Submit current solution for evaluation to an external
                           Gonito instance specified with --gonito-host option.
                           Optionally, specify --token.
  -s,--sort                When in line-by-line or diff mode, sort the results
                           from the worst to the best
  -r,--reverse-sort        When in line-by-line or diff mode, sort the results
                           from the best to the worst
  --out-directory OUT-DIRECTORY
                           Directory with test results to be
                           evaluated (default: ".")
  --expected-directory EXPECTED-DIRECTORY
                           Directory with expected test results (the same as
                           OUT-DIRECTORY, if not given)
  -t,--test-name NAME      Test name (i.e. subdirectory with results or expected
                           results) (default: "test-A")
  -o,--out-file OUT        The name of the file to be
                           evaluated (default: "out.tsv")
  -e,--expected-file EXPECTED
                           The name of the file with expected
                           results (default: "expected.tsv")
  -i,--input-file INPUT    The name of the file with the input (applicable only
                           for some metrics) (default: "in.tsv")
  -a,--alt-metric METRIC   Alternative metric (overrides --metric option)
  -m,--metric METRIC       Metric to be used - RMSE, MSE, Accuracy, LogLoss,
                           Likelihood, F-measure (specify as F1, F2, F0.25,
                           etc.), multi-label F-measure (specify as
                           MultiLabel-F1, MultiLabel-F2, MultiLabel-F0.25,
                           etc.), MAP, BLEU, NMI, ClippEU, LogLossHashed,
                           LikelihoodHashed, BIO-F1, BIO-F1-Labels or CharMatch
  -p,--precision NUMBER-OF-FRACTIONAL-DIGITS
                           Arithmetic precision, i.e. the number of fractional
                           digits to be shown
  -T,--tokenizer TOKENIZER Tokenizer on expected and actual output before
                           running evaluation (makes sense mostly for metrics
                           such BLEU), minimalistic, 13a and v14 tokenizers are
                           implemented so far. Will be also used for tokenizing
                           text into features when in --worst-features and
                           --most-worsening-features modes.
  --gonito-host GONITO_HOST
                           Submit ONLY: Gonito instance location.
  --token TOKEN            Submit ONLY: Token for authorization with Gonito
                           instance.
```

If you need another metric, let me know, or do it yourself!

## License

Apache License 2.0

## Authors

* Filip Graliński

## Contributors

* Piotr Halama
* Karol Kaczmarek

## Copyright

2015-2019 Filip Graliński
2019 Applica.ai

## References

Filip Graliński, Anna Wróblewska, Tomasz Stanisławek, Kamil Grabowski, Tomasz Górecki, [_GEval: Tool for Debugging NLP Datasets and Models_](https://www.aclweb.org/anthology/W19-4826/)

    @inproceedings{gralinski-etal-2019-geval,
        title = "{GE}val: Tool for Debugging {NLP} Datasets and Models",
        author = "Grali{\'n}ski, Filip  and
          Wr{\'o}blewska, Anna  and
          Stanis{\l}awek, Tomasz  and
          Grabowski, Kamil  and
          G{\'o}recki, Tomasz",
        booktitle = "Proceedings of the 2019 ACL Workshop BlackboxNLP: Analyzing and Interpreting Neural Networks for NLP",
        month = aug,
        year = "2019",
        address = "Florence, Italy",
        publisher = "Association for Computational Linguistics",
        url = "https://www.aclweb.org/anthology/W19-4826",
        pages = "254--262",
        abstract = "This paper presents a simple but general and effective method to debug the output of machine learning (ML) supervised models, including neural networks. The algorithm looks for features that lower the evaluation metric in such a way that it cannot be ascribed to chance (as measured by their p-values). Using this method {--} implemented as MLEval tool {--} you can find: (1) anomalies in test sets, (2) issues in preprocessing, (3) problems in the ML model itself. It can give you an insight into what can be improved in the datasets and/or the model. The same method can be used to compare ML models or different versions of the same model. We present the tool, the theory behind it and use cases for text-based models of various types.",
    }
