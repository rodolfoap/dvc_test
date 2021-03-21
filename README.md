# DVC Test

Just a test of _Data Version Control_, [dvc](https://dvc.org/).

Follow the `exploring.bash` file to understand the basics of **dvc**, and the `manualtest.bash` exercise in order to run a pipeline.

This example has four executables, that produce a result based on the previous one (check the scripts, they are extremely simple). In the **dvc** jargon, that is a pipeline. The results are parameterized with the variables in the `params.yaml` file, and the final output is saved in the `metrics.yaml` file.

So, you want to choose the parameters configuration that best suits your needs, based on the metrics. For that, you will run multiple experiments.

**Requisite**: results must be reproductible, as it occurs with AI models development. Only under such constraint you can expect you are selecting a good set of parameters. If metrics would change without changing the parameters, then you should just use [git-lfs](https://git-lfs.github.com/).

### Assessment Abstract

**dvc** performs multiple disparate functions:

* **Management of large files for git**. Simple: large files are marked as `.gitignore`d and managed separately, with **svn**-like operations: `dvc add`, which is the equivalent to `git commit` (no equivalent to `git add`), and `dvc push`, equivalent to **git**. Does not need a server, like **git-lfs**. On the other end (a directory, an ssh server, Google Drive, Amazon, etc.), just a directory is needed. Files are organized and saved according to its hash. The backside is that all operations must be tracked by the user, so the user must be extremely methodical, and must be aware of the impact of each data operation in both versioning systems.
* **Running data calculation pipelines**. This part is not yet solid. The user needs to have a good knowledge of **dvc** before using it in production, because multiple types of errors and glitches are possible, and losing information is almost certain without a strict method. Pipelines are sets of chained stages, each one depending on parameters and inputs, and producing outputs. This functionality should not be part of **dvc**, but of a different application.
* **Downloading files**, which aims probably to replace **curl**.
* **Plotting graphics**, which probably aims to replace **gnuplot**.
* **Preparing omelettes**, which probably aims to replace **Pierre Gagnaire**.

Following my tests, it is possible to map a **git+dvc** repository to multiple remotes, and use files in the same remote in multiple **git+dvc** repositories.

#########################################################################################3

### **dvc** Shoots Itself on its own Foot, Sometimes

The command `dvc run` create a stage, which is a part of the processing pipeline. Notice the following facts:

* Parameters should be defined with `-p`.
* Inputs (_dependencies_ in the **dvc** jargon) are mandatory, they must be defined with `-d`.
* Outputs (_outs_ in the **dvc** jargon) are optional, they must be defined with `-o`. If results were previously added, **dvc** will refuse to consider them as outputs, so you might probably need to remove them. This is because the files tracked with **dvc** were already added.

In case you have already saved files in **dvc**, you will probably want to use them in a pipeline. But there will be a problem with the command:
```
dvc run -n phase1 -p params.yaml:x,a -o result1/dat ./1-producer

	ERROR: output 'result1/dat' is already specified in stages:
		- phase1
		- result1/dat.dvc
```

**THIS IS IMPORTANT**: This occurs because the file is already tracked in **dvc**. Files that are already tracked cannot be part of inputs or outputs. One might be tempted to just exclude the `-o result1/dat` from the command, which will make it run. But if we do so, we are removing the pipeline dependencies. Pipelines are so because each stage depend on others. So, do not remove the `-o result1/dat` from the command. Instead, **we need to remove the files from dvc**.

This is really stupid, because, as said, **dvc performs two functions**, and this is the perfect example of the consequences: one function messing with another... within the same application. This could have been fixed intelligently by **dvc**. But since its philosophy is not the traditional Unix _KISS_, but moreover _KISSASS_ (_Keep It Stupid, Scumbag... And Sometimes, Simple_), this should be managed by the user. The solution is to...

```
dvc remove result?/dat.dvc
dvc gc -wf
```
Now, it is possible to create the pipeline. Try also the `dvc dag` command.

# Bug

A simple fix for an install bug (present in Debian/Buster, on 2021/2+1/21-21:21:21):

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
