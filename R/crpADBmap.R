#####################################################################################
# Title: Dissolve GAUL Districts and Overlay with CRP Layers
# Date: September 2013
# Project:  HarvestChoice, CRP Mapping
# Author: Bacou, Melanie <mel@mbacou.com>
#####################################################################################

setwd("/home/projects")
#setwd("~/Google Drive")

library(foreign)
library(data.table)
library(rgdal)
library(rgeos)
library(maptools)
library(stringr)

# Load image
load("./2013-CRP/temp/crpADBmap.RData")

# We clearly need flexible approaches to deal with different CRPs:
# CRP 1.1: intersect all maps with adm-0 (and clean up)
# CRP 1.2: not in prototype. Use maps and intersect all layers with adm-0 (they report site ids)
# CRP 1.3: not in prototype, and no map. website cites Bangladesh, Cambodia, Philippines, Solomon Islands, Zambia.
# CRP 2: use DG spreadsheet
# CRP 3.1: not in prototype, we only have wheat ME maps. Use project locations from their website
# CRP 3.2: use prototype with country field (also with DG)
# CRP 3.3: use maps of GRISP partners (country field)
# CRP 3.4: use CIAT spreadsheet (country field)
# CRP 3.5: only very generic on their website, see table in notes
# CRP 3.6: in prototype (country field) (also with DG)
# CRP 3.7: in prototype (country field) 
# CRP 4: use map as-is
# CRP 5: use activity points + El Savador, Honduras, Guatemala, Nicaragua, or word count from prototype (country field)
# CRP 6: not in prototype, intersect the 6 maps with adm-0
# CRP 7: ask CIAT to provide a table or intersect the 3 layers with adm-0 (no country in prototype) from blogs, 2 layers have country names to be factored in plus 11 CCAFS countries in WA
# AfSIS: Use AfSIS layer (country field)


# Load GAUL adm-0 for intersecting (it's on Kanga)
# writeOGR(g, dsn, "test", driver="MSSQLSpatial") 
dsn <- "MSSQL:server=72.167.202.217;database=gaul_2013;uid=***;pwd=***"
ogrListLayers(dsn) 
g <- readOGR(dsn, "g13_12_adm0")

# Check
plot(g[g$ADM0_NAME=="Ethiopia",])

# Dissolve multi-feature countries
g@polygons <- lapply(g@polygons, checkPolygonsHoles)
g0 <- unionSpatialPolygons(g, ID=g$ADM0_CODE)

# Merge back all attributes from [g] into [g0]
g <- data.table(g@data)
setkey(g, ADM0_CODE)
g <- unique(g)
g <- g[J(getSpPPolygonsIDSlots(g0))]
g0 <- SpatialPolygonsDataFrame(g0, data.frame(g), match.ID=FALSE)

# Check
plot(g0[g0$ADM0_NAME=="Ethiopia",])

# Make meaningful polygon IDs
g0 <- spChFIDs(g0, as.character(g$ADM0_CODE))

# Write out for reuse
writeOGR(g0, "./2013-CRP/maps/admin", "G2013_2012_0", driver="ESRI Shapefile")


## Dissolve multi-feature provinces (for later use)
g1 <- readOGR(dsn, "g13_12_adm1")
# Check
plot(g1[g1$ADM0_NAME=="Ethiopia",])

g1@polygons <- lapply(g1@polygons, checkPolygonsHoles)
g10 <- unionSpatialPolygons(g1, ID=g1$ADM1_CODE)

# Merge back all attributes from [g1] into [g10]
g1 <- data.table(g1@data)
setkey(g1, ADM1_CODE)
g1 <- unique(g1)
g1 <- g1[J(getSpPPolygonsIDSlots(g10))]
g10 <- SpatialPolygonsDataFrame(g10, data.frame(g1), match.ID=FALSE)

# Make meaningful polygon IDs
g10 <- spChFIDs(g10, as.character(g1$ADM1_CODE))

# Write out for reuse
writeOGR(g10, "./2013-CRP/maps/admin", "G2013_2012_1", driver="ESRI Shapefile")


## Dissolve multi-feature districts (for later use)
# g2 <- readOGR(dsn, "g13_12_adm2") => reading from Kanga is too slow
g2 <- readOGR("../Maps/admin", "G2013_2012_2")

# Check
plot(g2[g2$ADM0_NAME=="Ethiopia",])
g2@polygons <- lapply(g2@polygons, checkPolygonsHoles)

# Next statement doesn't run on 8GB (breaking it by country and recombine)
g20 <- lapply(unique(g2@data$ADM0_CODE), function(x)
      unionSpatialPolygons(g2[g2$ADM0_CODE==x,], ID=g2@data[g2$ADM0_CODE==x, "ADM2_CODE"])
)

# Merge back all attributes from [g2] into [g20]
g2 <- data.table(g2@data)
setkey(g2, ADM2_CODE)
g2 <- unique(g2)
g2 <- g2[J(as.integer(unlist(sapply(g20, getSpPPolygonsIDSlots))))]

names(g20) <- as.character(unique(g2$ADM0_CODE))
g20 <- lapply(names(g20), function(x)
      SpatialPolygonsDataFrame(g20[[x]], data.frame(g2[ADM0_CODE==as.integer(x)]), match.ID=FALSE))

# Make unique polygon IDs (or rbind() will complain)
names(g20) <- as.character(unique(g2$ADM0_CODE))
for (x in names(g20)) g20[[x]] <- spChFIDs(g20[[x]], g2[ADM0_CODE==as.integer(x), as.character(ADM2_CODE)])

g20 <- do.call(rbind, g20)
    
# Write out for reuse
writeOGR(g20, "./2013-CRP/maps/admin", "G2013_2012_2", driver="ESRI Shapefile")

# Test performance of cleaned layer (e.g on an intersection)
t <- readOGR("./2013-CRP/maps/AES_Africa", "FarmingSystem")
system.time(t1 <- over(g2, t))
#   user  system elapsed 
#  19.73    0.12   19.86 

system.time(t2 <- over(g20, t))
#  user  system elapsed 
#  19.06    0.17   19.25 

t1 <- g2@data[t1, "ADM2_CODE"]
t2 <- g20@data[t2, "ADM2_CODE"]
# => seems 99% consistent too



## Start CRP mapping
g <- g0; rm(g0)

## Generic overlay function (att is a vector of CRP attribute names we want to keep)
gaulOverlay <- function(x, att) {
  tmp <- over(x, g)
  tmp <- data.table(featureID=row.names(x), g@data[tmp, c("ADM0_CODE", "ADM0_NAME")])
  tmp[, att] <- x@data[, att]
  return(tmp)      
}

## CRP 1.1
# CRP 1.1: intersect all maps with adm-0 (and clean up)

# Load available maps
f <- list.files("./2013-CRP/maps/CRP 1.1", glob2rx("*.shp"), recursive=TRUE)
l <- data.frame(dir=dirname(f), base=str_replace(basename(f), ".shp", ""), stringsAsFactors=F)
crp11 <- lapply(1:dim(l)[1], function(i) readOGR(paste0("./2013-CRP/maps/CRP 1.1/", l[i, "dir"]), l[i, "base"]))

# Visual check
plot(crp11[[1]], col="red")
plot(g, col="#cccccc20", add=TRUE)

# Reproject all CRP layers to match GAUL
crp11[[4]]@proj4string <- crp11[[1]]@proj4string
crp11 <- lapply(crp11, spTransform, g@proj4string)

# [[1]] shows action and satellite sites
# [[2]] shows river basins, but no name
# [[3]] shows areas in Egypt
# [[4]] shows STR domains

out <- lapply(crp11[1:3], gaulOverlay, "Id")
out[[1]]$source <- l[1, "base"]
out[[2]]$source <- l[2, "base"]
out[[3]]$source <- l[3, "base"]
out <- do.call(rbind, out)
out$program <- "CRP 1.1"
out[, Id := NULL]

crp11$out <- out


## CRP 1.2
# CRP 1.2: not in prototype. Use maps and intersect all layers with adm-0 (they report site ids)

# Load available maps
f <- list.files("./2013-CRP/maps/CRP 1.2", glob2rx("*.shp"), recursive=TRUE)
l <- data.frame(dir=dirname(f), base=str_replace(basename(f), ".shp", ""), stringsAsFactors=F)

# we don't want all the layers, only keep 2
l <- l[8:9,]

# Load
crp12 <- lapply(1:dim(l)[1],
    function(i) readOGR(paste0("./2013-CRP/maps/CRP 1.2/", l[i, "dir"]), l[i, "base"]))

# Reproject all CRP layers to match GAUL
crp12 <- lapply(crp12, spTransform, g@proj4string)

# Visual check
plot(crp12[[1]], col="red")
plot(g, col="#cccccc20", add=TRUE)

# Attributes we can keep are SITE_ID and Name
out.1 <- gaulOverlay(crp12[[1]], "SITE_ID")
out.2 <- gaulOverlay(crp12[[2]], "Name")
setnames(out.1, 4, "title")
setnames(out.2, 4, "title")
out.1[, title := as.character(title)]
out.2[, title := as.character(title)]
out.1$source <- l[1, "base"]
out.2$source <- l[2, "base"]
crp12$out <- rbind(out.1, out.2)
crp12$out$program <- "CRP 1.2"


## CRP 1.3
# CRP 1.3: not in prototype, and no map. Extract countries from proposal doc.
# From their website they mention:

cr <- c("Bangladesh", "Cambodia", "Philippines", "Solomon Islands", "Zambia")
title <- c("Khulna Hub", "Tonle Sap Hub", "Visayas-Mindanao Hub", "Malaita Hub", "Western Province")
description <- c("Aquaculture (fish and shrimp), High value horticulture (vegetables and fruit), Alternative field crops (maize, sunflowers)",
    "Strengthening the management of fisheries and other common-property resources in order to enhance the natural productivity and resilience of these systems so that sustained, equitable benefits improve livelihoods of AAS-dependent poor people.",
    "The area shows potential for expanding aquaculture production, and there are emerging markets for AAS products due to expansion of tourism.",
    "The AAS Program will pursue action research with partners, including farmers, to address agricultural and fisheries management and development opportunities identified by rural Malaitans. Improved technologies and approaches will increase the opportunity for people to manage resources more effectively and to take advantage of emerging markets for horticultural, fish, and livestock products.  Apart from marine capture fisheries in coastal communities, opportunities will also be explored for integrated aquatic agricultural systems based around freshwater systems.",
    "There is a high potential to produce high value agricultural products including rice, livestock and fish products. The market demands for these products is very high and is projected to increase further in Zambia and neighboring countries. The prominent role of women as household heads, though marginalized and poorly targeted. Many farmers are willing to innovate and integrate different farming practices, but their efforts are not well networked and connected to existing infrastructure. There is also a strong presence of traditional leadership.")
    
crp13 <- list()
crp13$out <- data.table(
    featureID=1:5,
    ADM0_CODE=NA, ADM0_NAME=cr,
    program="CRP 1.3",
    source="http://aas.cgiar.org/",
    title=title,
    description=description)



## CRP 2
# CRP 2: use DG spreadsheet
crp2 <- list()
crp2[[1]] <- fread("./2013-CRP/maps/CRP 2/IFPRI_CRP2 geocoding_wk1.csv")
crp2[[2]] <- fread("./2013-CRP/maps/CRP 2/IFPRI_CRP2 geocoding_wk2.csv")

# Which activities in [2] are not in [1] if any?
crp2[[2]][!`Activity ID` %in% unique(crp2[[1]]$`Activity ID`)]
# seems none, so we can use country from crp2[[1]] and intersect XY points with GAUL
crp2[[3]] <- readOGR("./2013-CRP/maps/CRP 2", "IFPRI_CRP2 geocoding_wk1")

# Reproject layer to match GAUL
crp2[[3]] <- spTransform(crp2[[3]], g@proj4string)

# Intersect with GAUL
out <- over(crp2[[3]], g)[, c("ADM0_CODE", "ADM0_NAME")]
out <- cbind(out, crp2[[3]]@data[, names(crp2[[3]])[c(1:4,11,12)]])
out <- data.table(out)
setnames(out, 3:7, c("activityid", "title", "theme", "source", "precision"))
crp2$out <- out


## CRP 3.1
# CRP 3.1: not in prototype, we only have wheat ME maps. Use project locations from their website.
crp31 <- list()
crp31[[1]] <- fread("./2013-CRP/maps/CRP 3.1/CRP31fromWeb.csv")
crp31$out <- data.table(
    featureID=1:11,
    ADM0_CODE=NA,
    ADM0_NAME=crp31[[1]]$Country,
    program="CRP 3.1",
    source="http://wheat.org/where-we-work/wheat-in-the-world",
    title=crp31[[1]]$Activity,
    description=NA)


## CRP 3.2
# CRP 3.2: use prototype with country field (also with DG)
crp32 <- list()
caadp <- read.delim("./2013-CRP/data/CRP Activities from CAADP-CGIAR.tsv")
caadp <- data.table(caadp)
crp32[[1]] <- caadp[Program=="CRP 3.2"]

out <- crp32[[1]][, list(
        country=Countries,
        program="CRP 3.2",
        theme=Theme,
        title=Title,
        source="CRP Proposal")]

out <- out[country!=""]
out[, title := str_trim(title)]
out[, activityid := substr(title, 1, 3)]
out[, featureid := NA]
out[, description := NA]

# Normalize country field
tmp <- str_split(out$country, ", ")
tmp <- lapply(1:14, function(x) data.table(tmp[[x]], out[x]))
out <- do.call(rbind, tmp)
out[, country := NULL]
setnames(out, "V1", "country")

# Merge in ADM0_CODE and ADM0_NAME
out[!country %in% unique(g@data[, "ADM0_NAME"]), country]
# [1] "Benin Republic" "Benin Republic" "Benin Republic" "Benin Republic"
out[country=="Benin Republic", country := "Benin"]
tmp <- data.table(g@data)
setkey(tmp, ADM0_NAME)
setkey(out, country)
out[, "ADM0_CODE"] <- tmp[out][, ADM0_CODE]
setnames(out, "country", "ADM0_NAME")
out[, precision := "adm-0, unspecified"]
crp32$out <- out


## CRP 3.3
# CRP 3.3: use maps of GRISP partners (country field)
crp33 <- list()
crp33[[1]] <- fread("2013-CRP/maps/CRP 3.3/GRiSP Partners.tsv")
out <- data.table(
    program="CRP 3.3",
    ADM0_NAME=crp33[[1]]$Country,
    precision="adm0, partner location",
    source="List of GRiSP partners",
    title=NA,
    description=NA,
    theme=NA,
    featureid=NA,
    activityid=1:79)

# Merge in ADM0_CODE
out[!ADM0_NAME %in% unique(g@data[, "ADM0_NAME"]), ADM0_NAME]
# [1] "Tanzania" "Iran"     "Oregon"   "Vietnam"  "Tanzania" "Lao PDR"  "Lao PDR" 
# [8] "Lao PDR"
out[ADM0_NAME=="Tanzania", ADM0_NAME := "United Republic of Tanzania"]
out[ADM0_NAME=="Iran", ADM0_NAME := "Iran  (Islamic Republic of)"]
out[ADM0_NAME=="Oregon", ADM0_NAME := "United States of America"]
out[ADM0_NAME=="Vietnam", ADM0_NAME := "Viet Nam"]
out[ADM0_NAME=="Lao PDR", ADM0_NAME := "Lao People's Democratic Republic"]
setkey(tmp, ADM0_NAME)
setkey(out, ADM0_NAME)
out[, "ADM0_CODE"] <- tmp[out][, ADM0_CODE]
crp33$out <- out


# CRP 3.4
# CRP 3.4: use CIAT spreadsheet (country field)




# CRP 3.5: only very generic on their website, see table in notes
crp35 <- list()
crp35[[1]] <- fread("./2013-CRP/maps/CRP 3.5/CRP35fromWeb.csv")
out <- data.table(
    program="CRP 3.5",
    ADM0_NAME=crp35[[1]]$Country,
    precision="adm0, activity location",
    source="http://grainlegumes.cgiar.org/",
    title=crp35[[1]]$Title,
    description=NA,
    theme=NA,
    featureid=NA,
    activityid=1:11)

out[!ADM0_NAME %in% unique(g@data[, "ADM0_NAME"]), ADM0_NAME]
# [1] "East Africa" "East Africa"
out[ADM0_NAME=="East Africa", ADM0_NAME := "Ethiopia"]
setkey(tmp, ADM0_NAME)
setkey(out, ADM0_NAME)
out[, "ADM0_CODE"] <- tmp[out][, ADM0_CODE]
crp35$out <- out


# CRP 3.6
# CRP 3.6: in prototype (country field) (also with DG)
crp36 <- list()
crp36[[1]] <- caadp[Program=="CRP 3.6"]

out <- crp36[[1]][, list(
        country=Countries,
        program="CRP 3.6",
        theme=Theme,
        title=Title,
        source="CRP Proposal")]

out <- out[country!=""]
out[, title := str_trim(title)]
out[, activityid := substr(title, 1, 3)]
out[, featureid := NA]
out[, description := NA]

# Normalize country field
tmp <- str_split(out$country, ", ")
tmp <- lapply(1:94, function(x) data.table(tmp[[x]], out[x]))
out <- do.call(rbind, tmp)
out[, country := NULL]
setnames(out, "V1", "ADM0_NAME")

# Merge in ADM0_CODE and ADM0_NAME
out[!ADM0_NAME %in% unique(g@data[, "ADM0_NAME"]), unique(ADM0_NAME)]
#[1] "Afganistan"             "Iran"                   "Kazakstan"             
#[4] "Libyan Arab Jamahiriya" "Tanzania"  
out[ADM0_NAME=="Tanzania", ADM0_NAME := "United Republic of Tanzania"]
out[ADM0_NAME=="Iran", ADM0_NAME := "Iran  (Islamic Republic of)"]
out[ADM0_NAME=="Afganistan", ADM0_NAME := "Afghanistan"]
out[ADM0_NAME=="Kazakstan", ADM0_NAME := "Kazakhstan"]
out[ADM0_NAME=="Libyan Arab Jamahiriya", ADM0_NAME := "Libya"]

tmp <- data.table(g@data)
setkey(tmp, ADM0_NAME)
setkey(out, ADM0_NAME)
out[, "ADM0_CODE"] <- tmp[out][, ADM0_CODE]
out[, precision := "adm-0, unspecified"]
crp36$out <- out


# CRP 3.7
# CRP 3.7: in prototype (country field)
crp37 <- list()
crp37[[1]] <- caadp[Program=="CRP 3.7"]

out <- crp37[[1]][, list(
        country=Countries,
        program="CRP 3.7",
        theme=Theme,
        title=Title,
        source="CRP Proposal")]

out <- out[country!=""]
out[, title := str_trim(title)]
out[, activityid := substr(title, 1, 3)]
out[, featureid := NA]
out[, description := NA]

# Normalize country field
tmp <- str_split(out$country, ", ")
tmp <- lapply(1:90, function(x) data.table(tmp[[x]], out[x]))
out <- do.call(rbind, tmp)
out[, country := NULL]
setnames(out, "V1", "ADM0_NAME")

# Merge in ADM0_CODE and ADM0_NAME
out[!ADM0_NAME %in% unique(g@data[, "ADM0_NAME"]), unique(ADM0_NAME)]
#[1] "Tanzania" "Vietnam" 
out[ADM0_NAME=="Tanzania", ADM0_NAME := "United Republic of Tanzania"]
out[ADM0_NAME=="Vietnam", ADM0_NAME := "Viet Nam"]

tmp <- data.table(g@data)
setkey(tmp, ADM0_NAME)
setkey(out, ADM0_NAME)
out[, "ADM0_CODE"] <- tmp[out][, ADM0_CODE]
out[, precision := "adm-0, unspecified"]
crp37$out <- out


# CRP 4
# CRP 4: use map as-is
crp4 <- list()
crp4[[1]] <- readOGR("./2013-CRP/maps/CRP 4", "CRP4_A4NH_Projects")
# Note that [Name] includes country name, so no need to intersect.



# CRP 5: use activity points + El Savador, Honduras, Guatemala, Nicaragua, or word count from prototype (country field)
# CRP 6: not in prototype, intersect the 6 maps with adm-0
# CRP 7: ask CIAT to provide a table or intersect the 3 layers with adm-0 (no country in prototype) from blogs, 2 layers have country names to be factored in plus 11 CCAFS countries in WA
# AfSIS: Use AfSIS layer (country field)






# Save all
save.image(file="./2013-CRP/temp/crpADBmap.RData")

