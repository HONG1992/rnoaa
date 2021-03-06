#' Get NOAA wind storm tabular data, metadata, or shp files from IBTrACS
#'
#' @name storms
#' @param basin (character) A basin name, one of EP, NA, NI, SA, SI, SP, or WP.
#' @param storm (character) A storm serial number of the form YYYYJJJHTTNNN.
#' See Details.
#' @param year (numeric) One of the years from 1842 to 2014
#' @param overwrite (logical) To overwrite the path to store files in or not,
#' Default: \code{TRUE}
#' @param what (character) One of storm_columns or storm_names.
#' @param type (character) One of points or lines. This gives shp files with
#' points, or with lines.
#' @param x Output from \code{storm_shp}, a path to shp file to read in.
#' @param ... Curl options passed on to \code{\link[crul]{HttpClient}} 
#' (optional)
#'
#' @return A tibble (data.frame)
#'
#' @details International Best Track Archive for Climate Stewardship (IBTrACS)
#'
#' Details for storm serial numbers:
#' \itemize{
#'  \item YYYY is the corresponding year of the first recorded observation of
#'  the storm
#'  \item JJJ is the day of year of the first recorded observation of the storm
#'  \item H is the hemisphere of the storm: N=Northern, S=Southern
#'  \item TT is the absolute value of the rounded latitude of the first
#'  recorded observation of the storm (range 0-90, if basin=SA or SH, then TT
#'  in reality is negative)
#'  \item NNN is the rounded longitude of the first recorded observation of
#'  the storm (range 0-359)
#' }
#'
#' For example: \code{1970143N19091} is a storm in the North Atlantic which
#' started on May 23, 1970 near 19N 91E
#'
#' See \url{http://www.ncdc.noaa.gov/ibtracs/index.php?name=numbering} for more
#'
#' The datasets included in the package \code{\link{storm_names}}, and
#' \code{\link{storm_columns}} may help in using these storm functions.
#'
#'
#' @section File storage:
#' We use \pkg{rappdirs} to store files, see
#' \code{\link[rappdirs]{user_cache_dir}} for how
#' we determine the directory on your machine to save files to, and run
#' \code{rappdirs::user_cache_dir("rnoaa/storms")} to get that directory.
#'
#' @references \url{http://www.ncdc.noaa.gov/ibtracs/index.php?name=wmo-data}
#'
#' @examples \dontrun{
#' # Metadata
#' head( storm_meta() )
#' head( storm_meta("storm_columns") )
#' head( storm_meta("storm_names") )
#'
#' # Tabular data
#' ## Get tabular data for basins, storms, or years
#' storm_data(basin='WP')
#' storm_data(storm='1970143N19091')
#' storm_data(year=1940)
#' storm_data(year=1941)
#' storm_data(year=2010)
#'
#' # shp files
#' ## storm_shp downloads data and gives a path back
#' ## to read in, use storm_shp_read
#' res <- storm_shp(basin='EP')
#' storm_shp_read(res)
#'
#' ## Get shp file for a storm
#' (res2 <- storm_shp(storm='1970143N19091'))
#'
#' ## Plot shp file data, we'll need sp library
#' library('sp')
#'
#' ### for year 1940, points
#' (res3 <- storm_shp(year=1940))
#' res3shp <- storm_shp_read(res3)
#' plot(res3shp)
#'
#' ### for year 1940, lines
#' (res3_lines <- storm_shp(year=1940, type="lines"))
#' res3_linesshp <- storm_shp_read(x=res3_lines)
#' plot(res3_linesshp)
#'
#' ### for year 2010, points
#' (res4 <- storm_shp(year=2010))
#' res4shp <- storm_shp_read(res4)
#' plot(res4shp)
#' }

#' @export
#' @rdname storms
storm_data <- function(basin = NULL, storm = NULL, year = NULL,
                       overwrite = TRUE, ...) {
  calls <- names(sapply(match.call(), deparse))[-1]
  calls_vec <- "path" %in% calls
  if (any(calls_vec)) {
    stop("The parameter path has been removed, see ?storms",
         call. = FALSE)
  }

  path <- file.path(rnoaa_cache_dir(), "storms")
  csvpath <- csv_local(basin, storm, year, path)
  if (!is_storm(x = csvpath)) {
    csvpath <- storm_GET(path, basin, storm, year, overwrite, ...)
  }
  message(sprintf("<path>%s", csvpath), "\n")
  tibble::as_data_frame(read_csv(csvpath))
}

storm_GET <- function(bp, basin, storm, year, overwrite, ...){
  dir.create(local_base(basin, storm, year, bp), showWarnings = FALSE,
             recursive = TRUE)
  fp <- csv_local(basin, storm, year, bp)
  cli <- crul::HttpClient$new(csv_remote(basin, storm, year), opts = list(...))
  res <- suppressWarnings(cli$get(disk = fp))
  res$content
}

filecheck <- function(basin, storm, year){
  tmp <- noaa_compact(list(basin = basin, storm = storm, year = year))
  if (length(tmp) > 1)
    stop("You can only supply one or more of basin, storm, or year",
         call. = FALSE)
  if (length(tmp) == 0) list(all = "Allstorms") else tmp
}

filepath <- function(basin, storm, year){
  tmp <- filecheck(basin, storm, year)
  switch(names(tmp),
         all = 'Allstorms',
         basin = sprintf('basin/Basin.%s', tmp[[1]]),
         storm = sprintf('storm/Storm.%s', tmp[[1]]),
         year = sprintf('year/Year.%s', tmp[[1]])
  )
}

fileext <- function(basin, storm, year){
  tt <- filepath(basin, storm, year)
  if (grepl("Allstorms", tt)) {
    paste0(tt, '.ibtracs_all.v03r10.csv.gz')
  } else {
    paste0(tt, '.ibtracs_all.v03r10.csv')
  }
}

csv_remote <- function(basin, storm, year) {
  file.path(stormurl(), fileext(basin, storm, year))
}
csv_local <- function(basin, storm, year, path) {
  file.path(path, fileext(basin, storm, year))
}

local_base <- function(basin, storm, year, path){
  tt <- filecheck(basin, storm, year)
  if (names(tt) == "all") path else file.path(path, names(tt))
}

is_storm <- function(x) if (file.exists(x)) TRUE else FALSE

stormurl <- function(x = "csv") {
  sprintf('ftp://eclipse.ncdc.noaa.gov/pub/ibtracs/v03r10/all/%s', x)
}
