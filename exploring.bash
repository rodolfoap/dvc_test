#!/bin/bash

# Run this manually.
exit

# Start using an empty git repository.
mkdir test
cd test
git init
dvc init

# Check all the .dvc files
ls -la

# Add a remote, in my case, this is just a directory
dvc remote add -d origin /opt/dvc/
cat .dvc/config

# Create a big file
dd if=/dev/urandom of=longfile bs=1024k count=100

# Add the file to DVC, equivalent to git commit; there's no equivalent to 'git add'.
dvc add longfile

# Check the contents of the dvc file. It is stupidly simple: what is saved is just a pointer to the file
ls -la
cat longfile.dvc

# Stupidly simple: the big file is not saved in git.
cat .gitignore

# The equivalent to a git push is dvc push.
dvc push

# Stupidly simple: the repository is just based on file names.
# Notice that **directory/filename** (/opt/dvc/d7/587431a2d5cf02a994849d5c960a57)
# ... corresponds exactly to the hash value:    d7587431a2d5cf02a994849d5c960a57
find /opt/dvc/ -type f

# Some cleanout...
cd ..
rm -r test

# Cleaning the repository is as simple as...
rm -r /opt/dvc/d7/
