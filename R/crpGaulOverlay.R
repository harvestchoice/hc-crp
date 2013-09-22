#####################################################################################
# Title: Dissolve GAUL Districts and Overlay with CRP Layers
# Date: September 2013
# Project:  HarvestChoice, CRP Mapping
# Author: Bacou, Melanie <mel@mbacou.com>
#####################################################################################

setwd("/home/projects")

library(foreign)
library(data.table)
library(rgdal)
library(rgeos)
library(maptools)
library(stringr)

# Load GAUL 2008 (release 2009) adm-2
g <- readOGR("../maps/admin", "G2013_2012_2")
# Only keep Ethiopia to test
g <- g[g$ADM0_NAME=="Ethiopia",]

# Dissolve multi-feature districts
g.merged <- unionSpatialPolygons(g, ID=g$ADM2_CODE)

# Merge back all attributes from [g] into [g.merged]
g <- data.table(g@data)
setkey(g, ADM2_CODE)
g <- unique(g)
g <- g[J(getSpPPolygonsIDSlots(g.merged))]
g.merged <- SpatialPolygonsDataFrame(g.merged, data.frame(g), match.ID=FALSE)


# Load all CRP layers into a list
f <- list.files("./maps", glob2rx("*.shp"), recursive=TRUE)
l <- data.frame(dir=dirname(f), base=str_replace(basename(f), ".shp", ""), stringsAsFactors=F)
f <- lapply(1:dim(l)[1], function(i) readOGR(paste0("./maps/", l[i, "dir"]), l[i, "base"]))


# Make sure coordinate systems are identical before overlaying
# If they don't match then reproject the layers
sapply(f, slot, "proj4string")
# [[1]]
# CRS arguments:
#     +proj=longlat +a=6378137 +b=6378137 +no_defs

# If no projection is available, then assume same as others or best guess, e.g.
f[[4]]@proj4string <- f[[1]]@proj4string

g.merged@proj4string
# CRS arguments:
#     +proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0

# Reproject all CRP layers to match GAUL
f <- lapply(f, spTransform, g.merged@proj4string)

# Define generic overlay function (att is a vector of CRP attributes we want to keep)
# e.g. att <- c("Title", "Description", "Resolution", etc..)
gaulOverlay <- function(x, att) {
  tmp <- over(x, g.merged)
  tmp <- data.table(featureID=row.names(x),
      g.merged@data[tmp, c("ADM0_CODE", "ADM0_NAME", "ADM1_CODE", "ADM1_NAME", "ADM2_CODE", "ADM2_NAME")])
  tmp[, att] <- x@data[, att]
  return(tmp)       
}

# Overlay CRP layer by CRP layer
out <- lapply(f, gaulOverlay, "AREA")

# Combine all
out <- do.call(rbind, out)


# Visual check
p <- plot(g.merged[g.merged$ADM2_CODE %in% out[[1]]$ADM2_CODE,], col="cadetblue2")
plot(f[[1]][out[[1]]$featureID,], col="#D9D9D920", add=TRUE)

# Or check interactively through Github's new geojson feature
writeOGR(g.merged[g.merged$ADM2_CODE %in% out[[1]]$ADM2_CODE,],
    dsn="./out/test.geojson", layer="lyr1", driver="GeoJSON")
writeOGR(f[[1]][out[[1]]$featureID,],
    dsn="./out/test.geojson", layer="lyr2", driver="GeoJSON")
# View on github => https://github.com/mbacou/config/blob/master/test.geojson
# (only showing Ethiopia districts)

