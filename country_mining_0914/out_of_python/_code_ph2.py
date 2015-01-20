import sys, os
import pandas as pd
import numpy as np

def concat(*args):
	strs = [str(arg) for arg in args if not pd.isnull(arg)]
	return '\n'.join(strs) if strs else np.nan
np_concat = np.vectorize(concat, otypes = [np.str])

os.chdir('/Users/maria/Projects/hc-crp/country_mining_0914/out_of_python')

# corrected in d12: UAE -> United Arab Emirates, The Phillipines -> Phillipines
d12 = pd.read_csv('../crps_2014.csv');
d14 = pd.read_csv('output_numbers.csv');

print d12
print d14

d14.replace(to_replace=np.NaN,value=0,inplace=True)

for col in d14.columns:
	if col <> 'COUNTRY':
		for i in np.array(d14.values.ravel()):
			if i > 0:
				d14.replace(to_replace = { col : i }, value = 1, inplace = True)

for col in d12.columns:
	if col <> 'COUNTRY':
		d12.replace(to_replace = { col : col }, value = 1, inplace = True)

d12 = d12.drop(d12.index[[25]])
del d12['COUNT']
del d12['ALL']

d12 = d12.sort(['COUNTRY'])
d14 = d14.sort(['COUNTRY'])

# convert float24 to str
for col in d14.columns:
	if col != 'COUNTRY':
		d14[col] = d14[col].astype(int).astype('str')

d12.to_csv('../out_of_python/d12.csv')
d14.to_csv('../out_of_python/d14.csv')

x = pd.merge(d12, d14, how='outer', on='COUNTRY', sort=True, suffixes=('_12', '_13'))
x = x.sort(['COUNTRY'])
x.replace(to_replace = np.NaN, value = 0, inplace = True)
x['Genebanks_12'] = x['Genebanks']
x['Genebanks_13'] = x['Genebanks']

x.to_csv('../out_of_python/x.csv')

for col in x.columns:
	if col != 'COUNTRY':
		x[col] = x[col].astype(str).astype('int')

for col in d12.columns:
	if col <> 'COUNTRY':
		d = pd.DataFrame(data = {'COUNTRY': x.COUNTRY, col + ' 2012 Report': x[col + '_12'], col + ' 2013 Report': x[col + '_13']}, \
			columns = ['COUNTRY', col + ' 2012 Report', col + ' 2013 Report', 'Actual Value (please review)', \
			'Activity or Intervention', 'Conference, Meeting, Workshop, or Training Event',\
			'Partners', 'Permanent Agricultural Trial Site', 'Intended Beneficiaries'])
		d = d[d[d.columns[1]] + d[d.columns[2]] > 0]
		d[d.columns[3]] = 1
		d.to_csv('../out_of_python/v2_output/' + col + '.csv', index = False)


