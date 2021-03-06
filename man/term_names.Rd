% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utililties.R
\name{term_names}
\alias{term_names}
\alias{term_names.gam}
\alias{term_names.mgcv.smooth}
\alias{term_names.gamm}
\title{Extract names of all variables needed to fit a GAM or a smooth}
\usage{
term_names(object, ...)

\method{term_names}{gam}(object, ...)

\method{term_names}{mgcv.smooth}(object, ...)

\method{term_names}{gamm}(object, ...)
}
\arguments{
\item{object}{a fitted GAM object or an {mgcv} smooth object}

\item{...}{arguments passed to other methods. Not currently used.}
}
\value{
A vector of variable names required for terms in the model
}
\description{
Extract names of all variables needed to fit a GAM or a smooth
}
