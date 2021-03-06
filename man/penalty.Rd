% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/penalty.R
\name{penalty}
\alias{penalty}
\alias{penalty.gam}
\alias{penalty.mgcv.smooth}
\alias{penalty.tensor.smooth}
\alias{penalty.t2.smooth}
\alias{penalty.re.smooth.spec}
\title{Extract and tidy penalty matrices}
\usage{
penalty(object, ...)

\method{penalty}{gam}(object, smooth = NULL, rescale = FALSE, ...)

\method{penalty}{mgcv.smooth}(object, rescale = FALSE, ...)

\method{penalty}{tensor.smooth}(object, margins = FALSE, ...)

\method{penalty}{t2.smooth}(object, margins = FALSE, ...)

\method{penalty}{re.smooth.spec}(object, data, ...)
}
\arguments{
\item{object}{a fitted GAM or a smooth.}

\item{...}{additional arguments passed to methods.}

\item{smooth}{character; vector of smooths to extract penalty matrices for.
If \code{NULL}, penalty matrices for all smooths in \code{object} are extracted.}

\item{rescale}{logical; by default, \emph{mgcv} will scale the penalty matrix for
better performance in \code{\link[mgcv:gamm]{mgcv::gamm()}}. If \code{rescale} is \code{TRUE}, this scaling
will be undone to put the penalty matrix back on the original scale.}

\item{margins}{logical; extract the penalty matrices for the tensor
product or the marginal smooths of the tensor product?}

\item{data}{data frame; a data frame of values for terms mentioned in the
smooth specification.}
}
\value{
A 'tibble' (data frame) of class \code{penalty_df} inheriting from
\code{tbl_df}, with the following components:
\itemize{
\item \code{smooth} - character; the label \emph{mgcv} uses to refer to the smooth,
\item \code{type} - character; the type of smooth,
\item \code{penalty} - character; the label for the specific penalty. Some smooths
have multiple penalty matrices, so the \code{penalty} component identifies the
particular penalty matrix and uses the labelling that \emph{mgcv} uses internally,
\item \code{row} - character; a label of the form \code{fn} where \code{n} is an integer for
the \code{n}th basis function, referencing the columns of the penalty matrix,
\item \code{col} - character; a label of the form \code{fn} where \code{n} is an integer for
the \code{n}th basis function, referencing the columns of the penalty matrix,
\item \code{value} - double; the value of the penalty matrix for the combination of
\code{row} and \code{col},
}
}
\description{
Extract and tidy penalty matrices
}
\note{
The \code{print()} method uses \code{\link[base:zapsmall]{base::zapsmall()}} to turn very small numbers
into 0s for display purposes only; the underlying values of the penalty
matrix or matrices are not changed.
}
\examples{
\dontshow{
op <- options(cli.unicode = FALSE, digits = 5)
}
load_mgcv()
dat <- data_sim("eg4", n = 400, seed = 42)
m <- gam(y ~ s(x0) + s(x1) + s(x2, by = fac),
         data = dat, method = "REML")
penalty(m)

# for a specific smooth
penalty(m, smooth = "s(x2):fac1")
\dontshow{options(op)}
}
\author{
Gavin L. Simpson
}
