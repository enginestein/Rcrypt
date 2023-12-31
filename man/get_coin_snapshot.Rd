% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/public_api.R
\name{get_coin_snapshot}
\alias{get_coin_snapshot}
\title{Get specific coin details by coin id.}
\usage{
get_coin_snapshot(id)
}
\arguments{
\item{id}{integer. Coin id. Can be retreived using \code{\link{get_coins}}.}
}
\value{
A tibble containing details about the specified coin.
}
\description{
\code{get_coin_snapshot} returns a tibble of several coin details about the
provided id. These details include specifics about the coin, such as the algorithm
used, the url for the coin's website, the coin's twitter handle, coin start date,
and coin proof type.
}
\examples{
\dontrun{
# Get snapshot for bitcoin
get_coin_snapshot(1182)
}

}
\references{
\url{https://www.cryptocompare.com/api#-api-data-coinsnapshotfullbyid-}
}
