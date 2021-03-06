% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/action_names.R
\name{action_names}
\alias{action_names}
\alias{action_names,ProjectProblem-method}
\title{Action names}
\usage{
action_names(x)

\S4method{action_names}{ProjectProblem}(x)
}
\arguments{
\item{x}{\linkS4class{ProjectProblem}.}
}
\value{
\code{character} action names.
}
\description{
Extract the names of the actions in an object.
}
\examples{
# load data
data(sim_projects, sim_features, sim_actions)

# build problem with default solver
p <- problem(sim_projects, sim_actions, sim_features,
             "name", "success", "name", "cost", "name") \%>\%
     add_max_richness_objective(budget = 200) \%>\%
     add_binary_decisions() \%>\%
     add_default_solver()

# print problem
print(p)

# print action names
action_names(p)
}
