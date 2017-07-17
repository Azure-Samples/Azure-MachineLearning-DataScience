import pyodbc
import pickle
import os

cnxn = pyodbc.connect('DRIVER={SQL Server};SERVER={SERVER_NAME};DATABASE={DB_NAME};UID={USER_NAME};PWD={PASSWORD}')
cursor = cnxn.cursor()
cursor.execute("EXECUTE [dbo].[SerializePlots]")
tables = cursor.fetchall()
for i, table in enumerate(tables):
    fig = pickle.loads(table[0])
    fig.savefig(str(i)+'.png')

print("The plots are saved in directory:", os.getcwd())
