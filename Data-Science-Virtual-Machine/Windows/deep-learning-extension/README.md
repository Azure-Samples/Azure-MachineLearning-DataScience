### Welcome to the Deep Learning toolkit for the Microsoft Data Science Virtual Machine

[![Deploy to Azure](http://azuredeploy.net/deploybutton.svg)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-MachineLearning-DataScience%2Fmaster%2FData-Science-Virtual-Machine%2FWindows%2Fdeep-learning-extension%2Fazuredeploy.json)

The [data science virtual machine](https://azure.microsoft.com/en-us/marketplace/partners/microsoft-ads/standard-data-science-vm/) on Azure, based on Windows Server 2012, contains popular tools for data science modeling and development activities. Some tools include Microsoft R Server Developer Edition, Anaconda Python, Jupyter notebooks for Python and R, Visual Studio Community Edition with Python and R Tools, Power BI desktop, and SQL Server Express edition. Jump start modeling and development for your data science project using software commonly used for analytics and machine learning tasks in a variety of languages including R, Python, SQL, and C#.

This deep learning toolkit provides GPU versions of mxnet and CNTK for use on [Azure GPU N-series](https://azure.microsoft.com/en-us/blog/azure-n-series-preview-availability/) instances. These GPUs use [discrete device assignment](https://channel9.msdn.com/Shows/Azure-Friday/Leveraging-NVIDIA-GPUs-in-Azure), resulting in performance that is close to bare-metal, and are well-suited to deep learning problems that require large training sets and expensive computational training efforts. The deep learning toolkit also provides a set of sample deep learning solutions that use the GPU, including image classification on the CIFAR database and a word prediction sample from character inputs.

You can click on the "Deploy to Azure" button to immediately try out the DSVM with this extension installed. Hardware compute [fees](https://azure.microsoft.com/en-us/marketplace/partners/microsoft-ads/standard-data-science-vm/) apply.

**IMPORTANT NOTE**: Before you proceed to use the **Deploy to Azure** button you must perform a one-time task to accept the terms of the data science virtual machine on your Azure subscription. You can do this by visiting [Configure Programmatic Deployment](https://ms.portal.azure.com/#blade/Microsoft_Azure_Marketplace/LegalTermsSkuProgrammaticAccessBlade/legalTermsSkuProgrammaticAccessData/%7B%22product%22%3A%7B%22publisherId%22%3A%22microsoft-ads%22%2C%22offerId%22%3A%22standard-data-science-vm%22%2C%22planId%22%3A%22standard-data-science-vm%22%7D%7D). You must also accept the license terms in this repository.

After provisioning the data science virtual machine with the deep learning toolkit, see the README file in C:\dsvm\deep-learning, or on the desktop, for more information.

For more information on provisioning and using the Data Science VM, please check out the [documentation page](https://azure.microsoft.com/documentation/articles/machine-learning-data-science-provision-vm/).
You can also find a [How-To Guide to the data science VM](https://azure.microsoft.com/documentation/articles/machine-learning-data-science-vm-do-ten-things/) that demonstrates some of the things you can do on the VM.
