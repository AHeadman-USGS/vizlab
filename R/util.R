### Utility functions for use in vizlab ###

#' Check required fields
#'
#' @param x object to check for fields
#' @param required list of fields required
#' @export
checkRequired <- function(x, required) {
  hasAll <- all(required %in% names(x))
  if (!hasAll) {
    stop(x[['id']], " missing at least one of ", paste(required, collapse = ", "))
  }
}

#' Get webapp path
#'
#' @param file path to file being exported
#' @return character vector describing relative path
#' @export
relativePath <- function(file) {
  exportAndPath <- sub(exportLocation(), "", file)
  return(exportAndPath)
}

#' Build context for templating
#'
#' @param viz vizlab object
#' @param dependencies list of dependency ids
#' @return list of context with dependencies injected
buildContext <- function(viz, dependencies) {
  # allow for context to be inline
  data <- viz[["context"]]

  if (is.null(data)) {
    data <- list()
  }
  else if (is.character(data)) {
    data <- readData(data)
  }

  # replace dependencies with contents
  data <- rapply(data, function(x) {
    dep.ids <- x %in% names(dependencies)
    if (any(dep.ids)) {
      x[which(dep.ids)] <- dependencies[x[which(dep.ids)]]
    }
    return(x)
  }, how = "replace", classes = "character")

  return(data)
}

#' Private function to expand dependencies by appropriately publishing
#' or reading
#'
#' @param x item to expand
expandDependencies <- function(x) {
  expanded.dep <- NULL
  expanded.dep <- publish(x)
  if (is.list(expanded.dep) && !is.null(expanded.dep[['reader']])) {
    expanded.dep <- as.reader(expanded.dep)
    expanded.dep <- readData(expanded.dep)
  }
  return(expanded.dep)
}

#' Use mimetype lookup to get reader
#'
#' @importFrom utils modifyList
#' @param mimetype character vector of length one with the mimetype name
#' @return character vector describing the reader to be used
#' @importFrom utils modifyList
#' @export
lookupMimetype <- function(mimetype){
  # add to and replace default mimetypes using the file specified in viz.yaml
  mimetype_list_default <- yaml.load_file(system.file('mimetypes.default.yaml', package="vizlab"))
  mimetype_file_user <- getBlocks('info')[[1]]$mimetypeDictionary[[1]]
  if(length(mimetype_file_user) != 0){
    mimetype_list_user <- yaml.load_file(mimetype_file_user)
  } else {
    mimetype_list_user <- list()
  }
  mimetype_list <- modifyList(mimetype_list_default, mimetype_list_user)

  # match the current mimetype with one in the list to get the correct reader/publisher
  type_match <- which(unlist(lapply(mimetype_list,
                                    FUN=function(mimetype_list, mimetype){
                                      mimetype %in% mimetype_list},
                                    mimetype=mimetype)))
  type_nm <- names(type_match)
  return(type_nm)
}

#' Assemble whisker partials from vizlab package
#'
#' @importFrom tools file_path_sans_ext
#' @return list containing partials available
getPartialLibrary <- function() {
  template.dir <- system.file("templates", package = "vizlab")
  template.files <- dir(template.dir, pattern = "*.mustache")
  template.names <- file_path_sans_ext(template.files)
  partials <- lapply(template.files, function(x, dir) {
    viz <- list(
      location = file.path(dir, x),
      reader = "txt"
    )
    viz <- as.reader(as.viz(viz))
    return(readData(viz))
  }, template.dir)
  names(partials) <- template.names
  return(partials)
}

#' Replace any markdown text with rendered html
#'
#' @importFrom markdown markdownToHTML
#' @param text character vector containing markdown text
handleMarkdown <- function(text) {
  options <- c("skip_html", "skip_style", "skip_images", "escape", "smartypants", "fragment_only")
  extensions <- c("tables", "fenced_code", "strikethrough", "lax_spacing", "superscript", "latex_math")
  html <- markdownToHTML(text = text, options = options, extensions = extensions)
  m <- regexec("^<p>(.*)</p>\\n$", html, perl = TRUE)
  if (length(regmatches(x = html, m = m)[[1]]) > 0) {
    # capture the stuff between paragraph tags (group 1, index 2)
    html <- regmatches(x = html, m = m)[[1]][2]
  }
  return(html)
}

#' Sets up folders so file can be written without warnings
#'
#' @param file file that is about to be written
#' @export
setupFoldersForFile <- function(file) {
  dir <- dirname(file)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
}

#' Grab a random number to break the cache
#'
#' @return random number between 10000 and 10000000
uniqueness <- function() {
  rng <- floor(runif(n = 1, min = 10000, max = 10000000))
  return(rng)
}
