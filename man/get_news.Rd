% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/public_api.R
\name{get_news}
\alias{get_news}
\title{Get cryptocurrency news items.}
\usage{
get_news(feeds, ts = Sys.time(), lang = "EN", sign = FALSE,
  app_name = NULL)
}
\arguments{
\item{feeds}{character. One or more news providers to query. News providers
can be found with \code{\link{get_news_providers}}.}

\item{ts}{character or POSIXct or POSIXt. Timestamp to pull news for. Defaults
to \code{Sys.time()}.}

\item{lang}{character. Code for the language to return results in. Defaults
to 'EN' for English.}

\item{sign}{logical. Should the server sign the response? Defaults to FALSE.}

\item{app_name}{character. Name of app to be passed in API request. Defaults
to NULL.}
}
\value{
A tibble containing news items and URLs from selected providers for
the specified time stamp.
}
\description{
\code{get_news} returns news items and URLs from news providers that can be
found with \code{\link{get_news_providers}}.
}
\examples{
\dontrun{
get_news(c("cryptocompare", "cnn"))
}

}
\references{
\url{https://min-api.cryptocompare.com}
}
