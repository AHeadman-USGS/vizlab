#' Utilities for building online data visualizations
#'
#' @name vizlab
NULL

### Setting up the viz object ###

#' Coerce viz objects
#'
#' @rdname vizlab
#' @param x object to coerce to viz.
#' @param ... further arguments passed to or from other methods.
#' @export
as.viz <- function(x, ...) UseMethod("as.viz")

#' Convert character (id) to vizlab object
#'
#' @rdname vizlab
#' @export
as.viz.character <- function(x, ...) {
  # get the reading information for this data ID from viz.yaml
  viz <- getContentInfo(x, no.match='stop')
  return(as.viz(viz))
}

#' Convert list into vizlab object
#' @rdname vizlab
#' @export
as.viz.list <- function(x, ...) {
  class(x) <- "viz"
  return(x)
}

#' Recast viz into new vizlab object
#' @rdname vizlab
#' @export
as.viz.viz <- as.viz.list
