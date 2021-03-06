#' ---
#' title: "Spatial tools"
#' author: "Arezoo Rafieeinasab & Aubrey Dugger"
#' date: "`r Sys.Date()`"
#' output: rmarkdown::html_vignette
#' vignette: >
#'   %\VignetteIndexEntry{Vignette Title}
#'   %\VignetteEngine{knitr::rmarkdown}
#'   %\VignetteEncoding{UTF-8}
#' ---
#' For model analysis and evaluation, we often need to create spatial maps, aggregate over spatial units, or produce georeferenced rasters and shapefiles. We have adapted existing functionality from spatial libraries such as SP, RGDAL, RGEOS, and Raster into rwrfhydro. In this vignette, we describe some of these spatial functions and give examples of their application to model evaluation.
#' 
#' ## List of the available functions
#' - GetProj
#' - GetGeogridSpatialInfo
#' - ExportGeogrid
#' - GetGeogridIndex
#' - GetTimeZone
#' - GetRfc
#' - GetPoly
#' - PolygonToRaster
#' 
#' ## General Info
#' Load the rwrfhydro package.
#' 
## ------------------------------------------------------------------------
library(rwrfhydro)
library(rgdal) ## on some linux machines this appears needed
options(warn=1)

#' 
#' Set a data path to the Fourmile Creek test case.
#' 
## ------------------------------------------------------------------------
fcPath <- '~/wrfHydroTestCases/Fourmile_Creek_testcase_v2.0'

#' 
#' The geogrid file is the main coarse-grid (LSM) parameter file and contains base geographic information on the model domain such as the geographic coordinate system and latitude/longitude coordinates. We use this file frequently. Set a path to geogrid file.
#' 
## ------------------------------------------------------------------------
geoFile <- paste0(fcPath,'/DOMAIN/geo_em_d01.Fourmile1km.nlcd11.nc')

#' 
#' 
#' ## GetProj
#' 
#' To be able to use spatial tools in R, we need to know the projection information for the domain. All the coarse-resolution (LSM) model input and output files are based on the geogrid domain. `GetProj` will pull projection information from the geogrid file. You will see the specs for the Lambert Conformal Conic projection on the WRF standard sphere.
#' 
## ------------------------------------------------------------------------
proj4 <- GetProj(geoFile)
proj4

#' 
#' ## GetGeogridSpatialInfo
#' 
#' `GetGeogridSpatialInfo` will pull geospatial information about the coarse-resolution (LSM) model domain from the geogrid file.
#' 
## ------------------------------------------------------------------------
geoInfo <- GetGeogridSpatialInfo(geoFile)
geoInfo

#' 
#' 
#' ## ExportGeogrid
#' 
#' If you need to create a georeferenced TIF file from any variable in an LSM-related netcdf file (input or output), then you can use the `ExportGeogrid` function. It takes a NetCDF file and converts the specified variable into a georeferenced TIF file for use in standard GIS tools. You can use `ExportGeogrid` directly on a file that contains lat/lon coordinates or you can use it on a file that does not contain lat/lon coords by providing a separate coordinate file.
#' 
#' Let's export a variable from the geogrid file. You can get a list of all available variables in the `geoFile` using the `ncdump` function in rwrfhydro.
#' 
## ---- eval = FALSE-------------------------------------------------------
## head(ncdump(geoFile))

#' 
#' Now we will create a georeferenced TIF file from the elevation field. The geogrid contains lat/long coordinates, so you only need to provide the address to the file (`geoFile`), the name of the variable (`HGT_M`), and the name of the output file (`geogrid_hgt.tif`).
#' 
## ---- results='hide', message=FALSE, warning=FALSE-----------------------
ExportGeogrid(geoFile,"HGT_M", "geogrid_hgt.tif")

#' 
#' You can now use the geotiff in any standard GIS platform. Here we will just read it into memory as a raster and display it.
#' 
## ----plot1, fig.show = "hold", fig.width = 8, fig.height = 8, out.width='600', out.height='600'----
# Read the newly created tiff file
library(raster)
r <- raster("geogrid_hgt.tif")

# Plot the imported raster from tiff file
plot(r, main = "HGT_M", col=terrain.colors(100))

# Check the raser information and notice that geographic coordinate information has been added.
r

#' 
#' Many of the output files (such as LDASOUT, RESTARTS) do not contain lat/lon coordinates but match the spatial coordinate system of the geogrid input file. In that case, you can provide a supplemental `inCoordFile` which contains the lat/lon information. 
#' 
## ----plot2, fig.width = 8, fig.height = 8, out.width='600', out.height='600'----
file <- paste0(fcPath,"/run.FluxEval/RESTART.2013060100_DOMAIN1")
# ncdump(file) # check if the SOIL_T exist in the file

# Export the 3rd layer of the 4-layer soil temperature variable
ExportGeogrid(file,
             inVar="SOIL_T",
             outFile="20130315_soilm3.tif",
             inCoordFile=geoFile,
             inLyr=3)

# Read the newly created tiff file
r <- raster("20130315_soilm3.tif")

# Plot the imported raster from tiff file
plot(r, main = "Soil Temperature", col=rev(heat.colors(100))) # in raster

# Check the raster information and notice that geographic coordinate information has been added
r

#' 
#' 
#' ## GetGeogridIndex
#' 
#' To be able to use tools such as `GetMultiNcdf` to pull data from gridded output, we need to know the indices (i,j) of the area of interest within the domain. `GetGeogridIndex` calculates cell indices from lat/lon (or other) coordinates. It reads in a set of lat/lon (or other) coordinates and generates a corresponding set of geogrid index pairs. You can assign a projection to the points using the `proj4` argument, which will be used to transform the points to the `geoFile` coordinate system. Check `?GetGeogridIndex` or the Precipitation Evaluation vignette for full usage.
#' 
## ------------------------------------------------------------------------
sg <- data.frame(lon = seq(-105.562, -105.323, length.out = 10), 
                 lat = seq(40.0125, 40.0682, length.out = 10))
GetGeogridIndex(sg, geoFile)

#' 
#' 
#' ## GetTimeZone
#' 
#' Many station observations are reported in local time and need to be converted to UTC time to be comparable with WRF-Hydro inputs and outputs. `GetTimeZone` returns the time zone for any lat/lon coordinates. It simply takes a dataframe containing at least two fields of `latitude` and `longitude` and overlays the `points` with a timezone shapefile (can be downloded from <http://efele.net/maps/tz/world/>). The shapefile is provided in rwrfhydro data and is called `timeZone`.
#' 
## ------------------------------------------------------------------------
# timeZone has been provided by rwrfhydro as a SpatialPolygonDataFrame
class(timeZone)

# Shows the available timezone (TZID column in timeZone@data)
head(timeZone@data)

#' 
#' `GetTimeZone` has three arguments. 
#' 
#' - `points`: A dataframe of the points. The dataframe should contain at least two fields called `latitude` and `longitude`.
#' - `proj4`: Projection of the `points` to be used in transforming the `points` projection to the `timeZone` projection. Default is `+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0` which is the same as the `timezone` projection.
#' - `parallel`: If the number of points is high you can parallelize the process.
#' 
#' `GetTimeZone` will return the `points` dataframe with an added column called `timeZone`. It will return NA if a point is not in any polygon. Now let's generate some points and find their time zone information.
#' 
## ------------------------------------------------------------------------
# Provide a dataframe of 10 points having longitude and latitude as column name.
sg <- data.frame(longitude = seq(-110, -80, length.out = 10),
                 latitude = seq(30, 50, length.out = 10))

# Find the time zone for each point
sg <- GetTimeZone(sg)
sg

#' 
#' ## GetRfc
#' 
#' The US has 13 River Forecast Centers (RFCs) which issue daily river forecasts using hydrologic models based on rainfall, soil characteristics, precipitation forecasts, and several other variables. The RFC boundary shapefile is provided in rwrfhydro data and is called `rfc`.
#' 
## ------------------------------------------------------------------------
class(rfc)

# Shows the available rfc, name of the column is BASIN_ID
head(rfc@data)

#' 
#' `GetRfc` return the RFC name for any point having `latitude` and `longitude`. It takes a dataframe containing at least two fields of `latitude` and `longitude`, overlays the points with the `rfc` SpatialPolygonDataFrame, and return the RFC's BASIN_ID. This function has three arguments:
#' 
#' - `points`: A dataframe of the points. The dataframe should contain at least two fields called "latitude" and "longitude".
#' - `proj4`: Projection of the `points` to be used in transforming the `points` projection to the `rfc` projection. Default is `+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0`.
#' - `parallel`: If the number of points is high you can parallelize the process.
#' 
#' `GetRfc` will return the points dataframe with an added column called `rfc`. It will return NA if the point is not in any polygon.
#' 
## ------------------------------------------------------------------------
# Provide a dataframe of 10 points having longitude and latitude as column name.
sg <- data.frame(longitude = seq(-110, -80, length.out = 10), 
                 latitude = seq(30, 50, length.out = 10))

# Find the rfc for each point
sg <- GetRfc(sg)
sg

#' 
#' ## GetPoly
#' 
#' `GetPoly` is similar to `GetRfc`; it is a wrapper for the function `sp::over`. It takes a dataframe containing at least two fields of `latitude` and `longitude`, overlays the points with a `SpatialPolygonDataFrame`, and returns the requested attribute from the polygon. You could use any available `SpatialPolygon*` loaded into memory or provide the address to the location of a polygon shapefile and it will read the shapefile using the `rgdal::readOGR` function.
#' 
#' Let's get the RFC information from `GetPoly` instead of `GetRfc`. Here we provide the name of the `SpatialPolygon*` and, using the argument `join`, request one of the polygon attributes. For example, here we request the `BASIN_ID`, `RFC_NAME` and `RFC_CITY` attributes. 
#' 
## ------------------------------------------------------------------------
# Provide a dataframe of 10 points having longitude and latitude
sg <- data.frame(longitude = seq(-110, -80, length.out = 10), 
                 latitude = seq(30, 50, length.out = 10))

# Find the ID of RFC for each point
sg <- GetPoly(points = sg, polygon = rfc, join = "BASIN_ID")

# Find the full name of RFC for each point
sg <- GetPoly(points = sg, polygon = rfc, join = "RFC_NAME")

# Find the location/city of RFC for each point
sg <- GetPoly(points = sg, polygon = rfc, join = "RFC_CITY")
sg

#' 
#' Now let's provide the address to a shapefile on the disk as well as the name of the shapefile and perform the same process. We have clipped the `HUC12` shapefile and provided it in the case study as a sample. The northeast portion of the clipped polygon partially covers the Fourmile Creek domain.
#'  
## ------------------------------------------------------------------------
# Provide a dataframe of 10 points within the Fourmile Creek domain having longitude and latitude
sg <- data.frame(longitude = seq(-105.562, -105.323, length.out = 10), 
                 latitude = seq(40.0125, 40.0682, length.out = 10))


# We use `rgdal::readOG` in the GetPoly function and it does not interpret the character/symbol `~`. 
# Therefore, we need to use path.expand to get the full address to the case study location on your system. 
polygonAddress <- paste0(path.expand(fcPath), "/polygons")


# Find the HUC12 for each point
sg <- GetPoly(points = sg,
              polygonAddress = polygonAddress,
              polygonShapeFile = "clipped_huc12",
              join = "HUC12")
sg

#' 
#' ## PolyToRaster
#' 
#' If you want to create an area mask in the coarse-resolution (LSM) model domain, you can use `PolyToRaster`. It first picks up the required geographic information (like `proj4`) from the geogrid file (`geoFile`) and then uses the `raster::rasterize` function to grab the mask or attibute values from the `SpatialPolygonDataFrame`. This function is basically wrapping the `raster::rasterize` function to serve our purpose. Below are a few different ways we can use this function.
#' 
#' Example 1 : 
#' Let's get the RFC ID for each pixel within the Fourmile Creek domain. This is equivalent to rasterizing the `rfc` `SpatialPolygonDataFrame` based on the `BASIN_ID`.
#' 
## ----plot3, fig.width = 8, fig.height = 8, out.width='600', out.height='600'----
r <- PolyToRaster(geoFile = geoFile,
                  useRfc = TRUE,
                  field ="BASIN_ID")

#' 
#' To get the string (RFC ID) associated with the gridded ID value, you can check the attributes.
#' 
## ------------------------------------------------------------------------
r@data@attributes 

#' As the results show, the full domain falls into one RFC (MBRFC). 
#' 
#' 
#' Example 2 : 
#' Rasterize the HUC12 `SpatialPolygonDataFrame` based on the `HUC12` field. The clipped HUC12 shapefile is provided with the test case. You can read the shapefile and plot it as below.
## ----results="hide", plot4, fig.width = 8, fig.height = 8, out.width='600', out.height='600'----
polyg <- rgdal::readOGR(paste0(path.expand(fcPath), "/polygons"), "clipped_huc12")
plot(polyg, main = "Clipped HUC12") ## in raster

#' 
#' Our study domain partially covers a few basins in the northeast portion of this shapefile.
#' 
## ----results="hide", plot5, fig.width = 8, fig.height = 8, out.width='600', out.height='600'----
polygonAddress <- paste0(path.expand(fcPath), "/polygons")
r <- PolyToRaster(geoFile = geoFile,
                  polygonAddress = polygonAddress,
                  polygonShapeFile = "clipped_huc12",
                  field ="HUC12")

#' 
#' To get the `HUC12` actual values:
#' 
## ------------------------------------------------------------------------
r@data@attributes

#' 
#' Example 3: You can create masks over the study domain using PolyToRaster. To create a unified mask over the study domain:
#' 
## ----results="hide", plot6, fig.width = 8, fig.height = 8, out.width='600', out.height='600'----
r <- PolyToRaster(geoFile = geoFile,
                  polygonAddress = polygonAddress,
                  polygonShapeFile = "clipped_huc12",
                  mask =TRUE)

#' 
#' You can also create a separate mask for each subbasin (HUC12 in this case) with the fraction of each grid cell that is covered by each polygon. The fraction covered is estimated by dividing each cell into 100 subcells and determining presence/absence of the polygon in the center of each subcell. 
#' 
## ----results="hide", plot7, fig.width = 8, fig.height = 8, out.width='600', out.height='600'----
r <- PolyToRaster(geoFile = geoFile,
                  polygonAddress = polygonAddress,
                  polygonShapeFile = "clipped_huc12",
                  field = "HUC12",
                  getCover = TRUE)
plot(r) ## in raster

#' 
