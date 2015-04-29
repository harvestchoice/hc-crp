import pandas as pd

d = pd.read_csv('/Users/maria/Projects/hc-crp/cg-contacts/contacts_1009.CSV',low_memory=False)
print d.head()
d = pd.DataFrame(d, columns = ['First Name', 'Last Name', 'Company', 'E-mail Display Name' ])
d = d.dropna()
d['Email'] = d['E-mail Display Name'].str.extract('.*\(([^\)]+)\)$')
del d['E-mail Display Name']

d['Email'] = d['Email'].apply(str.lower)

d = d[d['Email'].str.contains('cgiar.org|irri.org')]

d['tmp'] = d['Email'].str.replace('@cgiar.org|@irri.org', '')

d = d[d['tmp'].str.contains('\.')]

d = d[~d['tmp'].str.contains('africarice|africa|ciat|ifpri|cip|icrisat|agroforestry|icraf|worldfish|iita|icarda|\
	cifor|iwmi|cimmyt|ilri|bioversity')]

del d['tmp']

d.sort(['Company','First Name']).to_csv('/Users/maria/Projects/hc-crp/cg-contacts/cg_contacts_0120.csv', index = False)


d = pd.DataFrame(d, columns = ['First Name', 'Last Name', 'Company', 'Department', 'E-mail Display Name' ])
d = d.dropna()
d['Email'] = d['E-mail Display Name'].str.extract('.*\(([^\)]+)\)$')
del d['E-mail Display Name']

d['Department'] = d['Department'].apply(str.upper)
d2 = d[d['Department'] == 'EPTD']

print 'reer'.upper()
d2.sort(['Company','First Name']).to_csv('/Users/maria/Projects/hc-crp/cg-contacts/cg_eptd.csv', index = False)

