% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/posterior-samples.R
\name{fitted_samples}
\alias{fitted_samples}
\alias{fitted_samples.gam}
\title{Draw fitted values from the posterior distribution}
\usage{
fitted_samples(model, ...)

\method{fitted_samples}{gam}(
  model,
  n = 1,
  newdata,
  seed,
  scale = c("response", "linear_predictor"),
  method = c("gaussian", "mh", "inla"),
  freq = FALSE,
  unconditional = FALSE,
  ncores = 1L,
  ...
)
}
\arguments{
\item{model}{a fitted model of the supported types}

\item{...}{arguments passed to other methods. For \code{fitted_samples()}, these
are passed on to \code{predict.gam()}.}

\item{n}{numeric; the number of posterior samples to return.}

\item{newdata}{data frame; new observations at which the posterior draws
from the model should be evaluated. If not supplied, the data used to fit
the model will be used for \code{newdata}, if available in \code{model}.}

\item{seed}{numeric; a random seed for the simulations.}

\item{scale}{character;}

\item{method}{character; the method used to generate samples from the
posterior distribution of the model. \code{"gaussian"}, the default, uses a
Gaussian approximation to the posterior. \code{"mh"} uses a simple Metropolis
Hastings sampler, while \code{"inla"} uses a variant of Integrated Nested
Laplace Approximation due to Wood (2019). Currently, the only available
option is \code{"gaussian"}.}

\item{freq}{logical; \code{TRUE} to use the frequentist covariance matrix of
the parameter estimators, \code{FALSE} to use the Bayesian posterior
covariance matrix of the parameters.}

\item{unconditional}{logical; if \code{TRUE} (and \code{freq == FALSE}) then the
Bayesian smoothing parameter uncertainty corrected covariance matrix is
used, if available.}

\item{ncores}{number of cores for generating random variables from a
multivariate normal distribution. Passed to \code{\link[mvnfast:rmvn]{mvnfast::rmvn()}}.
Parallelization will take place only if OpenMP is supported (but appears
to work on Windows with current \code{R}).}
}
\value{
A tibble (data frame) with 3 columns containing the posterior
predicted values in long format. The columns are
\itemize{
\item \code{row} (integer) the row of \code{newdata} that each posterior draw relates to,
\item \code{draw} (integer) an index, in range \code{1:n}, indicating which draw each row
relates to,
\item \code{response} (numeric) the predicted response for the indicated row of
\code{newdata}.
}
}
\description{
Expectations (fitted values) of the response drawn from the posterior
distribution of fitted model using a Gaussian approximation to the
posterior.
}
\examples{
load_mgcv()
\dontshow{
set.seed(2)
op <- options(cli.unicode = FALSE)
}
dat <- gamSim(1, n = 1000, dist = "normal", scale = 2)
m1 <- gam(y ~ s(x0) + s(x1) + s(x2) + s(x3), data = dat, method = "REML")

fitted_samples(m1, n = 5, seed = 42)
\dontshow{options(op)}
}
\references{
Wood, S.N., (2020). Simplified integrated nested Laplace approximation.
\emph{Biometrika} \strong{107}, 223--230. \doi{10.1093/biomet/asz044}
}
\author{
Gavin L. Simpson
}
