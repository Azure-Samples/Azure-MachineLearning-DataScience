Azure-MachineLearning-DataScience
=================================
This repository is designed to share custom modules, utility codes, applications, and other miscellaneous codes for Azure ML studio. 

The hierarchy of this repository is:
=================================
Repository
|
|--Modules                    # Things that can be installed in Studio – reserved for when we support custom modules
    |--DataProcessing         # eg TFIDF, feature extraction, date conversion, risk tables
        |--Python
		    |--C#
		    |--R
		    |--Misc
    |--Algorithms             # Custom algorithms, i.e., Regularized Greedy Forest
        |--Python
        |--C#
        |--R
        |--Misc
    |--Misc                   # Eg call out to data provider
        |--Python
        |--C#
        |--R
        |--Misc
|--Utilities                  # Running outside of Studio, or inside module as script
    |--Python                 # Could be ipython notebook
    |--C#                     # Eg. To interact with AML APIs to copy workspaces
    |--R                      # R scripts inside ExecuteR, external scripts for data. For example code to calculate performance metrics, produce graphs, etc.
    |--Misc
|--Apps                       # apps to drive/consume AzureML, e.g., web apps, mobile apps, Excel plugins.
|--Visualization Tool         # tools/codes for visualization    
|--	Misc                      # For hard-to-classify items


Please put your codes in properly place in the repository.


 
