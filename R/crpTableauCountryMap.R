#####################################################################################
# Title: Reshape MSExcel Sheets for Tableau
# Date: September 2013
# Project:  HarvestChoice, CRP Mapping
# Author: Bacou, Melanie <mel@mbacou.com>
#####################################################################################

setwd("~/Google Drive")

library(foreign)
library(reshape2)
library(stringr)

# Reshape CRP map 1)
d1 <- read.delim("./2013-CRP/maps/CRPs by Country wk1.txt", sep="\t")
d1 <- dcast(d1, COUNTRY~CRP)

names(d1)[2:17] <-  c("4 Nutrition and Health",
                      "1.3 Aquatic Agricultural Systems",
                      "7 Climate Change, Ag. and Food Security",                    
                      "3.6 Dryland Cereals", "1.1 Dryland Systems",                
                      "6 Forest, Trees, and Agroforestry", "Genebanks",                  
                      "3.5 Grain Legumes", "3.3 GRiSP",                         
                      "1.2 Humid Tropics", "3.7 Livestock and Fish",               
                      "3.2 Maize", "2 Policies, Institutions, and Markets",
                      "3.4 Roots, Tubers and Bananas", "3.1 Wheat",                         
                      "5 Water, Land and Ecosystems")   

# Reorder CRP columns
t <- names(d1)[2:17]
t <- t[order(t)]
d1 <- d1[, c("COUNTRY", t)]

# Add count
d1$count <- rowSums(d1[, 2:17])

# Write out for MSExcel
write.table(d1, "./2013-CRP/out/CRPs by Country wk1 (table).tab", sep="\t", na="", row.names=F)

# Concat
for (i in names(d1)[2:17]) d1[, i] <- ifelse(d1[, i]==1, paste0(i, "\n"), "")
d1$all  <- do.call(paste0, d1[, 2:17])

# Write out for Tableau
write.table(d1, "./2013-CRP/out/CRPs by Country wk1.tab", sep="\t", na="", row.names=F)

# Reshape CRP map 2)
d2 <- read.delim("../Desktop/CRPs by Country wk2.txt", sep="\t")

names(d2)[2:16] <- c("1.1 Dryland Systems",
                     "1.2 Humid Tropics",  
                     "1.3 Aquatic Agricultural Systems",
                     "2 Policies, Institutions and Markets", "3.1 Wheat",
                     "3.2 Maize", "3.3 GRiSP",  "3.4 Roots, Tubers and Bananas",
                     "3.5 Grain Legumes", "3.6 Dryland Cereals",
                     "3.7 Livestock and Fish", "4 Nutrition and Health",
                     "5 Water, Land and Ecosystems", 
                     "6 Forest, Trees, and Agroforestry",
                     "7 Climate Change, Ag. and Food Security")   

# Reorder CRP columns
t <- names(d2)[2:16]
t <- t[order(t)]
d2 <- d2[, c("Country", t)]

# Add count
d2[, 9] <- 0L
d2$count <- rowSums(d2[, 2:16], na.rm=T)

# Write out for MSExcel
write.table(d2, "./2013-CRP/out/CRPs by Country wk2 (table).tab", sep="\t", na="", row.names=F)

# Concat
for (i in names(d2)[2:16]) d2[, i] <- ifelse(d2[, i]==1, paste0(i, "\n"), "")
d2$all  <- do.call(paste0, d2[, 2:16])
d2$all <- str_replace_all(d2$all, "NA", "")

# Write out for Tableau
write.table(d2, "./2013-CRP/out/CRPs by Country wk2.tab", sep="\t", na="", row.names=F)
