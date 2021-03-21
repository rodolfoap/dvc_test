#!/bin/bash

# Run this manually. 
exit

ORIGIN=/opt/dvc
mkdir -p $ORIGIN

# Start by cloning this repository, and delete all **dvc stuff** by running:

git checkout -b local-test-$(date +%Y%m%d.%H%M%S)
dvc destroy -f
rm -f metrics.yaml result?/dat* .dvcignore
git add .
git commit -m "Resetting dvc";

# Initialize **dvc**

dvc init

# Add a remote
dvc remote add -d origin $ORIGIN
cat .dvc/config

# Test and run the provided scripts in order to generate some data to use with dvc
./1-producer
./2-modifier
./3-modifier
./4-modifier
./5-genresults

# Add the data to git and dvc
git status
dvc add result?/dat
git add .
git status
git commit -m "Added results"
dvc push

# Create a pipeline. This is done with the command dvc run. Sadly, the following command will give an error:
#
#    dvc run -n phase1 -p params.yaml:x,a -o result1/dat ./1-producer
#
# The solution is to...
dvc remove result?/dat.dvc
dvc gc -wf

# Then, the pipeline can be created:
dvc run -n phase1 -p params.yaml:x,a -o result1/dat ./1-producer
dvc run -n phase2 -d result1/dat -p params.yaml:b -o result2/dat ./2-modifier
dvc run -n phase3 -d result2/dat -p params.yaml:c -o result3/dat ./3-modifier
dvc run -n phase4 -d result3/dat -p params.yaml:d -o result4/dat ./4-modifier
dvc run -n phase5 -d result4/dat -M metrics.yaml --force ./5-genresults

# The dvc dag command depicts the pipeline graphically:
dvc dag|sed 's/^/\t/'
git add .
git status
git commit -m "Added pipeline"

# Nothing fancy until here. Pipelines were executed, but no changes are done, 
# because we've already committed the current state of the repository. Notice that
# dvc.yaml and dvc.lock have been created.

# Modify the `c` parameter and ask **dvc** to run the pipeline. Save the results.
# Notice that only the stages affected by the parameter changes will be updated.
# So, it can be said that _**dvc** is equivalent to a Makefile for data projects_.
cat params.yaml
sed -i '/^c:/s/.*/c: 13/' params.yaml
cat params.yaml
dvc params diff
dvc repro
dvc push
git add .
git status
git commit -m "Modified parameters"

# Up to here, no way to perform comparisons. For that, dvc provides experiments:
dvc exp run --set-param b=7 --set-param c=6 --set-param d=5
dvc exp run --set-param b=8 --set-param c=9 --set-param d=5
dvc exp run --set-param b=9 --set-param c=9 --set-param d=5
dvc exp run --set-param b=9 --set-param c=8 --set-param d=6
dvc exp run --set-param b=9 --set-param c=9 --set-param d=6
dvc exp run --set-param b=9 --set-param c=10 --set-param d=4
dvc exp run --set-param b=9 --set-param c=10 --set-param d=5
dvc exp run --set-param b=9 --set-param c=10 --set-param d=6

# This is the best part: assessing the impact of the inputs on the outputs:
dvc exp show|sed s/_/_/

# Generates something like exp-t2ns8. Use such label to make a branch out of it:
dvc exp apply exp-t2ns8
dvc exp push origin exp-t2ns8

# Your process might generate data that can be graphically represented. For the example, see logs.csv, taken from the dvc documentation:
dvc plots show logs.csv

# That will create plots.html. Open it with your browser. There seems to be no way to save it as a graphic file. According to the doc, you can save it using the browser.
