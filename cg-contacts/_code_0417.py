import pandas as pd
import re

d = pd.read_csv('/Users/maria/Projects/hc-crp/cg-contacts/contacts_export_0417.csv',low_memory=False)
print d.head()
d = pd.DataFrame(d, columns = ['Full Name', 'Company', 'E-mail', 'File As' ])
d = d.dropna()

d['Email'] = d['E-mail'].apply(str.lower)
del d['E-mail']
print len(d)
d = d[d['Email'].str.contains('cgiar.org|irri.org')]

d['tmp'] = d['Email'].str.replace('@cgiar.org|@irri.org', '')

d = d[d['tmp'].str.contains('\.')]

d = d[~d['tmp'].str.contains('africarice|africa|ciat|ifpri|cip|icrisat|agroforestry|icraf|worldfish|iita|icarda|\
	cifor|iwmi|cimmyt|ilri|bioversity')]

del d['tmp']
print d.Company.unique()
d.Company.replace(to_replace='AATF', value='AFF' , inplace=True)
d.Company.replace(to_replace='WorldAgroforestry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World Agroforstry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='Wolrd Agroforestry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='Worl Agroforestry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World  Agroforestr', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World Agroforestrt', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World Agroforestry.', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World AGroforestry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World agroforestry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World Agroforetry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World Agroforstry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='Worldagroforestry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World  Agroforestry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World Agoforestry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World Agrforestry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='World Agroforerstry', value='World Agroforestry' , inplace=True)
d.Company.replace(to_replace='WorldFish Center', value='WorldFish' , inplace=True)
d.Company.replace(to_replace='Worldifsh', value='WorldFish' , inplace=True)
d.Company.replace(to_replace='Cimmyt', value='CIMMYT' , inplace=True)
d.Company.replace(to_replace='CIMMYT ', value='CIMMYT' , inplace=True)
d.Company.replace(to_replace='Cip', value='CIP' , inplace=True)
d.Company.replace(to_replace='ICRAf', value='ICRAF' , inplace=True)
d.Company.replace(to_replace='ILRI ', value='ILRI' , inplace=True)
d.Company.replace(to_replace='ilri', value='ILRI' , inplace=True)
d.Company.replace(to_replace='AFricaRice', value='AfricaRice' , inplace=True)
d.Company.replace(to_replace='AfriceRice', value='AfricaRice' , inplace=True)
d.Company.replace(to_replace='AfriceRice', value='AfricaRice' , inplace=True)
d.Company.replace(to_replace='(AfricaRice)', value='BIOVERSITY' , inplace=True)

# replace based on the last space
# d['Last Name'] = d['File As'].str.extract('.*\W([^\W]+)$')
# d['First Name'] = d['File As'].str.extract('(.*)\W[^\W]+$')

d['File As'].
d['File As'] = d['File As'].map(lambda x: x.lstrip(',').rstrip(','))

d['First Name'] = d['File As'].str.extract('.*\,([^\,]+)$')
d['Last Name'] = d['File As'].str.extract('(.*)\,[^\,]+$')
d['First Name'] = d['First Name'].map(lambda x: x.lstrip(' ').rstrip(' '))
d['Last Name'] = d['Last Name'].map(lambda x: x.lstrip(' ').rstrip(' '))
d['First Name'] = d['First Name'].map(lambda x: x.lstrip(',').rstrip(','))
d['Last Name'] = d['Last Name'].map(lambda x: x.lstrip(',').rstrip(','))

d = d[d['File As'].str.contains(',')]
print len(d)
print d.head()
del d['Full Name']
print d.sort(['Company','Last Name'])

d.to_csv('/Users/maria/Projects/hc-crp/cg-contacts/test.csv', index = False)


d.sort(['Company','Last Name']).to_csv('/Users/maria/Projects/hc-crp/cg-contacts/cg_contacts_0420.csv', index = False)



d = pd.DataFrame(d, columns = ['First Name', 'Last Name', 'Company', 'Department', 'E-mail Display Name' ])
d = d.dropna()
d['Email'] = d['E-mail Display Name'].str.extract('.*\(([^\)]+)\)$')
del d['E-mail Display Name']

d['Department'] = d['Department'].apply(str.upper)
d2 = d[d['Department'] == 'EPTD']

print 'reer'.upper()
d2.sort(['Company','First Name']).to_csv('/Users/maria/Projects/hc-crp/cg-contacts/cg_eptd.csv', index = False)

