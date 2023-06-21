#' Total API calls used and remaining.
#'
#' \code{get_api_limit} returns a tibble detailing API calls made and API calls
#' remaining against established rate limits.
#'
#' @references \url{https://www.cryptocompare.com/api#requests}
#'
#' @param time character. Either "hour", "minute", or "second". Defaults to "hour".
#'
#' @return A single tibble with two rows - one for calls made and one for calls
#'   remaining.
#'
#' @examples
#' \dontrun{
#' # Get hour limit
#' get_api_limit()
#'
#' # Get second limit
#' get_api_limit(time = "second")
#' }
#'
#' @export
get_api_limit <- function(time = "hour") {
  # Check parameters
  check_params(time = time)

  query_url <- httr::modify_url(MIN_API_URL,
                                path = glue::glue("stats/rate/{time}/limit"))

  query_cont <- get_api_content(query_url)



  # Parse JSON from response into tibble
  limit_tbl <- query_cont[names(query_cont) != "Message"] %>%
    response_to_tbl() %>%
    dplyr::mutate(call_metric = c("calls_made", "calls_left")) %>%
    dplyr::select(call_metric, dplyr::everything())

  limit_tbl
}

#' List all available exchanges.
#'
#' \code{get_exchanges} provides details on each exchange available through the
#' API
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @param sign logical. Should the server sign the response? Defaults to FALSE.
#' @param app_name character. Name of app to be passed in API request. Defaults
#' to NULL.
#'
#' @return A tibble containing details for each exchange available through the API.
#'
#' @examples
#' \dontrun{
#' exchanges <- get_exchanges()
#' head(exchanges)
#' }
#'
#' @export
get_exchanges <- function(sign = FALSE, app_name = NULL) {
  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/all/exchanges",
                                query = list(
                                  sign = tolower(sign),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  # Parse content into tibble
  exchange_tbl <- tibble(
    exchange = names(query_cont),
    coin = purrr::map(
      query_cont,
      names
    )
  ) %>%
    tidyr::unnest() %>%
    dplyr::mutate(market = purrr::flatten(query_cont)) %>%
    tidyr::unnest()

  exchange_tbl
}

#' List all available coins.
#'
#' \code{get_coins} provides general information about all coins available through
#' the CryptoCompare API.
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @inheritParams get_exchanges
#'
#' @return A tibble containing details for each coin available through the API.
#'
#' @examples
#' \dontrun{
#' coins <- get_coins()
#' head(coins)
#' }
#'
#' @export
get_coins <- function(sign = FALSE, app_name = NULL) {
  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/all/coinlist",
                                query = list(
                                  sign = tolower(sign),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  # Parse data into tibble
  coin_tbl <- response_to_tbl(query_cont$Data)

  coin_tbl
}

#' Get details on news providers integrated on cryptocompare.
#'
#' \code{get_news_providers} returns details about news providers that are
#' integrated with the cryptocompare website.
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @inheritParams get_exchanges
#'
#' @return A tibble containining simple details about integrated news providers.
#'
#' @export
get_news_providers <- function(sign = FALSE, app_name = NULL) {
  check_params(sign = sign, app_name = app_name)

  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/news/providers",
                                query = list(
                                  sign = tolower(sign),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  news_provider_tbl <- response_to_tbl(query_cont)

  news_provider_tbl
}

#' Get cryptocurrency news items.
#'
#' \code{get_news} returns news items and URLs from news providers that can be
#' found with \code{\link{get_news_providers}}.
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @param feeds character. One or more news providers to query. News providers
#' can be found with \code{\link{get_news_providers}}.
#' @param ts character or POSIXct or POSIXt. Timestamp to pull news for. Defaults
#' to \code{Sys.time()}.
#' @param lang character. Code for the language to return results in. Defaults
#' to 'EN' for English.
#' @param sign logical. Should the server sign the response? Defaults to FALSE.
#' @param app_name character. Name of app to be passed in API request. Defaults
#' to NULL.
#'
#' @return A tibble containing news items and URLs from selected providers for
#' the specified time stamp.
#'
#' @examples
#' \dontrun{
#' get_news(c("cryptocompare", "cnn"))
#' }
#'
#' @export
get_news <- function(feeds,
                     ts = Sys.time(),
                     lang = "EN",
                     sign = FALSE,
                     app_name = NULL) {
  check_params(feeds = feeds,
               ts = ts,
               lang = lang,
               sign = sign,
               app_name = app_name)

  parsed_ts <- time_to_numeric(ts)
  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/news/",
                                query = list(
                                  feeds = glue::collapse(feeds, sep = ","),
                                  lTs = parsed_ts,
                                  lang = lang,
                                  sign = tolower(sign),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  news_tbl <- response_to_tbl(purrr::map(
    query_cont,
    `[`,
    c("id",
      "guid",
      "published_on",
      "imageurl",
      "title",
      "url",
      "source",
      "body",
      "tags",
      "lang")
  ))

  news_tbl %>%
    dplyr::mutate(published_on = lubridate::as_datetime(published_on))
}

#' Get price data for one or more coin(s).
#'
#' \code{get_price} provides price information about selected coins in terms
#' of other coins.
#'
#' @references \url{https://www.cryptocompare.com/api#-api-data-price-}
#'
#' @param fsyms character. 3 letter name(s) for coins to retreive price details for.
#' @param tsyms character. 3 letter name(s) for how price should be reported for
#'   \code{fsyms}.
#' @param exchange character. Exchange to query. Defaults to 'CCCAGG'.
#' @param sign logical. Should the server sign the response? Defaults to FALSE.
#' @param try_conversion logical. Should BTC conversion be used if \code{fsym}
#'   is not trading in \code{tsym} on specified exchange? Defaults to TRUE.
#' @param app_name character. Name of app to be passed in API request. Defaults
#'   to NULL.
#'
#' @return A tibble containing price details about selected coin(s).
#'
#' @examples
#' \dontrun{
#' # Get BTC price in USD
#' get_price("BTC", "USD")
#'
#' # Get BTC and ETH price in USD and EUR
#' get_price(c("BTC", "ETH"), c("USD", "EUR"))
#' }
#'
#' @export
get_price <- function(fsyms,
                      tsyms,
                      exchange = "CCCAGG",
                      sign = FALSE,
                      try_conversion = TRUE,
                      app_name = NULL) {
  check_params(fsyms = fsyms,
               tsyms = tsyms,
               exchange = exchange,
               sign = sign,
               try_conversion = try_conversion,
               app_name = app_name)

  # Ensure fsyms and tsyms are upper case
  fsyms <- toupper(fsyms)
  tsyms <- toupper(tsyms)
  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/pricemulti",
                                query = list(
                                  fsyms = glue::collapse(fsyms, sep = ","),
                                  tsyms = glue::collapse(tsyms, sep = ","),
                                  e = exchange,
                                  sign = tolower(sign),
                                  tryConversion = tolower(try_conversion),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  # Parse response into tibble with requested coins as rows and requested
  # prices as columns
  price_tbl <- query_cont %>%
    tibble::as_tibble() %>%
    tidyr::unnest() %>%
    dplyr::mutate(tosymbol = names(query_cont[[1]])) %>%
    tidyr::gather(
      key = fromsymbol,
      value = price,
      -tosymbol
    ) %>%
    dplyr::select(
      fromsymbol,
      dplyr::everything()
    )

  price_tbl
}

#' Get full price details for one or more coin(s).
#'
#' \code{get_price_details} is Like \code{\link{get_price}} but provides a more
#' thorough summary of price data by including details like 24 volume and highs
#' and lows.
#'
#' @references https://www.cryptocompare.com/api#-api-data-price-
#'
#' @inheritParams get_price
#'
#' @return A tibble containing comprehensive price details for \code{fsyms} in
#' terms of \code{tsyms}.
#'
#' @examples
#' \dontrun{
#' # Get BTC price details in USD
#' get_price_details("BTC", "USD")
#'
#' # Get BTC and ETH price details in USD and EUR
#' get_price_details(c("BTC", "ETH"), c("USD", "EUR"))
#' }
#'
#' @export
get_price_details <- function(fsyms,
                              tsyms,
                              exchange = "CCCAGG",
                              sign = FALSE,
                              try_conversion = TRUE,
                              app_name = NULL) {
  check_params(fsyms = fsyms,
               tsyms = tsyms,
               exchange = exchange,
               sign = sign,
               try_conversion = try_conversion,
               app_name = app_name)
  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/pricemultifull",
                                query = list(
                                  fsyms = glue::collapse(fsyms, sep = ","),
                                  tsyms = glue::collapse(tsyms, sep = ","),
                                  e = exchange,
                                  sign = tolower(sign),
                                  tryConversion = tolower(try_conversion),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  price_tbl <- query_cont$RAW %>%
    purrr::flatten() %>%
    response_to_tbl()

  price_tbl
}

#' Get historical daily price data
#'
#' \code{get_historical_price} provides price information about a single currency
#' at the daily level.
#'
#' @references \url{https://www.cryptocompare.com/api#-api-data-histoday-}
#'
#' @param fsym character. 3 letter name for coin to retreive price history for.
#' @param tsym character. 3 letter name for how price should be reported for
#' \code{fsym}.
#' @param end_time character or POSIXct or POSIXt. Final date to retrieve data
#' for in the format of yyyy-mm-dd with optional hh:mm:ss (used when unit is
#' set to "hour" or "minute"). Defaults to \code{Sys.time()}.
#' @param unit character. Either "day", "hour", or "minute" indicating the granularity of
#' the returned data. The default is 'day'. \strong{Note:} minute data is only available
#' for the past 7 days.
#' @param exchange character. Exchange to query. Defaults to 'CCCAGG'.
#' @param aggregate numeric. Data is reported every n units. Defaults to 1. Maximum
#' value of 30.
#' @param limit numeric. Number of records to retrive leading up to \code{end_date}.
#' If \code{all_data} is set to true, this is ignored. Defaults to 30 when \code{unit}
#' is "day", 168 when \code{unit} is "hour", and 1440 when \code{unit} is "minute".
#' Minimum of 1, maximum of 2000.
#' @param all_data logical. SHould all historical data for \code{fsym} be retreived?
#' Defaults to FALSE.
#' @param sign logical. Should the server sign the response? Defaults to FALSE
#' @param try_conversion logical. Should BTC conversion be used fsym is not trading
#' in tsym on specified exchange? Defaults to TRUE.
#' @param app_name character. Name of app to be passed in API request. Defaults
#' to NULL.
#'
#' @return A tibble containing daily price details for \code{fsym}
#'
#' @examples
#' \dontrun{
#' get_daily_price("BTC", "USD", "2017-10-31")
#' }
#'
#' @export
get_historical_price <- function(fsym,
                                 tsym,
                                 end_time = Sys.time(),
                                 unit = "day",
                                 exchange = "CCCAGG",
                                 aggregate = 1,
                                 limit = NULL,
                                 all_data = FALSE,
                                 sign = FALSE,
                                 try_conversion = TRUE,
                                 app_name = NULL) {
  check_params(fsym = fsym,
               tsym = tsym,
               end_time = end_time,
               unit = unit,
               exchange = exchange,
               aggregate = aggregate,
               limit = limit,
               all_data = all_data,
               sign = sign,
               try_conversion = try_conversion,
               app_name = app_name)

  # Set limit based on unit
  if (is.null(limit)) {
    limit <- dplyr::case_when(unit == "day" ~ 30,
                              unit == "hour" ~ 168,
                              TRUE ~ 1440)
  }

  # Parse end_date into proper numeric format
  p_end_time <- time_to_numeric(end_time)

  # Build query
  query_url <- httr::modify_url(MIN_API_URL,
                                path = glue::glue("data/histo{unit}"),
                                query = list(
                                  fsym = fsym,
                                  tsym = tsym,
                                  e = exchange,
                                  limit = limit,
                                  aggregate = aggregate,
                                  allData = tolower(all_data),
                                  sign = tolower(sign),
                                  tryConversion = tolower(try_conversion),
                                  toTs = p_end_time,
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  # Return parsed tibble
  history_tbl <- response_to_tbl(query_cont$Data)

  history_tbl
}

#' Get data for a currency pair
#'
#' \code{get_pair_snapshot} provides aggregated and individual data for the
#' provided currency pair in every exchange available.
#'
#' @references \url{https://www.cryptocompare.com/api#-api-data-coinsnapshot-}
#'
#' @param fsym character. 3 letter name for coin to retreive.
#' @param tsym character. 3 letter name for how details should be reported for
#' \code{fsym}.
#'
#' @return A list of 3 containing the following:
#' \describe{
#'   \item{coin_data}{A tibble containing general coin data}
#'   \item{aggregated_data}{A tibble containing aggregate data about the pair}
#'   \item{exchange_data}{A tibble containing exchange data for each available
#'        exchange and the provided pair}
#' }
#'
#' @examples
#' \dontrun{
#' # Get data on BTC and USD
#' get_pair_snapshot("BTC", "USD")
#' }
#'
#' @export
get_pair_snapshot <- function(fsym, tsym) {
  check_params(fsym = fsym,
               tsym = tsym)

  query_url <- httr::modify_url(API_URL,
                                path = "api/data/coinsnapshot",
                                query = list(
                                  fsym = fsym,
                                  tsym = tsym
                                ))

  query_cont <- get_api_content(query_url)

  coin_data <- query_cont$Data[!purrr::map_lgl(query_cont$Data, purrr::is_list) &
                                 !purrr::map_lgl(query_cont$Data, purrr::is_null)] %>%
    as_clean_tbl()

  aggregated_data <- query_cont$Data$AggregatedData %>%
    as_clean_tbl()

  exchange_data <- response_to_tbl(query_cont$Data$Exchanges)

  list(
    coin_data = coin_data,
    aggregated_data = aggregated_data,
    exchange_data = exchange_data
  )
}

#' Get specific coin details by coin id.
#'
#' \code{get_coin_snapshot} returns a tibble of several coin details about the
#' provided id. These details include specifics about the coin, such as the algorithm
#' used, the url for the coin's website, the coin's twitter handle, coin start date,
#' and coin proof type.
#'
#' @references \url{https://www.cryptocompare.com/api#-api-data-coinsnapshotfullbyid-}
#'
#' @param id integer. Coin id. Can be retreived using \code{\link{get_coins}}.
#'
#' @return A tibble containing details about the specified coin.
#'
#' @examples
#' \dontrun{
#' # Get snapshot for bitcoin
#' get_coin_snapshot(1182)
#' }
#'
#' @export
get_coin_snapshot <- function(id) {
  check_params(id = id)
  query_url <- httr::modify_url(API_URL,
                                path = "api/data/coinsnapshotfullbyid",
                                query = list(
                                  id = id
                                ))

  query_cont <- get_api_content(query_url)

  flat_cont <- query_cont$Data[1:3] %>%
    purrr::flatten()

  snapshot_tbl <- flat_cont[!purrr::map_lgl(flat_cont, purrr::is_list) &
              !purrr::map_lgl(flat_cont, purrr::is_null)] %>%
    as_clean_tbl() %>%
    dplyr::mutate(start_date = lubridate::mdy(start_date))

  snapshot_tbl
}

#' Gets social data for a given coin id.
#'
#' \code{get_social} returns a list containing several tibbles that provide
#' social details for the specified coin.
#'
#' @references \url{https://www.cryptocompare.com/api#-api-data-socialstats-}
#'
#' @inheritParams get_coin_snapshot
#'
#' @return A list with the following structure:
#' \itemize{
#'   \item \strong{similar_items} A tibble outlining coins similar to the coin provided.
#'   \item \strong{cryptopian_followers} A tibble containing details about followers of
#'     the provided coin on cryptocompare.
#'   \item \strong{page_views} A tibble outlining number of page views for the coin on
#'     different pages.
#'   \item \strong{crypto_compare_summary} Aggergated cryptocompare data for the given coin.
#'   \item \strong{social_media} A list containing the following three elements:
#'   \itemize{
#'     \item \strong{Twitter} A tibble containing Twitter data.
#'     \item \strong{Reddit} A tibble containing Reddit data.
#'     \item \strong{Facebook} A tibble containing Facebook data.
#'   }
#'   \item \strong{repo_summary} A tibble with details about various code repositories
#'     associated with the given coin.
#' }
#'
#' @examples
#' \dontrun{
#' # Get bitcoin social data
#' get_social(1182)
#' }
#'
#' @export
get_social <- function(id) {
  check_params(id = id)
  query_url <- httr::modify_url(API_URL,
                                path = "api/data/socialstats",
                                query = list(
                                  id = id
                                ))

  query_cont <- get_api_content(query_url)

  # Check for empty content - this is because the API does not return an error
  # when an invalid id value is passed in.
  if (query_cont$Data$General$Name == "") {
    stop(glue::glue("{id} is not a valid id. Empty result returned from API."),
         call. = FALSE)
  }

  # CryptoCompare data
  crypto_compare <- query_cont$Data$CryptoCompare
  similar_items <- response_to_tbl(crypto_compare$SimilarItems)

  cryptopian_followers <- response_to_tbl(crypto_compare$CryptopianFollowers)

  page_views <- crypto_compare$PageViewsSplit %>%
    as_clean_tbl() %>%
    tidyr::gather(key = "page",
                  value = "views")

  crypto_compare_summary <- crypto_compare[!purrr::map_lgl(crypto_compare, purrr::is_list)] %>%
    as_clean_tbl()

  # Social media
  social_names <- c("Twitter", "Reddit", "Facebook")

  social_media <- query_cont$Data[social_names] %>%
    purrr::map(as_clean_tbl)

  # Repo data
  repo_summary <- query_cont$Data$CodeRepository$List %>%
    # purrr::map(purrr::flatten) %>%
    purrr::map_df(as_clean_tbl)

  list(
    similar_items = similar_items,
    cryptopian_followers = cryptopian_followers,
    page_views = page_views,
    crypto_compare_summary = crypto_compare_summary,
    social_media = social_media,
    repo_summary = repo_summary
  )
}

#' Get top currencies by volume for a given currency.
#'
#' \code{get_top_pairs} returns a tibble containing the top currency pairs by
#' volume.
#'
#' @references \url{https://www.cryptocompare.com/api#-api-data-toppairs-}
#'
#' @param fsym character. Three letter symbol for currency of interest.
#' @param limit integer. Number of top pairs to return. Min of 1, max of 2000.
#' Defaults to 5.
#' @param sign logical. Should the server sign the response? Defaults to FALSE.
#'
#' @return A tibble containing the top currencies by volume for the specified
#' currency
#'
#' @examples
#' \dontrun{
#' # Get top 10 currencies for bitcoin
#' get_top_pairs("BTC", limit = 10)
#'
#' # Get top 20 currencies for ethereum
#' get_top_pairs("ETH", limit = 20)
#' }
#'
#' @export
get_top_pairs <- function(fsym, limit = 5, sign = FALSE) {
  check_params(fsym = fsym,
               limit = limit,
               sign = sign)

  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/top/pairs",
                                query = list(
                                  fsym = fsym,
                                  limit = limit,
                                  sign = tolower(sign)
                                ))

  query_cont <- get_api_content(query_url)

  pairs_tbl <- response_to_tbl(query_cont$Data)

  pairs_tbl
}

#' Get top exchanges by volume for a given currency pair.
#'
#' \code{get_top_exchanges} returns a tibble containing details about the top
#' exchanges by volume for a given currency pair.
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @param fsym character. 3 letter name for coin to retreive price history for.
#' @param tsym character. 3 letter name for how price should be reported for
#' \code{fsym}.
#' @param limit numeric. Maximum number of returned exchanges. Between 1 and 50.
#' @param sign logical. Should the server sign the response? Defaults to FALSE
#' @param app_name character. Name of app to be passed in API request. Defaults
#' to NULL.
#'
#' @return A tibble containing volume details for the top \code{limit} exchanges.
#'
#' @examples
#' \dontrun{
#' # Top exchanges for BTC - USD
#' get_top_exchanges("BTC", "USD")
#' }
#'
#' @export
get_top_exchanges <- function(fsym,
                              tsym,
                              limit = 5,
                              sign = FALSE,
                              app_name = NULL) {
  check_params(fsym = fsym,
               tsym = tsym,
               limit = limit,
               sign = sign,
               app_name = app_name)

  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/top/exchanges",
                                query = list(
                                  fsym = fsym,
                                  tsym = tsym,
                                  limit = limit,
                                  sign = tolower(sign),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  exchanges_tbl <- response_to_tbl(query_cont$Data)

  exchanges_tbl
}

#' Get top exchanges by volume along with additional details.
#'
#' \code{get_top_exchanges_full} retrieves top exchanges for the given coin pair
#' by volume along with additional coin and exchange details.
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @inheritParams get_top_exchanges
#'
#' @return A named list containing exchanges, coin_info, and aggregated_data.
#'
#' @examples
#' \dontrun{
#' get_top_exchanges_full("BTC", "USD")
#' }
#' @export
get_top_exchanges_full <- function(fsym,
                                   tsym,
                                   limit = 5,
                                   sign = FALSE,
                                   app_name = NULL) {
  check_params(fsym = fsym,
               tsym = tsym,
               limit = limit,
               sign = sign,
               app_name = app_name)

  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/top/exchanges/full",
                                query = list(
                                  fsym = fsym,
                                  tsym = tsym,
                                  limit = limit,
                                  sign = tolower(sign),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  list(
    exchanges = response_to_tbl(query_cont$Data$Exchanges),
    coin_info = as_clean_tbl(query_cont$Data$CoinInfo),
    aggregated_data = as_clean_tbl(query_cont$Data$AggregatedData)
  )
}

#' Get top coins by volume for the provided currency.
#'
#' \code{get_top_volumes} returns details about the top coins by volume for the
#' specified currency.
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @param tsym character. 3 letter name for coin to get top volumes for.
#' @param limit numeric. Maximum number of records to return. Defaults to 20.
#' @param sign logical. Should the server sign the response? Defaults to FALSE
#' @param app_name character. Name of app to be passed in API request. Defaults
#' to NULL.
#'
#' @return A tibble containing details about the top coins by volume for the
#' specified coin.
#'
#' @examples
#' \dontrun{
#' # Get top volumes traded into USD
#' get_top_volumes("USD")
#' }
#'
#' @export
get_top_volumes <- function(tsym,
                            limit = 20,
                            sign = FALSE,
                            app_name = NULL) {
  check_params(tsym = tsym,
               limit = limit,
               sign = sign,
               app_name = app_name)

  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/top/volumes",
                                query = list(
                                  tsym = tsym,
                                  limit = limit,
                                  sign = tolower(sign),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  volumes_tbl <- response_to_tbl(query_cont$Data)

  volumes_tbl
}

#' Get top coins by total volume across all markets.
#'
#' \code{get_top_coins_by_volume} returns details about the top coins by volume
#' for the specified coin (\code{tsym}).
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @param tsym character. 3 letter name for coin to get top volumes for.
#' @param limit numeric. Number of records to return. Defaults to 10.
#' @param page numeric. Page of results to return. Defaults to 0.
#' @param sign logical. Should the server sign the response? Defaults to FALSE.
#' @param app_name character. Name of app to be passed in API request. Defaults
#' to NULL.
#'
#' @return A tibble containing details about the top coins by volume for the
#' specified coin.
#'
#' @examples
#' \dontrun{
#' get_top_coins_by_volume("USD")
#' }
#'
#' @export
get_top_coins_by_volume <- function(tsym,
                                    limit = 10,
                                    page = 0,
                                    sign = FALSE,
                                    app_name = NULL) {
  check_params(tsym = tsym,
               limit = limit,
               page = page,
               sign = sign,
               app_name = app_name)

  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/top/totalvol",
                                query = list(
                                  tsym = tsym,
                                  limit = limit,
                                  page = page,
                                  sign = tolower(sign),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  query_data <- purrr::transpose(query_cont$Data)

  dplyr::bind_cols(
    coin_info = response_to_tbl(query_data$CoinInfo),
    # Exclude stream entries - at times contain more than a single entry
    conversion_info = purrr::map_df(query_data$ConversionInfo,
                                    `[`,
                                    c(
                                      "Conversion",
                                      "ConversionSymbol",
                                      "CurrencyFrom",
                                      "CurrencyTo",
                                      "Market",
                                      "Supply",
                                      "TotalVolume24H"
                                    )) %>%
      as_clean_tbl()
  )
}

#' Get weighted average price of coin pair based on any number of exchanges.
#'
#' \code{get_price_avg} returns the current trading details
#' (price, vol, open, high, low, etc) of a given coin pair as a volume weighted
#' average based on provided exchanges.
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @param fsym character. 3 letter name for coin to retreive price history for.
#' @param tsym character. 3 letter name for how price should be reported for
#' \code{fsym}.
#' @param exchanges character. Exchanges to build weighted average from.
#' Defaults to 'CCCAGG'.
#' @param sign logical. Should the server sign the response? Defaults to FALSE
#' @param try_conversion logical. Should BTC conversion be used fsym is not trading
#' in tsym on specified exchange? Defaults to TRUE.
#' @param app_name character. Name of app to be passed in API request. Defaults
#' to NULL.
#'
#' @return A tibble containing price details as a volume weighted average of the
#' provided exchanges.
#'
#' @examples
#' \dontrun{
#' get_price_avg("BTC", "USD", c("Coinbase", "Kraken", "Bitfinex"))
#' }
#'
#' @export
get_price_avg <- function(fsym,
                          tsym,
                          exchanges,
                          sign = FALSE,
                          try_conversion = TRUE,
                          app_name = NULL) {
  check_params(fsym = fsym,
               tsym = tsym,
               exchanges = exchanges,
               sign = sign,
               try_conversion = try_conversion,
               app_name = app_name)

  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/generateAvg",
                                query = list(
                                  fsym = fsym,
                                  tsym = tsym,
                                  e = glue::collapse(exchanges, sep = ","),
                                  sign = tolower(sign),
                                  tryConversion = tolower(try_conversion),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  price_average_tbl <- query_cont$RAW %>%
    as_clean_tbl()

  price_average_tbl
}

#' Get averge daily price for a given currency pair.
#'
#' \code{get_day_avg} returns the daily average for a given currency pair calculated
#' in one of 3 ways.
#'
#' @references \url{https://min-api.cryptocompare.com}
#'
#' @param fsym character. 3 letter name for coin to retreive price history for.
#' @param tsym character. 3 letter name for how price should be reported for
#' \code{fsym}.
#' @param end_time character or POSIXct or POSIXt. Indicates the date data should
#' be retrieved for. Defaults to \code{Sys.time()}.
#' @param exchange character. Exchange to query. Defaults to 'CCCAGG'.
#' @param avg_type character. Indicates the type of calculation to use. One of
#' "HourVWAP", "MidHighLow" or "VolFVolT".
#' @param utc_hour_diff numeric. Hour difference between current timezone and UTC.
#' The API returns results in UTC by default. Valid values are between -12 and 14.
#' @param sign logical. Should the server sign the response? Defaults to FALSE
#' @param try_conversion logical. Should BTC conversion be used fsym is not trading
#' in tsym on specified exchange? Defaults to TRUE.
#' @param app_name character. Name of app to be passed in API request. Defaults
#' to NULL.
#'
#' @return A tibble containing the date, fsym, tsym, and daily average price
#'
#' @examples
#' \dontrun{
#' # Get today's daily average of BTC in USD
#' get_day_avg("BTC", "USD")
#' }
#'
#' @export
get_day_avg <- function(fsym,
                        tsym,
                        end_time = Sys.time(),
                        exchange = "CCCAGG",
                        avg_type = "HourVWAP",
                        utc_hour_diff = 0,
                        sign = FALSE,
                        try_conversion = TRUE,
                        app_name = NULL) {
  check_params(fsym = fsym,
               tsym = tsym,
               end_time = end_time,
               exchange = exchange,
               avg_type = avg_type,
               utc_hour_diff = utc_hour_diff,
               sign = sign,
               try_conversion = try_conversion,
               app_name = app_name)

  # Parse end_time into correct format
  p_end_time <- time_to_numeric(end_time)

  query_url <- httr::modify_url(MIN_API_URL,
                                path = "data/dayAvg",
                                query = list(
                                  fsym = fsym,
                                  tsym = tsym,
                                  e = exchange,
                                  avgType = avg_type,
                                  UTCHourDiff = utc_hour_diff,
                                  toTs = p_end_time,
                                  sign = tolower(sign),
                                  extraParams = app_name
                                ))

  query_cont <- get_api_content(query_url)

  tibble(
    date = lubridate::as_date(end_time),
    fsym = fsym,
    tsym = tsym,
    daily_avg = query_cont[[1]]
  )
}
