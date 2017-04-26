import pyodbc
import pickle
cnxn = pyodbc.connect('DRIVER={SQL Server};SERVER={SERVER_NAME};DATABASE={DB_NAME};UID={USER_NAME};PWD={PASSWORD}')
cursor = cnxn.cursor()
cursor.execute("EXECUTE [nyctaxi1].[dbo].[SerializePlots]")
tables = cursor.fetchall()
for i in range(0, len(tables)):
    fig = pickle.loads(tables[i][0])
    fig.savefig(str(i)+'.png')