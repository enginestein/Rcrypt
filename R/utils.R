# Internal functions for crypto package ---------------------------------------

#' Parse API response
#'
#' \code{get_response_content} extracts the content from an API response and
#' converts the JSON response into an R list.
#'
#' @param api_response API response returned from a \code{\link[httr]{GET}} request
#'
#' @return A list in R parsed from the JSON of the \code{api_response}.
#'
#' @noRd
get_response_content <- function(api_response) {
  httr::content(api_response,
                type = "text",
                encoding = "UTF-8") %>%
    jsonlite::fromJSON(simplifyDataFrame = FALSE)
}

#' Check API response for common errors
#'
#' \code{api_errs} is a helper function designed to check API responses for
#' common errors.
#'
#' @inheritParams get_response_content
#'
#' @return Returns TRUE invisibly
#'
#' @noRd
api_errs <- function(api_response) {
  if (httr::status_code(api_response) != 200) {
    stop("API returned status code: ",
         httr::status_code(api_response),
         call. = FALSE)
  }

  if (httr::http_type(api_response) != "application/json") {
    stop("API returned type ",
         httr::http_status(api_response),
         " instead of the expected JSON",
         call. = FALSE)
  }

  api_content <- get_response_content(api_response)
  if ("Response" %in% names(api_content)) {
    if (api_content$Response == "Error") {
      stop(api_content$Message,
           "; ",
           api_content$ErrorsSummary,
           call. = FALSE)
    }
  }

  if ("Data" %in% names(api_content)) {
    if (length(api_content$Data) == 0) {
      stop(api_content$Message,
           call. = FALSE)
    }
  }

  invisible(TRUE)
}

#' Get and parse response from API call.
#'
#' \code{get_api_content} takes an API endpoint and returns the content of
#' the response after checking for errors.
#'
#' @param endpoint character. An API endpoint in the form of a URL.
#'
#' @return The content of the repsonse returned for the given endpoint. If the
#' API returns an error, this function will error out and provide details on the
#' error.
#'
#' @noRd
get_api_content <- function(endpoint) {
  query_resp <- httr::GET(endpoint, httr::user_agent(UA))
  api_errs(query_resp)
  get_response_content(query_resp)
}

check_params <- function(time,
                         fsym,
                         tsym,
                         fsyms,
                         tsyms,
                         exchange,
                         exchanges,
                         sign,
                         try_conversion,
                         app_name,
                         end_time,
                         unit,
                         aggregate,
                         limit,
                         all_data,
                         id,
                         avg_type,
                         utc_hour_diff,
                         page,
                         feeds,
                         ts,
                         lang) {
  if (!missing(time)) {
    if (length(time) > 1) {
      stop("time must be either 'hour', 'minute', or 'second'.",
           call. = FALSE)
    }

    if (!time %in% c("hour", "minute", "second")) {
      stop("time must be either 'hour', 'minute', or 'second'.",
           call. = FALSE)
    }
  }

  if (!missing(fsym)) {
    if (!purrr::is_character(fsym) | length(fsym) > 1) {
      stop("fsym must be a character vector of length 1 (ie 'BTC')",
           call. = FALSE)
    }
  }

  if (!missing(tsym)) {
    if (!purrr::is_character(tsym) | length(tsym) > 1) {
      stop("tsym must be a character vector of length 1 (ie 'USD')",
           call. = FALSE)
    }
  }

  if (!missing(fsyms)) {
    if (!purrr::is_character(fsyms)) {
      stop("fsyms must be a character vector",
           call. = FALSE)
    }
  }

  if (!missing(tsyms)) {
    if (!purrr::is_character(tsyms)) {
      stop("tsyms must be a character vector",
           call. = FALSE)
    }
  }

  if (!missing(exchange)) {
    if (!purrr::is_character(exchange) | length(exchange) > 1) {
      stop("exchange must be a chracter vector of length 1 (ie 'CCCAGG')",
           call. = FALSE)
    }
  }

  if (!missing(exchanges)) {
    if (!purrr::is_character(exchanges)) {
      stop("exchanges must be a character vector of valid exchange names",
           call. = FALSE)
    }
  }

  if (!missing(sign)) {
    if (!purrr::is_logical(sign) | length(sign) > 1) {
      stop("sign must be a logical vector of length 1 (ie TRUE)",
           call. = FALSE)
    }
  }

  if (!missing(try_conversion)) {
    if (!purrr::is_logical(try_conversion) | length(try_conversion) > 1) {
      stop("try_conversion must be a logical vector of length 1 (ie TRUE)",
           call. = FALSE)
    }
  }

  if (!missing(app_name)) {
    if (!is.null(app_name) & (!purrr::is_character(app_name) | length(app_name) > 1)) {
      stop("app_name must be either NULL or a character vector of length 1")
    }
  }

  if (!missing(end_time)) {
    if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", end_time)) {
      stop("end_time must be a string or POSIXct or POSIXt object matching the pattern of 'yyyy-mm-dd hh:mm:ss' where 'hh:mm:ss' is optional",
           call. = FALSE)
    }
  }

  if (!missing(ts)) {
    if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", ts)) {
      stop("ts must be a string or POSIXct or POSIXt object matching the pattern of 'yyyy-mm-dd hh:mm:ss' where 'hh:mm:ss' is optional",
           call. = FALSE)
    }
  }

  if (!missing(unit)) {
    if (!unit %in% c("day", "hour", "minute")) {
      stop("unit must be one of 'day', 'hour', or 'minute'",
           call. = FALSE)
    }
  }

  if (!missing(aggregate)) {
    if (!purrr::is_bare_numeric(aggregate) | aggregate < 1 | aggregate > 30) {
      stop("aggregate must be a numeric vector of length 1 between 1 and 30",
           call. = FALSE)
    }
  }

  if (!missing(limit)) {
    if (!is.null(limit)) {
      if (!purrr::is_bare_numeric(limit) | limit < 1 | limit > 2000) {
        stop("limit must be a numeric vector of length 1 between 1 and 2000",
             call. = FALSE)
      }
    }
  }

  if (!missing(all_data)) {
    if (!purrr::is_logical(all_data) | length(all_data) > 1) {
      stop("all_data must be a logical vector of length 1 (ie TRUE)",
           call. = FALSE)
    }
  }

  if (!missing(id)) {
    if (!purrr::is_bare_numeric(id) | length(id) > 1) {
      stop("id must be a numeric vector of length 1",
           call. = FALSE)
    }
  }

  if (!missing(avg_type)) {
    if (!purrr::is_character(avg_type) | !avg_type %in% c("HourVWAP", "MidHighLow", "VolFVolT")) {
      stop("avg_type must be a character vector of either 'HourVWAP', 'MidHighLow', or 'VolFVolT'",
           call. = FALSE)
    }
  }

  if (!missing(utc_hour_diff)) {
    if (!purrr::is_bare_numeric(utc_hour_diff) | utc_hour_diff < -12 | utc_hour_diff > 14) {
      stop("utc_hour_diff must be a numeric value between -12 and 14",
           call. = FALSE)
    }
  }

  if (!missing(page)) {
    if (!purrr::is_bare_numeric(page)) {
      stop("page must be a numeric value",
           call. = FALSE)
    }
  }

  if (!missing(feeds)) {
    if (!purrr::is_character(feeds)) {
      stop("feeds must be a character vector",
           call. = FALSE)
    }
  }

  if (!missing(lang)) {
    if (!purrr::is_character(lang) | length(lang) > 1) {
      stop("lang must be a character vector of length one",
           call. = FALSE)
    }
  }
}

#' Possibly read a set of values
#'
#' \code{possibly_read} uses \code{\link[readr]{parse_guess}} and wraps it in
#' \code{\link[purrr]{possibly}} to create a safe parser for objects.
#'
#' @inheritParams readr::parse_guess
#'
#' @return A parsed version of the input vector.
#'
#' @noRd
possibly_read <- purrr::possibly(
  ~readr::parse_guess(., na = c("", "NA", "N/A")),
  otherwise = NA
)

#' Clean up a tbl parsed from API response
#'
#' \code{parse_date_columns} takes a tbl and converts column names to snake case
#' and then parses the date columns that are integers into POSIXct objects. It also
#' converts columns to the proper type using \code{\link{possibly_read}}.
#'
#' @param tbl Tibble parsed from API response
#'
#' @return The input tbl with specified columns cleaned and updated appropriately.
#'
#' @noRd
as_clean_tbl <- function(tbl) {
  tbl %>%
    purrr::map_df(possibly_read) %>%
    janitor::clean_names(case = "snake") %>%
    dplyr::mutate_at(
      dplyr::vars(dplyr::matches("update|^time")),
      dplyr::funs(lubridate::as_datetime)
  )
}

#' Parse API response into a tibble
#'
#' \code{response_to_tbl} takes a nested list returned from an API and turns
#' it into a tibble. It uses \code{\link{as_clean_tbl}} to parse the list
#' data into appropriate R types.
#'
#' @param parsed_response API response that has been parsed into an R list
#'
#' @return A tibble of a nested list.
#'
#' @noRd
response_to_tbl <- function(parsed_response) {
  # TODO: Find more efficient implementation for this
  tbl_response <- parsed_response %>%
    # Convert everything to character - this is corrected in as_clean_tbl()
    # This conversion ensures that tibbles will be able to be stacked with
    # bind_rows() in map_df()
    purrr::map(
      purrr::map,
      as.character
    ) %>%
    purrr::map_df(tibble::as_tibble) %>%
    as_clean_tbl()

  tbl_response
}

#' Parse time into a numeric value
#'
#' \code{time_to_numeric} parses a provided time value into a numeric value good
#' good for passing into the API.
#'
#' @param time POSIXct or POSIXt value
#'
#' @return A numeric value respresenting the input time.
#'
#' @noRd
time_to_numeric <- function(time) {
  lubridate::as_datetime(time) %>%
    as.numeric() %>%
    floor()
}

MIN_API_URL <- "https://min-api.cryptocompare.com"
API_URL <- "https://www.cryptocompare.com"
PUBLIC_KEY <- "a0f4f688350018ad1b9785991c0bde5f704b005dc79972b114dbed4a615a983710bfc647ebe5a320daa28771dce6a2d104f5efa2e4a85ba3760b76d46f8571ca"
UA <- "https://github.com/blairj09/rcrypt"
