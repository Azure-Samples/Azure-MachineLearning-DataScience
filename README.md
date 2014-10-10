Azure-MachineLearning-DataScience
=================================
This repository is designed to share custom modules, utility codes, applications, and other miscellaneous codes for Azure ML studio. 
Please check the hierarchical structure of this repository below and put your codes in proper place in the repository.

#Repository Structure
```
Repository
|
|--Modules                    // Things that can be installed in Studio – reserved for when we support custom modules in that language
    |--DataProcessing         // Codes process the data in Studio, e.g., TFIDF, feature extraction, date conversion, risk tables
        |--Python
        |--C#
        |--R
        |--Misc
    |--Algorithms             // Custom algorithms, i.e., Regularized Greedy Forest
        |--Python
        |--C#
        |--R
        |--Misc
    |--Misc                   // Miscellaneous codes, e.g., call out to data provider
        |--Python
        |--C#
        |--R
        |--Misc
|--Utilities                  // Running outside of Studio, or inside module as script
    |--Python                 // Could be ipython notebook
    |--C#                     // Examples include codes to interact with AML APIs to copy workspaces
    |--R                      // R scripts inside ExecuteR, external scripts for data. For example codes to calculate performance metrics, produce graphs, etc.
    |--Misc
|--Apps                       // Apps to drive/consume AzureML, e.g., web apps, mobile apps, Excel plugins.
|--Visualization Tool         // Tools/codes for visualization    
|--	Misc                      // For hard-to-classify items
```


