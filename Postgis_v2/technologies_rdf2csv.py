# deprecated - moved technologies to csv, to review in case we use ontologies
import numpy as np
import pandas as pd
import os
import rdflib
from rdflib import *
import csv

os.chdir('/media/data/Projects/hc-crp/vocabularies');

g = Graph()
g.parse("root-ontology.owl", format="xml")
gl = list(g)
# more data reshaping should be done here, either with rdflib queries or pandas pivot_table
result = open("owl_technologies.csv",'wb')
writer = csv.writer(result, dialect = 'excel')
writer.writerow(('field_1', 'field_2', 'field_3'))
writer.writerows(gl)
result.close
print gl
print list(g)

