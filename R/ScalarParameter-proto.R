#' @include internal.R pproto.R Parameter-proto.R
NULL

#' @export
if (!methods::isClass("ScalarParameter")) methods::setOldClass("ScalarParameter")
NULL

#' Scalar parameter prototype
#'
#' This prototype is used to represent a parameter has a single value.
#' **Only experts should interact directly with this prototype.**
#'
#' @section Fields:
#' \describe{
#'
#' \item{$id}{`character` identifier for parameter.}
#'
#' \item{$name}{`character` name of parameter.}
#'
#' \item{$value}{`numeric` scalar value.}
#'
#' \item{$default}{`numeric` scalar default value.}
#'
#' \item{$class}{`character` name of the class that `$value` should
#'   inherit from (e.g. `integer`).}
#'
#' \item{$lower_limit}{`numeric` scalar value that is the minimum value
#'   that `$value` is permitted to be.}
#'
#' \item{$upper_limit}{`numeric` scalar value that is the maximum value
#'   that `$value` is permitted to be.}
#'
#' \item{$widget}{`function` used to construct a
#'                [shiny::shiny()] interface for modifying values.}
#' }
#'
#' @section Usage:
#'
#' `x$print()`
#'
#' `x$show()`
#'
#' `x$validate(x)`
#'
#' `x$get()`
#'
#' `x$set(x)`
#'
#' `x$reset()`
#'
#' `x$render(...)`
#'
#' @section Arguments:
#'
#' \describe{
#'
#' \item{x}{object used to set a new parameter value.}
#'
#' \item{...}{arguments passed to `$widget`.}
#'
#'  }
#'
#' @section Details:
#' \describe{
#'
#' \item{print}{print the object.}
#'
#' \item{show}{show the object.}
#'
#' \item{validate}{check if a proposed new set of parameters are valid.}
#'
#' \item{get}{extract the parameter value.}
#'
#' \item{set}{update the parameter value.}
#'
#' \item{reset}{update the parameter value to be the default value.}
#'
#' \item{render}{create a [shiny::shiny()] widget to modify
#'               parameter values.}
#'
#' }
#'
#' @name ScalarParameter-class
#'
#' @seealso [Parameter-class], [ArrayParameter-class].
#'
#' @aliases ScalarParameter
NULL

#' @export
ScalarParameter <- pproto(
  "ScalarParameter",
  Parameter,
  upper_limit = numeric(0),
  lower_limit = numeric(0),
  repr = function(self) {
    paste0(self$name, " (", self$value, ")")
  },
  validate = function(self, x) {
    invisible(assertthat::see_if(
      inherits(x, self$class),
      isTRUE(x >= self$lower_limit),
      isTRUE(x <= self$upper_limit),
      is.finite(x)
    ))
  },
  get = function(self) {
    self$value
  },
  set = function(self, x) {
    check_that(self$validate(x))
    self$value <- x
  },
  render = function(self, ...) {
    # get all possible arguments
    args <- list(inputId = self$id, label = self$name, value = self$value,
      min = self$lower_limit, max = self$upper_limit)
    # check that widget dependency installed
    pkg <- strsplit(self$widget, "::")[[1]][[1]]
    if (!requireNamespace(pkg, quietly = TRUE))
      stop(paste0("the \"", pkg, "\" R package must be installed to render",
                  " this parameter."))
    # extract function
    f <- do.call(getFromNamespace,
      as.list(rev(strsplit(self$widget, "::")[[1]])))
    # subset to include only valid arguments
    args <- args[intersect(names(args), names(as.list(args(f))))]
    do.call(f, append(args, list(...)))
  })
