# DVC Test

Just a test of _Data Version Control_, [dvc](https://dvc.org/).

This example has four executables, that produce a result based on the previous one (check the scripts, they are extremely simple). In the **dvc** jargon, that is a pipeline. The results are parameterized with the variables in the `params.yaml` file, and the final output is saved in the `metrics.yaml` file.

So, you want to choose the parameters configuration that best suits your needs, based on the metrics. For that, you will run multiple experiments.

**Requisite**: results must be reproductible, as it occurs with AI models development. Only under such constraint you can expect you are selecting a good set of parameters. If metrics would change without changing the parameters, then you should just use [git-lfs](https://git-lfs.github.com/).

### Assessment Abstract

**dvc** performs two functions:

* **Management of large files for git**. Simple: large files are marked as `.gitignore`d and managed separately, with **svn**-like operations: `dvc add`, which is the equivalent to `git commit` (no equivalent to `git add`), and `dvc push`, equivalent to **git**. Does not need a server, like **git-lfs**. On the other end (a directory, an ssh server, Google Drive, Amazon, etc.), just a directory is needed. Files are organized and saved according to its hash. The backside is that all operations must be tracked by the user, so the user must be extremely methodical, and must be aware of the impact of each data operation in both versioning systems.
* **Running data calculation pipelines**. This part is not yet solid. The user needs to have a good knowledge of **dvc** before using it in production, because multiple types of errors and glitches are possible, and losing information is almost certain without a strict method. Pipelines are sets of chained stages, each one depending on parameters and inputs, and producing outputs. This functionality should not be part of **dvc**, but of a different application.

This swiss-knife of the data-scientist-hacker also does other functions:

* **Downloading files**, which aims probably to replace **curl**.
* **Plotting graphics**, which probably aims to replace **gnuplot**.
* **Preparing omelettes**, perhaps not quite documented and not quite functional.

### Initialize a Git repository

Start by cloning this repository, and delete all **dvc stuff** by running:
```
git checkout -b local-test-$(date +%Y%m%d.%H%M%S)
dvc destroy -f
rm -f metrics.yaml result?/dat* .dvcignore
git add .
git commit -m "Resetting dvc";
```

### Initialize **dvc**

```
dvc init
	Initialized DVC repository.
	You can now commit the changes to git.
	+---------------------------------------------------------------------+
	|                                                                     |
	|        DVC has enabled anonymous aggregate usage analytics.         |
	|     Read the analytics documentation (and how to opt-out) here:     |
	|             <https://dvc.org/doc/user-guide/analytics>              |
	|                                                                     |
	+---------------------------------------------------------------------+
	What's next?
	------------
	- Check out the documentation: <https://dvc.org/doc>
	- Get help and share ideas: <https://dvc.org/chat>
	- Star us on GitHub: <https://github.com/iterative/dvc>
```

### Add a remote

I just use a directory as a remote, but you can use **ssh**, Google Drive, Google Cloud, an Amazon bucket, etc. This is similar to Git.

```
dvc remote add -d origin /opt/dvc
	Setting 'origin' as a default remote.

cat .dvc/config
	[core]
	    remote = origin
	['remote "origin"']
	    url = /opt/dvc
```

### Analyzing what DVC does

```
mkdir test
cd test/
dd if=/dev/urandom of=longfile bs=1024k count=100
	100+0 records in
	100+0 records out
	104857600 bytes (105 MB, 100 MiB) copied, 2.27712 s, 46.0 MB/s

# Adding the file to DVC, equivalent to git commit; there's no equivalent to 'git add'.

dvc add longfile
	100% Add|.......................|1/1 [00:00,  2.24file/s]
	To track the changes with git, run:
		git add longfile.dvc .gitignore

ls -la
	drwxr-xr-x 9 rodolfoap rodolfoap 4.0K Mar 20 05:54 ../
	drwxr-xr-x 2 rodolfoap rodolfoap 4.0K Mar 20 05:56 ./
	-rw-r--r-- 1 rodolfoap rodolfoap   10 Mar 20 05:56 .gitignore
	-rw-r--r-- 1 rodolfoap rodolfoap 100M Mar 20 05:56 longfile
	-rw-r--r-- 1 rodolfoap rodolfoap   81 Mar 20 05:56 longfile.dvc

# Stupidly simple: the big file is not saved in git.

cat .gitignore
	/longfile

# Stupidly simple: what is saved is just a pointer to the file

cat longfile.dvc
	outs:
	- md5: d7587431a2d5cf02a994849d5c960a57
	  size: 104857600
	  path: longfile

# The equivalent to a git push is dvc push.

dvc push
	1 file pushed

# Stupidly simple: the repository is just based on file names.
# Notice that **directory/filename** (/opt/dvc/d7/587431a2d5cf02a994849d5c960a57)
# ... corresponds exactly to the hash value:    d7587431a2d5cf02a994849d5c960a57

find /opt/dvc/ -type f
	/opt/dvc/d7/587431a2d5cf02a994849d5c960a57

cd ..
rm -r test

	# Cleaning the repository is as simple as...

rm -r /opt/dvc/d7/
```

Following my tests, it is possible to map a **git+dvc** repository to multiple remotes, and use files in the same remote in multiple **git+dvc** repositories.

### Function 1: Managing files

Take some time to check and run the scripts `0-...` to `5-...` and check the output, the `metrics.yaml` file.
```
./1-producer
./2-modifier
./3-modifier
./4-modifier
./5-genresults
cat metrics.yaml
```

Then, add the generated files:

```
git status
	On branch master
	Your branch is up to date with 'origin/master'.
	Changes to be committed:
  	(use "git restore --staged <file>..." to unstage)
		new file:   metrics.yaml

dvc add result?/dat
	100% Add|.................................|4/4 [00:00, 12.19file/s]
	To track the changes with git, run:
		git add result3/dat.dvc result4/dat.dvc result1/dat.dvc result2/dat.dvc

git add .

git status
	On branch master
	Your branch is up to date with 'origin/master'.
	Changes to be committed:
  	(use "git restore --staged <file>..." to unstage)
		new file:   metrics.yaml
		new file:   result1/dat.dvc
		new file:   result2/dat.dvc
		new file:   result3/dat.dvc
		new file:   result4/dat.dvc

git commit -m "Added results"
dvc push
	4 files pushed
```

### Stages and pipelines

Each of the following commands will create a stage, which is a part of the processing pipeline. Notice the following facts:

* Parameters should be defined with `-p`.
* Inputs (_dependencies_ in the **dvc** jargon) are mandatory, they must be defined with `-d`.
* Outputs (_outs_ in the **dvc** jargon) are optional, they must be defined with `-o`. If results were previously added, **dvc** will refuse to consider them as outputs, so you might probably need to remove them. This is because the files tracked with **dvc** were already added.

So, there will be a problem with the first command:
```
dvc run -n phase1 -p params.yaml:x,a -o result1/dat ./1-producer

	ERROR: output 'result1/dat' is already specified in stages:
		- phase1
		- result1/dat.dvc
```

**THIS IS IMPORTANT**: This occurs because the file is already tracked in **dvc**. Files that are already tracked cannot be part of inputs or outputs. One might be tempted to just exclude the `-o result1/dat` from the command, which will make it run. But if we do so, we are removing the pipeline dependencies. Pipelines are so because each stage depend on others. So, do not remove the `-o result1/dat` from the command. Instead, **we need to remove the files from dvc**.

This is really stupid, because, as said, **dvc performs two functions**, and this is the perfect example of the consequences: one function messing with another... within the same application. This could have been fixed intelligently by **dvc**. But since its philosophy is not the traditional Unix _KISS_, but moreover _KISSASS_ (_Keep It Stupid, Scumbag... And Sometimes, Simple_), this should be managed by the user. So:

```
dvc remove result?/dat.dvc
dvc gc -wf
```
Now, it is possible to create the pipeline:

```
dvc run -n phase1 -p params.yaml:x,a -o result1/dat ./1-producer
dvc run -n phase2 -d result1/dat -p params.yaml:b -o result2/dat ./2-modifier
dvc run -n phase3 -d result2/dat -p params.yaml:c -o result3/dat ./3-modifier
dvc run -n phase4 -d result3/dat -p params.yaml:d -o result4/dat ./4-modifier
dvc run -n phase5 -d result4/dat -M metrics.yaml --force ./5-genresults
dvc dag
	+--------+
	| phase1 |
	+--------+
	     *
	     *
	     *
	+--------+
	| phase2 |
	+--------+
	     *
	     *
	     *
	+--------+
	| phase3 |
	+--------+
	     *
	     *
	     *
	+--------+
	| phase4 |
	+--------+
	     *
	     *
	     *
	+--------+
	| phase5 |
	+--------+
git add .
git status
git commit -m "Added pipeline"
```

Nothing fancy until here. Pipelines were executed, but no changes are done, because we've already committed the current state of the repository.

Notice that `dvc.yaml` and `dvc.lock` have been created. Check them and then commit them.

### Function 2: Tracking pipeline results

Modify the `c` parameter and ask **dvc** to run the pipeline:

```
cat params.yaml
	x: streptococcus
	a: 7
	b: 9
	c: 2
	d: 4

sed -i '/^c:/s/.*/c: 13/' params.yaml

cat params.yaml
	x: streptococcus
	a: 7
	b: 9
	c: 13
	d: 4

dvc params diff
	Path         Param    Old    New
	params.yaml  c        2      13

dvc repro
	Stage 'phase1' didn't change, skipping
	Stage 'phase2' didn't change, skipping
	Running stage 'phase3':
	> ./3-modifier
	Updating lock file 'dvc.lock'
	
	Running stage 'phase4':
	> ./4-modifier
	Updating lock file 'dvc.lock'
	
	Running stage 'phase5':
	> ./5-genresults
	---
	results:
  	chars: 364
  	numbers: 273
  	lowernumbers: 210
  	highernumbers: 63
  	letters: 91
  	vowels: 28
  	consonants: 63
	Updating lock file 'dvc.lock'
	
	To track the changes with git, run:
		git add dvc.lock
	Use `dvc push` to send your updates to remote storage.
	
dvc push
	2 files pushed
git add .
git status
git commit -m "Modified parameters"
```

Notice that only the stages affected by the parameter changes have been updated. So, it can be said that _**dvc** is equivalent to a Makefile for data projects_.

Commit your changes and push **git** and **dvc** files.

## Experiments

Up to here, there's no way to perform comparisons. For that, **dvc** provides _experiments_:

```
dvc exp run --set-param b=7 --set-param c=6 --set-param d=5
dvc exp run --set-param b=8 --set-param c=9 --set-param d=5
dvc exp run --set-param b=9 --set-param c=9 --set-param d=5
dvc exp run --set-param b=9 --set-param c=8 --set-param d=6
dvc exp run --set-param b=9 --set-param c=9 --set-param d=6
dvc exp run --set-param b=9 --set-param c=10 --set-param d=4
dvc exp run --set-param b=9 --set-param c=10 --set-param d=5
dvc exp run --set-param b=9 --set-param c=10 --set-param d=6

dvc exp show
┏━━━━━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━┳━━━┳━━━━┳━━━┓
┃ Experiment    ┃ Created  ┃ results.chars ┃ results.numbers ┃ results.lowernumbers ┃ results.highernumbers ┃ results.letters ┃ results.vowels ┃ results.consonants ┃ x             ┃ a ┃ b ┃ c  ┃ d ┃
┡━━━━━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━╇━━━╇━━━━╇━━━┩
│ workspace     │ -        │           336 │             245 │                  140 │                   105 │              91 │             28 │                 63 │ streptococcus │ 7 │ 9 │ 10 │ 6 │
│ master        │ 07:19 AM │           238 │             147 │                   28 │                   119 │              91 │             28 │                 63 │ streptococcus │ 7 │ 9 │ 4  │ 8 │
│ ├── exp-0d557 │ 07:21 AM │           336 │             245 │                  140 │                   105 │              91 │             28 │                 63 │ streptococcus │ 7 │ 9 │ 10 │ 6 │
│ ├── exp-ebafd │ 07:21 AM │           329 │             238 │                  140 │                    98 │              91 │             28 │                 63 │ streptococcus │ 7 │ 9 │ 10 │ 5 │
│ ├── exp-04477 │ 07:21 AM │           322 │             231 │                  168 │                    63 │              91 │             28 │                 63 │ streptococcus │ 7 │ 9 │ 10 │ 4 │
│ ├── exp-06c37 │ 07:21 AM │           259 │             168 │                    0 │                   168 │              91 │             28 │                 63 │ streptococcus │ 7 │ 9 │ 9  │ 6 │
│ ├── exp-899c8 │ 07:21 AM │           252 │             161 │                    0 │                   161 │              91 │             28 │                 63 │ streptococcus │ 7 │ 9 │ 8  │ 6 │
│ ├── exp-3ca13 │ 07:21 AM │           252 │             161 │                    0 │                   161 │              91 │             28 │                 63 │ streptococcus │ 7 │ 9 │ 9  │ 5 │
│ ├── exp-22354 │ 07:20 AM │           245 │             154 │                    0 │                   154 │              91 │             28 │                 63 │ streptococcus │ 7 │ 8 │ 9  │ 5 │
│ └── exp-077f8 │ 07:20 AM │           217 │             126 │                    0 │                   126 │              91 │             28 │                 63 │ streptococcus │ 7 │ 7 │ 6  │ 5 │
└───────────────┴──────────┴───────────────┴─────────────────┴──────────────────────┴───────────────────────┴─────────────────┴────────────────┴────────────────────┴───────────────┴───┴───┴────┴───┘
```

You can set your branch to one of those and save it. Just run:

```
dvc exp apply exp-04477

dvc exp push origin exp-04477
	Pushed experiment 'exp-04477' to Git remote 'origin'.
```

# Bug
```
dvc exp run --set-param d=3
	ERROR: unexpected error - [Errno 2] No such file or directory: '/usr/lib/dvc/text_unidecode/data.bin'

pyp install text-unidecode
	Collecting text-unidecode
	  Downloading text_unidecode-1.3-py2.py3-none-any.whl (78 kB)
	     |................................| 78 kB 3.1 MB/s
	Installing collected packages: text-unidecode
	Successfully installed text-unidecode-1.3
sudo mkdir -p /usr/lib/dvc/text_unidecode/
sudo cp /usr/local/lib/python3.7/dist-packages/text_unidecode/data.bin /usr/lib/dvc/text_unidecode/
```
