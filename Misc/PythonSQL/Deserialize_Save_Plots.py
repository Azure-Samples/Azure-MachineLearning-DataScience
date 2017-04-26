import pyodbc
import pickle
cnxn = pyodbc.connect('DRIVER={SQL Server};SERVER=IAAS16165370.redmond.corp.microsoft.com;DATABASE=nyctaxi1;UID=Xibin;PWD=TDSP@RedB24.,')
cursor = cnxn.cursor()
cursor.execute("EXECUTE [nyctaxi1].[dbo].[SerializePlots]")
tables = cursor.fetchall()
for i in range(0, len(tables)):
    fig = pickle.loads(tables[i][0])
    fig.savefig(str(i)+'.png')