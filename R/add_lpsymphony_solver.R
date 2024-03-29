#' @include Solver-proto.R
NULL

#' Add a SYMPHONY solver with \pkg{lpsymphony}
#'
#' Specify that the *SYMPHONY* software should be used to solve a
#' project prioritization [problem()] using the \pkg{lpsymphony}
#' package. This function can also be used to customize the behavior of the
#' solver. It requires the \pkg{lpsymphony} package.
#'
#' @inheritParams add_gurobi_solver
#'
#' @details [*SYMPHONY*](https://github.com/coin-or/SYMPHONY) is an
#'   open-source integer programming solver that is part of the Computational
#'   Infrastructure for Operations Research (COIN-OR) project, an initiative
#'   to promote development of open-source tools for operations research (a
#'   field that includes linear programming). The \pkg{lpsymphony} package is
#'   distributed through
#'   [Bioconductor](https://doi.org/doi:10.18129/B9.bioc.lpsymphony).
#'   This functionality is provided because the \pkg{lpsymphony} package may
#'   be easier to install to install on Windows and Mac OSX systems than the
#'   \pkg{Rsymphony} package.
#'
#' @inherit add_gurobi_solver seealso return
#'
#' @seealso [solvers].
#'
#' @examples
#' \dontrun{
#' # load data
#' data(sim_projects, sim_features, sim_actions)
#'
#' # build problem with lpsymphony solver
#' p <- problem(sim_projects, sim_actions, sim_features,
#'              "name", "success", "name", "cost", "name") %>%
#'      add_max_richness_objective(budget = 200) %>%
#'      add_binary_decisions() %>%
#'      add_lpsymphony_solver()
#'
#' # print problem
#' print(p)
#'
#' # solve problem
#' s <- solve(p)
#'
#' # print solution
#' print(s)
#'
#' # plot solution
#' plot(p, s)
#' }
#' @name add_lsymphony_solver
NULL

#' @export
#' @rdname Solver-class
methods::setClass("LpsymphonySolver", contains = "Solver")

#' @rdname add_lsymphony_solver
#' @export
add_lpsymphony_solver <- function(x, gap = 0, time_limit = .Machine$integer.max,
                                  first_feasible = FALSE, verbose = TRUE) {
  # assert that arguments are valid
  assertthat::assert_that(inherits(x, "ProjectProblem"),
                          isTRUE(all(is.finite(gap))),
                          assertthat::is.number(gap),
                          isTRUE(gap >= 0), isTRUE(all(is.finite(time_limit))),
                          assertthat::is.number(time_limit),
                          assertthat::is.count(time_limit) || isTRUE(time_limit
                            == -1),
                          assertthat::is.flag(verbose),
                          assertthat::is.flag(first_feasible),
                          requireNamespace("lpsymphony", quietly = TRUE))
  # throw warning about bug in lpsymphony
  if (utils::packageVersion("lpsymphony") <= as.package_version("1.4.1"))
    warning(paste0("The solution may be incorrect due to a bug in ",
                   "lpsymphony. Please verify that it is correct, ",
                   "or use a different solver to generate solutions."))
  # add solver
  x$add_solver(pproto(
    "LpsymphonySolver",
    Solver,
    name = "Lpsymphony",
    parameters = parameters(
      numeric_parameter("gap", gap, lower_limit = 0),
      integer_parameter("time_limit", time_limit, lower_limit = -1,
                        upper_limit = .Machine$integer.max),
      binary_parameter("first_feasible", as.numeric(first_feasible)),
      binary_parameter("verbose", verbose)),
    solve = function(self, x) {
      assertthat::assert_that(identical(x$pwlobj(), list()),
        msg = "gurobi solver is required to solve problems with this objective")
      model <- list(
        obj = x$obj(),
        mat = as.matrix(x$A()),
        dir = x$sense(),
        rhs = x$rhs(),
        types = x$vtype(),
        bounds = list(lower = list(ind = seq_along(x$lb()), val = x$lb()),
                      upper = list(ind = seq_along(x$ub()), val = x$ub())),
        max = isTRUE(x$modelsense() == "max"))
      p <- as.list(self$parameters)
      p$verbosity <- -1
      if (!p$verbose)
        p$verbosity <- -2
      p <- p[names(p) != "verbose"]
      names(p)[which(names(p) == "gap")] <- "gap_limit"
      model$dir <- replace(model$dir, model$dir == "=", "==")
      model$types <- replace(model$types, model$types == "S", "C")
      p$first_feasible <- as.logical(p$first_feasible)
      rt <- system.time({
        x <- do.call(lpsymphony::lpsymphony_solve_LP, append(model, p))
      })[[3]]
      # convert status from integer code to character description
      x$status <- symphony_status(x$status)
      # manually throw infeasible solution if it contains only zeros,
      # this is because during presolve SYMHPONY will incorrectly return
      # a solution with no funded actions when the problem is infeasible
      if (max(x$solution) < 1e-10)
        return(NULL)
      # check if no solution found
      if (is.null(x$solution) ||
          (x$status %in% c("TM_NO_SOLUTION", "PREP_NO_SOLUTION")))
        return(NULL)
      list(list(x = x$solution, objective = x$objval,
                status = as.character(x$status),
                runtime = rt))
    }))
}
