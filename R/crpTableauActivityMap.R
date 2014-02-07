#####################################################################################
# Title: Prepare CRP Activity Locations for Tableau
# Date: December 2013
# Project:  HarvestChoice, CRP Mapping
# Author: Bacou, Melanie <mel@mbacou.com>
#####################################################################################

#setwd("/home/projects")
setwd("~/Google Drive/2013-CRP")

library(data.table)
library(rgdal)
library(ggmap)
library(reshape2)
memory.limit(4000)

# Load saved workspace
load("./temp/crp2.RData")

# Load GAUL Level 2
g2 <- readOGR("../../Maps/admin", "G2013_2012_2")

# Keep just GAUL attributes (we only need country names)
g2 <- data.table(g2@data)

# Unpack locations by ids for Maria
c2 <- read.csv("./docs/CRP 2/crp2_mappr (1).csv")
c2[, location := str_split(location ,";")]
s <- rep(c2$id, times=sapply(t$location, length))
s <- data.table(id=s, location=unlist(t$location))
write.csv(s, "./docs/CRP 2/crp2_mappr_location.csv", row.names=F, na="")


# Maria prepared a merged version of crp2_mappr.csv
c2 <- readOGR("./maps/CRP 2/crp2_mappr_collapsed.geojson", "OGRGeoJSON")

# Clean up technology terms
tmp <- data.table(c2@data)
tmp[, rn := row.names(c2)]
tmp[, technology := gsub(" technology", "", technology, fixed=T)]
tmp[, technology := gsub("Economic and policy", "Economic and policy analysis", technology, fixed=T)]
tmp[, technology := gsub("Educational", "Education", technology, fixed=T)]
tmp[, technology := gsub("Education policy", "Education", technology, fixed=T)]
tmp[, participating_name := gsub("care", "CARE", participating_name, fixed=T)]
tmp[, participating_name := gsub("NigeriaINRAN", "Nigeria INRAN", participating_name, fixed=T)]
tmp[, technology := gsub("Alternative basic education for nomadic communities", "Livestock", technology, fixed=T)]
tmp[, theme := gsub("Inclusive Governance and Institutions ", "Inclusive Governance and Institutions", theme, fixed=T)]
tmp[, theme := gsub("Linking small producers to markets ", "Linking Small Producers to Markets", theme, fixed=T)]


# Make some donut charts
th <- lapply(unique(tmp$theme), grep, tmp$theme, fixed=T)
names(th) <- unique(tmp$theme)
names(th)[2] <- "Linking Small Producers to Markets"

th <- data.table(theme=names(th), count=sapply(th, length))
th[, fraction := count / sum(count)]
th <- th[order(fraction)]
th[, ymax := cumsum(fraction)]
th[, ymin := c(0, head(ymax, n=-1))]
th[, theme := paste(theme, " (", round(fraction*100), "%)", sep="")]

tech <- strsplit(tmp$technology, "|", fixed=T)
tech <- unlist(tech)
techv <- lapply(unique(tech), grep, tech, fixed=T)
names(techv) <- unique(tech)

techv <- data.table(theme=names(techv), count=sapply(techv, length))
techv[, fraction := count / sum(count)]
techv <- techv[order(fraction)]
techv[, ymax := cumsum(fraction)]
techv[, ymin := c(0, head(ymax, n=-1))]
techv[, theme := paste(theme, " (", round(fraction*100), "%)", sep="")]
techv <- techv[theme=="Food (1%)", theme := "Processing (1%)"]

ggplot(th, aes(fill=theme, ymax=ymax, ymin=ymin, xmax=3, xmin=1), legend="bottom") +
    geom_rect(colour="white") +
    coord_polar(theta="y") +
    xlim(c(0, 3)) +
    scale_fill_manual("Research Themes \n(share of activities)", values=seq(3,50,9)) +
    theme_bw() +
    theme(panel.grid=element_blank(),
        axis.text=element_blank(), axis.ticks=element_blank(),
        panel.border=element_blank(),
        legend.position="bottom", legend.direction="vertical")

ggsave("./maps/CRP 2/crp2_pieth.png", width=6.5, height=6, units="in")

ggplot(techv, aes(fill=theme, ymax=ymax, ymin=ymin, xmax=4, xmin=2)) +
    geom_rect(colour="white") +
    coord_polar(theta="y") +
    xlim(c(0, 4)) +
    scale_fill_manual("Technologies \n(share of activities)", values=sample(seq(3,50,2), 17)) +
    theme_bw() +
    theme(panel.grid=element_blank(),
        axis.text=element_blank(), axis.ticks=element_blank(),
        panel.border=element_blank(),
        legend.position="bottom", legend.direction="vertical")

ggsave("./maps/CRP 2/crp2_pietech.png", width=6.5, height=8, units="in")



# Unpack countries from the list of adm-2 codes
loc <- strsplit(as.character(tmp$location), ";", fixed=T)
names(loc) <- tmp$id
loc <- data.table(id=rep(names(loc), sapply(loc, length)), adm2=unlist(loc))
loc[, adm2 := as.integer(adm2)]
loc[, id := as.integer(id)]
setkey(loc, adm2)
setkey(g2, ADM2_CODE)
loc$ADM0_CODE <- g2[loc][, ADM0_CODE]
loc$ADM0_NAME <- g2[loc][, ADM0_NAME]

unique(loc$ADM0_NAME)
# 52 countries

setkey(tmp, id)
setkey(loc, id)
x <- c(names(loc), names(tmp)[c(2,3,17,22,27,28,32,39)])
loc <- tmp[loc][, x, with=F]

# Combine all by country and activity
setkey(loc, ADM0_CODE, ADM0_NAME, id)
loc <- unique(loc)

# Export to Tableau
write.csv(loc, "./maps/CRP 2/crp2_tableau_act.csv", na="", row.names=F)

# Combine all by country
loc <- loc[, list(
        count=length(id),
        title=paste(title, collapse="|"),
        reporting_org=paste(reporting_org, collapse="|"),
        participating_name=paste(participating_name, collapse="|"),
        theme=paste(theme, collapse="|"),
        technology=paste(technology, collapse="|"),
        budget=sum(budget, na.rm=T)),
    by=list(ADM0_CODE, ADM0_NAME)]

# Unpack technologies for Tableau
tech <- strsplit(loc$technology, "|", fixed=T)
names(tech) <- loc$ADM0_NAME
tech <- data.table(ADM0_NAME=rep(names(tech), sapply(tech, length)), tech=unlist(tech))
setkey(tech, ADM0_NAME)
setkey(loc, ADM0_NAME)
tech <- loc[tech]

tech[, title := str_wrap(title, width=40)]
tech[, reporting_org := gsub("|", " - ", reporting_org, fixed=T)]
tech[, participating_name := gsub("|", " - ", participating_name, fixed=T)]

# Export to Tableau
write.csv(tech, "./maps/CRP 2/crp2_tableau_tech.csv", na="", row.names=F)


# Save workspace
save.image(file="./temp/crp2.RData")

