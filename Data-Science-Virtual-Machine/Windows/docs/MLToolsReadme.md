## ML Tools on the DSVM

In addition to Microsoft R Server, Python, Jupyter Notebook and access to various Azure services like Azure ML, we have installed some advanced ML/analytics tools on the data science virtual machine. 

This directory (C:\dsvm\tools\) contains binaries for some ML and analytics tools. Currently there are three tools here. We hope to add more tools in future here. 

### Vowpal Wabbit (VW)
Vowpal Wabbit is a fast online learning code. This is a command line tool (vw.exe) that is available in the PATH. 

To run the tool on a very basic example do the following: 

       #Change directory to C:\dsvm\tools\VowpalWabbit\demo
       vw house_dataset

There are other larger demos in that directory. Please refer to [VW documentation](https://github.com/JohnLangford/vowpal_wabbit) for more info. 

### xgboost

This is a library that is designed, and optimized for boosted (tree) algorithms. 

It is provided as a command line as well as a R library. To use this library in R, within your R IDE you can just load the library.

	library(xgboost)

For xgboost command line, you need to run it in Git Bash. xgboost.exe is in the PATH. Steps to run one of the examples is below:

       #Open Git Bash (You can see a icon in the Start menu or desktop)
       cd /c/dsvm/tools/xgboost/demo/binary_classification
       xgboost mushroom.conf

More Info: https://xgboost.readthedocs.org/en/latest/, https://github.com/dmlc/xgboost

NOTE: This tool will not directly run in command prompt. You must currently use Git Bash to run xgboost. 

### CNTK (Microsoft Cognitive Toolkit)

CNTK (http://www.cntk.ai/), the Cognitive Toolkit by Microsoft Research, is a unified deep-learning toolkit that describes neural networks as a series of computational steps via a directed graph. This is a command line tool. (CNTK.exe) and is found in the PATH. 

To run a basic sample do the following in command prompt or git bash:

        cd C:\dsvm\tools\cntk2\cntk\Examples\Other\Simple2d\Data
        cntk configFile=../Config/Simple.cntk

You will find the model output in C:\dsvm\tools\cntk2\cntk\Examples\Other\Simple2d\Output\Models

More Info: https://github.com/Microsoft/CNTK, https://github.com/Microsoft/CNTK/wiki




