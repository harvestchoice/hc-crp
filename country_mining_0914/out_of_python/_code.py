import sys, os
import pandas as pd
import numpy as np

def concat(*args):
	strs = [str(arg) for arg in args if not pd.isnull(arg)]
	return '\n'.join(strs) if strs else np.nan
np_concat = np.vectorize(concat, otypes = [np.str])

os.chdir('/Users/maria/Projects/hc-crp/country_mining_0914/out_of_python')

d1 = pd.read_csv('../out_of_Clavin/Agriculture for Nutrition and Health 2013 Annual Report.csv'); d1.rename(columns={'no': 'A4NH'}, inplace=True)
d2 = pd.read_csv('../out_of_Clavin/Aquatic Agricultural Systems 2013 Annual Report.csv'); d2.rename(columns={'no': 'AAS'}, inplace=True)
d3 = pd.read_csv('../out_of_Clavin/Climate Change, Agriculture and Food Security 2013 Annual Report.csv'); d3.rename(columns={'no': 'CCAFS'}, inplace=True)
d4 = pd.read_csv('../out_of_Clavin/Dryland Cereals 2013 Annual Report.csv'); d4.rename(columns={'no': 'Dryland Cereals'}, inplace=True)
d5 = pd.read_csv('../out_of_Clavin/Dryland Systems 2013 Annual Report.csv'); d5.rename(columns={'no': 'Dryland Systems'}, inplace=True)
d6 = pd.read_csv('../out_of_Clavin/Forests, Trees and Agroforestry 2013 Annual Report.csv'); d6.rename(columns={'no': 'FTA'}, inplace=True)
d7 = pd.read_csv('../out_of_Clavin/GRiSP 2013 Annual Report.csv'); d7.rename(columns={'no': 'GRiSP'}, inplace=True)
d8 = pd.read_csv('../out_of_Clavin/Grain Legumes 2013 Annual Report.csv'); d8.rename(columns={'no': 'Grain Legumes'}, inplace=True)
d9 = pd.read_csv('../out_of_Clavin/Humidtropics 2013 Annual Report.csv'); d9.rename(columns={'no': 'Humid Tropics'}, inplace=True)
d10 = pd.read_csv('../out_of_Clavin/Livestock and Fish 2013 Annual Report.csv'); d10.rename(columns={'no': 'Livestock and Fish'}, inplace=True)

d12 = pd.read_csv('../out_of_Clavin/MAIZE 2013 Annual Report.csv'); d12.rename(columns={'no': 'Maize'}, inplace=True)
d13 = pd.read_csv('../out_of_Clavin/Policies Institutions and Markets 2013 Annual Report.csv'); d13.rename(columns={'no': 'PIM'}, inplace=True)
d14 = pd.read_csv('../out_of_Clavin/Roots Tubers and Bananas 2013 Annual Report.csv'); d14.rename(columns={'no': 'RTB'}, inplace=True)
d15 = pd.read_csv('../out_of_Clavin/Water, Land and Ecosystems 2013 Annual Report.csv'); d15.rename(columns={'no': 'WLE'}, inplace=True)
d16 = pd.read_csv('../out_of_Clavin/WHEAT 2013 Annual Report.csv'); d16.rename(columns={'no': 'Wheat'}, inplace=True)

d17 = pd.read_csv('../out_of_Clavin/CGIAR Intellectual Assets Report 2013.csv'); d17.rename(columns={'no': 'Intellectual Assets'}, inplace=True)
d18 = pd.read_csv('../out_of_Clavin/CGIAR Annual Report Featuring Climate-Smart Agriculture Download.csv'); d18.rename(columns={'no': 'Climate-Smart Agriculture'}, inplace=True)
d19 = pd.read_csv('../out_of_Clavin/CRP Portfolio Report 2013.csv'); d19.rename(columns={'no': 'Portofolio Report'}, inplace=True)

# missing: Genebanks
# extras: Climate-Smart Agriculture, Intellectual Assets, Portofolio Report

# replace NaN with 1
varList = [d1,d2,d3, d4, d5, d6, d7, d8, d9, d10, d12, d13, d14, d15, d16, d17, d18]
for i in varList:
	i.replace(to_replace=np.NaN,value=1,inplace=True)

# merge all into one
r1 = pd.merge(d1, d2, on='country', how='outer'); r2 = pd.merge(r1, d3, on='country', how='outer')
r3 = pd.merge(r2, d4, on='country', how='outer'); r4 = pd.merge(r3, d5, on='country', how='outer')
r5 = pd.merge(r4, d6, on='country', how='outer'); r6 = pd.merge(r5, d7, on='country', how='outer')
r7 = pd.merge(r6, d8, on='country', how='outer'); r8 = pd.merge(r7, d9, on='country', how='outer')
r9 = pd.merge(r8, d10, on='country', how='outer'); #r10 = pd.merge(r9, d11, on='country', how='outer')
r11 = pd.merge(r9, d12, on='country', how='outer'); r12 = pd.merge(r11, d13, on='country', how='outer')
r13 = pd.merge(r12, d14, on='country', how='outer'); r14 = pd.merge(r13, d15, on='country', how='outer')
r15 = pd.merge(r14, d16, on='country', how='outer'); 
r16 = pd.merge(r15, d17, on='country', how='outer');
r17 = pd.merge(r16, d18, on='country', how='outer'); 
# res = pd.merge(r17, d19, on='country', how='outer') # uncomment if last 3 docs need to be included, and comment the one bellow
res = pd.merge(r14, d16, on='country', how='outer'); 

res.rename(columns={'country': 'COUNTRY'}, inplace=True)

# replace country names according to country_mapping.csv
c_map = pd.read_csv('../country_mapping.csv')
for i in range(0,520):
	res.replace(to_replace = c_map.country[i], value = c_map.new_country[i], inplace=True)

# group by Country names and sum
res = res.groupby(['COUNTRY']).apply(sum)
del res['COUNTRY']

res.to_csv('../out_of_python/output_numbers.csv')

# append columns needed for Tableau
# replace NaN with 0 and >1 with crp name (column name)
for i in np.array(res.values.ravel()):
	if i > 0:
		res.replace(to_replace = i, value = 1, inplace = True)

# calculate the sum of the no of CRP
cnt = res.sum(axis = 1)
res['COUNT'] = cnt

for col in res.columns:
	if col <> 'COUNTRY' and col <> 'COUNT':
		res.replace(to_replace = { col : 1 }, value = col, inplace=True)

res['ALL'] = ''
for col in res.columns:
	if col <> 'COUNTRY' and col <> 'COUNT' and col <> 'ALL':
		res.ALL = np_concat(res.ALL, res[col])

res['ALL'] = res['ALL'].str.strip('\n')

res['Genebanks'] = 0

res.replace(to_replace = np.NaN, value = 0, inplace=True)

# rename columns

res.rename(columns={'A4NH' : '4 A4NH'}, inplace=True)
res.rename(columns={'AAS' : '1#3 AAS'}, inplace=True)
res.rename(columns={'CCAFS' : '7 CCAFS'}, inplace=True)
res.rename(columns={'Dryland Cereals' : '3#6 Dryland Cereals'}, inplace=True)
res.rename(columns={'Dryland Systems' : '1#1 Dryland Systems'}, inplace=True)
res.rename(columns={'FTA' : '6 Forest, Trees and Agroforestry'}, inplace=True)
res.rename(columns={'GRiSP' : '3#3 GRiSP'}, inplace=True)
res.rename(columns={'Grain Legumes' : '3#5 Grain Legumes'}, inplace=True)
res.rename(columns={'Humid Tropics' : '1#2 Humid Tropics'}, inplace=True)
res.rename(columns={'Livestock and Fish' : '3#7 Livestock and Fish'}, inplace=True)
res.rename(columns={'Genebanks' : ''}, inplace=True)
res.rename(columns={'Maize' : '3#2 Maize'}, inplace=True)
res.rename(columns={'PIM' : '2 Policies, Institutions, and Markets'}, inplace=True)
res.rename(columns={'RTB' : '3#4 Roots, Tubers and Bananas'}, inplace=True)
res.rename(columns={'WLE' : '5 Water, Land and Ecosystems'}, inplace=True)
res.rename(columns={'Wheat' : '3#1 Wheat'}, inplace=True)


res.to_csv('../out_of_python/output_tableau_v2.csv')


