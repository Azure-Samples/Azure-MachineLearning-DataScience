### Welcome to the Microsoft Data Science Virtual Machine


[![Deploy to Azure](http://azuredeploy.net/deploybutton.svg)](https://azuredeploy.net/)

This virtual machine on Azure based on Windows Server 2012, contains popular tools for data science modeling and development activities. The main tools include Microsoft R Server Developer Edition, Anaconda Python distribution, Jupyter notebooks for Python and R, Visual Studio Community Edition with Python and R Tools, Power BI desktop, SQL Server Express edition. It also includes ML tools like CNTK (an Open Source Deep Learning toolkit from Microsoft), xgboost and Vowpal Wabbit.

Jump start modeling and development for your data science project using software commonly used for analytics and machine learning tasks in a variety of languages including R, Python, SQL, C# all pre-installed. Visual Studio provides an easy to use IDE to develop and test your code. Jupyter notebooks offers a browser based experimentation and development environment for both Python and R. Microsoft R Services Developer edition included in the VM comes with Microsoft's RevoScaleR package in R that enables high-performance, scalable, parallelized, and distributed “Big Data Big Analytics.” On the VM, there is Azure SDK which allows you to build your applications using various services in the cloud that are part of the Cortana Analytics Suite which includes Azure Machine Learning, Azure data factory, Stream Analytics and SQL Datawarehouse, Hadoop, Data Lake, Spark and more. In addition, we also include ML tools like CNTK (Open Source Deep Learning toolkit from Microsoft), xgboost and Vowpal Wabbit.

For more information on provisioning and using the Data Science VM, please check out the [documentation page](https://azure.microsoft.com/documentation/articles/machine-learning-data-science-provision-vm/). 
Youy can also find a [How-To Guide to the data science VM](https://azure.microsoft.com/documentation/articles/machine-learning-data-science-vm-do-ten-things/) that demonstrates some of the things you can do on the VM.

You can click on the "Deploy to Azure" button to immediately try out the VM (Azure subscription required. Hardware compute [fees](https://azure.microsoft.com/en-us/marketplace/partners/microsoft-ads/linux-data-science-vm/) applies. [Free Trial](https://azure.microsoft.com/free/) available for new customers). 

**IMPORTANT NOTE**: Before you proceed to use the **Deploy to Azure** button you must perform a one-time task to accept the terms of the data science virtual machine on your Azure subscription. You can do this by visiting [Configure Programmatic Deployment](https://ms.portal.azure.com/#blade/Microsoft_Azure_Marketplace/LegalTermsSkuProgrammaticAccessBlade/legalTermsSkuProgrammaticAccessData/%7B%22product%22%3A%7B%22publisherId%22%3A%22microsoft-ads%22%2C%22offerId%22%3A%22standard-data-science-vm%22%2C%22planId%22%3A%22standard-data-science-vm%22%7D%7D)


[![Deploy to Azure](http://azuredeploy.net/deploybutton.svg)](https://azuredeploy.net/)

To create multiple instances of the Windows DSVM you can run the following command from a Azure CLI.

```
azure login
# Change to your subscription if you want to create VMs in non defaulty subscription
azure group create -n [RGNAME] -l "West US 2"
azure group deployment create -g [RGNAME] --template-uri https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Data-Science-Virtual-Machine/Windows/multiazuredeploy.json
```


