library(rcrypt)
context("test-public_api.R")

# Global objects
btc_id <- 1182
bogus_id <- 43
get_coins_result <- get_coins()
sample_coins <- get_coins_result$symbol[get_coins_result$sort_order <= 10]
sample_references <- c("USD", "EUR")

test_that("get_api_limit works", {
  api_limit_result <- get_api_limit()
  expect_is(api_limit_result, "tbl_df")
  expect_is(get_api_limit("minute"), "tbl_df")
  expect_is(get_api_limit("second"), "tbl_df")
  expect_equal(dim(api_limit_result), c(2, 5))
  expect_equal(purrr::map(api_limit_result, class),
               list(call_metric = "character",
                    histo = "integer",
                    price = "integer",
                    news = "integer",
                    strict = "integer"))
  expect_error(get_api_limit("tmp"), "time must be")
})

test_that("get_exchanges works", {
  get_exchanges_result <- get_exchanges()
  common_exchanges <- c(
    "Cryptopia",
    "BitTrex",
    "HitBTC",
    "Binance"
  )
  expect_is(get_exchanges_result, "tbl_df")
  expect_true(all(common_exchanges %in% get_exchanges_result$exchange))
  expect_equal(ncol(get_exchanges_result), 3)
  expect_equal(purrr::map(get_exchanges_result, class),
               list(exchange = "character",
                    coin = "character",
                    market = "character"))
})

test_that("get_coins works", {
  expect_is(get_coins_result, "tbl_df")
  expect_equal(purrr::map(get_coins_result, class),
               list(id = "integer",
                    url = "character",
                    image_url = "character",
                    name = "character",
                    symbol = "character",
                    coin_name = "character",
                    full_name = "character",
                    algorithm = "character",
                    proof_type = "character",
                    fully_premined = "integer",
                    total_coin_supply = "character",
                    pre_mined_value = "character",
                    total_coins_free_float = "character",
                    sort_order = "integer",
                    sponsored = "logical",
                    is_trading = "logical"
               ))
  expect_true(all(c("BTC", "ETH", "LTC") %in% get_coins_result$name))
})

test_that("get_news_providers works", {
  get_news_providers_result <- get_news_providers()
  expect_is(get_news_providers_result, "tbl_df")
  expect_equal(purrr::map(get_news_providers_result, class),
               list(key = "character",
                    name = "character",
                    lang = "character",
                    img = "character"))
  expect_error(get_news_providers(sign = "TEMP"),
               "sign must be a logical vector")
})

test_that("get_news_works", {
  news_providers <- c("cryptocompare", "coindesk")
  get_news_result <- get_news(news_providers)
  expect_is(get_news_result, "tbl_df")
  expect_equal(purrr::map(get_news_result, class),
               list(id = "integer",
                    guid = "character",
                    published_on = c("POSIXct", "POSIXt"),
                    imageurl = "character",
                    title = "character",
                    url = "character",
                    source = "character",
                    body = "character",
                    tags = "character",
                    lang = "character"))
  expect_true(all(news_providers %in% get_news_result$source))
  # TODO: Check behavior when incorrect source is passed to get_news()
  # expect_error(get_news("usatoday"))
})

test_that("get_price works", {
  get_price_result <- get_price(sample_coins, sample_references)
  expect_is(get_price_result, "tbl_df")
  expect_equal(dim(get_price_result), c(20, 3))
  expect_true(all(sample_coins %in% get_price_result$fromsymbol))
  expect_true(all(sample_references %in% get_price_result$tosymbol))
  expect_equal(purrr::map(get_price_result, class),
               list(fromsymbol = "character",
                    tosymbol = "character",
                    price = "numeric"))
  expect_error(get_price(sample_coins, sample_references, exchange = "non-exchange"),
               "market does not exist for this coin pair")
  expect_error(get_price("FAKECOIN", "USD"),
               "There is no data for any of the toSymbols")
})

test_that("get_price_details works", {
  get_price_details_result <- get_price_details(sample_coins, sample_references)
  expect_is(get_price_details_result, "tbl_df")
  expect_equal(dim(get_price_details_result), c(20, 29))
  expect_equal(purrr::map(get_price_details_result, class),
               list(type = "integer",
                    market = "character",
                    fromsymbol = "character",
                    tosymbol = "character",
                    flags = "integer",
                    price = "numeric",
                    lastupdate = c("POSIXct", "POSIXt"),
                    lastvolume = "numeric",
                    lastvolumeto = "numeric",
                    lasttradeid = "numeric",
                    volumeday = "numeric",
                    volumedayto = "numeric",
                    volume24hour = "numeric",
                    volume24hourto = "numeric",
                    openday = "numeric",
                    highday = "numeric",
                    lowday = "numeric",
                    open24hour = "numeric",
                    high24hour = "numeric",
                    low24hour = "numeric",
                    lastmarket = "character",
                    change24hour = "numeric",
                    changepct24hour = "numeric",
                    changeday = "numeric",
                    changepctday = "numeric",
                    supply = "numeric",
                    mktcap = "numeric",
                    totalvolume24h = "numeric",
                    totalvolume24hto = "numeric"))
})

test_that("get_historical_price works", {
  daily_price <- get_historical_price("ETH", "USD")
  hour_price <- get_historical_price("ETH", "USD", unit = "hour")
  minute_price <- get_historical_price("ETH", "USD", unit = "minute")
  expect_is(daily_price, "tbl_df")
  expect_is(hour_price, "tbl_df")
  expect_is(minute_price, "tbl_df")
  expect_equal(dim(daily_price), c(31, 7))
  expect_equal(dim(hour_price), c(169, 7))
  expect_equal(dim(minute_price), c(1441, 7))
  expect_equal(purrr::map(daily_price, class),
               list(time = c("POSIXct", "POSIXt"),
                    close = "numeric",
                    high = "numeric",
                    low = "numeric",
                    open = "numeric",
                    volumefrom = "numeric",
                    volumeto = "numeric"))
})

test_that("get_pair_snapshot works", {
  pair_snapshot_result <- get_pair_snapshot("BTC", "USD")
  expect_is(pair_snapshot_result, "list")
  expect_equal(length(pair_snapshot_result), 3)
  purrr::walk(pair_snapshot_result,
              expect_is,
              "tbl_df")
  expect_equal(purrr::map(pair_snapshot_result, purrr::map, class),
               list(
                 coin_data = list(
                   algorithm = "character",
                   proof_type = "character",
                   block_number = "integer",
                   net_hashes_per_second = "numeric",
                   total_coins_mined = "integer",
                   block_reward = "numeric"
                 ),
                 aggregated_data = list(
                   type = "integer",
                   market = "character",
                   fromsymbol = "character",
                   tosymbol = "character",
                   flags = "integer",
                   price = "numeric",
                   lastupdate = c("POSIXct", "POSIXt"),
                   lastvolume = "numeric",
                   lastvolumeto = "numeric",
                   lasttradeid = "integer",
                   volumeday = "numeric",
                   volumedayto = "numeric",
                   volume24hour = "numeric",
                   volume24hourto = "numeric",
                   openday = "numeric",
                   highday = "numeric",
                   lowday = "numeric",
                   open24hour = "numeric",
                   high24hour = "numeric",
                   low24hour = "numeric",
                   lastmarket = "character"
                 ),
                 exchange_data = list(
                   type = "integer",
                   market = "character",
                   fromsymbol = "character",
                   tosymbol = "character",
                   flags = "integer",
                   price = "numeric",
                   lastupdate = c("POSIXct", "POSIXt"),
                   lastvolume = "numeric",
                   lastvolumeto = "numeric",
                   lasttradeid = "character",
                   volume24hour = "numeric",
                   volume24hourto = "numeric",
                   open24hour = "numeric",
                   high24hour = "numeric",
                   low24hour = "numeric"
                 )
               ))
})

test_that("get_coin_snapshot works", {
  coin_snapshot_result <- get_coin_snapshot(btc_id)
  expect_is(coin_snapshot_result, "tbl_df")
  expect_equal(coin_snapshot_result$symbol, "BTC")
  expect_equal(dim(coin_snapshot_result), c(1, 39))
  expect_equal(purrr::map(coin_snapshot_result, class),
               list(
                 page_title = "character",
                 page_description = "character",
                 base_url = "character",
                 base_image_url = "character",
                 og_image_url = "character",
                 og_image_width = "integer",
                 og_image_height = "integer",
                 id = "integer",
                 document_type = "character",
                 h1text = "character",
                 danger_top = "character",
                 warning_top = "character",
                 info_top = "character",
                 symbol = "character",
                 url = "character",
                 base_angular_url = "character",
                 name = "character",
                 image_url = "character",
                 description = "character",
                 features = "character",
                 technology = "character",
                 total_coin_supply = "integer",
                 difficulty_adjustment = "character",
                 block_reward_reduction = "character",
                 algorithm = "character",
                 proof_type = "character",
                 start_date = "Date",
                 twitter = "character",
                 website_url = "character",
                 website = "character",
                 last_block_explorer_update_ts = c("POSIXct", "POSIXt"),
                 block_number = "integer",
                 block_time = "integer",
                 net_hashes_per_second = "numeric",
                 total_coins_mined = "integer",
                 previous_total_coins_mined = "integer",
                 block_reward = "numeric",
                 status = "character",
                 white_paper = "character"
               ))
  expect_error(get_coin_snapshot(bogus_id),
               "there is an id")
})

test_that("get_social works", {
  social_result <- get_social(btc_id)
  expect_is(social_result, "list")
  expect_equal(purrr::map(social_result, purrr::map, class),
                 list(
                   similar_items = list(
                       id = "integer",
                       name = "character",
                       full_name = "character",
                       image_url = "character",
                       url = "character",
                       following_type = "integer"
                     ),
                   cryptopian_followers = list(
                       id = "integer",
                       name = "character",
                       image_url = "character",
                       url = "character",
                       type = "character"
                     ),
                   page_views = list(
                     page = "character",
                     views = "integer"
                   ),
                   crypto_compare_summary = list(
                       points = "integer",
                       followers = "integer",
                       posts = "integer",
                       comments = "integer",
                       page_views = "integer"
                     ),
                   social_media = list(
                       Twitter = c("tbl_df", "tbl", "data.frame"),
                       Reddit = c("tbl_df", "tbl", "data.frame"),
                       Facebook = c("tbl_df", "tbl", "data.frame")
                     ),
                   repo_summary = list(
                       created_at = "integer",
                       open_total_issues = "integer",
                       parent = "logical",
                       size = "integer",
                       closed_total_issues = "integer",
                       stars = "integer",
                       last_update = c("POSIXct", "POSIXt"),
                       forks = "integer",
                       url = "character",
                       closed_issues = "integer",
                       closed_pull_issues = "integer",
                       fork = "character",
                       last_push = "integer",
                       source = "logical",
                       open_pull_issues = "integer",
                       language = "character",
                       subscribers = "integer",
                       open_issues = "integer"
                     )
                   ))
  expect_error(get_social(bogus_id),
               "is not a valid id")
})

test_that("get_top_pairs works", {
  top_pairs_result <- get_top_pairs("BTC")
  expect_is(top_pairs_result, "tbl_df")
  expect_equal(dim(top_pairs_result), c(5, 5))
  expect_equal(purrr::map(top_pairs_result, class),
               list(exchange = "character",
                    from_symbol = "character",
                    to_symbol = "character",
                    volume24h = "numeric",
                    volume24h_to = "numeric"))
  expect_error(get_top_pairs(c("ETH", "BTC")),
               "fsym must be a character vector of length 1")
  expect_error(get_top_pairs("FAKENAME"),
               "There is no data for the symbol FAKENAME")
})

test_that("get_top_exchanges works", {
  top_exchanges_result <- get_top_exchanges("BTC", "USD")
  expect_is(top_exchanges_result, "tbl_df")
  expect_equal(dim(top_exchanges_result), c(5, 5))
  expect_equal(purrr::map(top_exchanges_result, class),
               list(exchange = "character",
                    from_symbol = "character",
                    to_symbol = "character",
                    volume24h = "numeric",
                    volume24h_to = "numeric"))
  expect_error(get_top_exchanges("FAKENAME", "USD"),
               "There is no data for the symbol FAKENAME")
  expect_error(get_top_exchanges("BTC", "FAKENAME"),
               "There is no data for the toSymbol FAKENAME")
})

test_that("get_top_exchanges_full works", {
  top_exchanges_full_result <- get_top_exchanges_full("BTC", "USD")
  expect_is(top_exchanges_full_result, "list")
  expect_equal(purrr::map(top_exchanges_full_result, purrr::map, class),
                 list(
                   exchanges = list(
                       type = "integer",
                       market = "character",
                       fromsymbol = "character",
                       tosymbol = "character",
                       flags = "integer",
                       price = "numeric",
                       lastupdate = c("POSIXct", "POSIXt"),
                       lastvolume = "numeric",
                       lastvolumeto = "numeric",
                       lasttradeid = "numeric",
                       volume24hour = "numeric",
                       volume24hourto = "numeric",
                       open24hour = "numeric",
                       high24hour = "numeric",
                       low24hour = "numeric",
                       change24hour = "numeric",
                       changepct24hour = "numeric",
                       changeday = "integer",
                       changepctday = "integer",
                       supply = "integer",
                       mktcap = "numeric",
                       totalvolume24h = "numeric",
                       totalvolume24hto = "numeric"
                   ),
                   coin_info = list(
                       id = "integer",
                       name = "character",
                       full_name = "character",
                       internal = "character",
                       image_url = "character",
                       url = "character",
                       algorithm = "character",
                       proof_type = "character",
                       total_coins_mined = "integer",
                       block_number = "integer",
                       net_hashes_per_second = "numeric",
                       block_reward = "numeric",
                       total_volume24h = "numeric"
                   ),
                   aggregated_data = list(
                       type = "integer",
                       market = "character",
                       fromsymbol = "character",
                       tosymbol = "character",
                       flags = "integer",
                       price = "numeric",
                       lastupdate = c("POSIXct", "POSIXt"),
                       lastvolume = "numeric",
                       lastvolumeto = "numeric",
                       lasttradeid = "integer",
                       volumeday = "numeric",
                       volumedayto = "numeric",
                       volume24hour = "numeric",
                       volume24hourto = "numeric",
                       openday = "numeric",
                       highday = "numeric",
                       lowday = "numeric",
                       open24hour = "numeric",
                       high24hour = "numeric",
                       low24hour = "numeric",
                       lastmarket = "character",
                       change24hour = "numeric",
                       changepct24hour = "numeric",
                       changeday = "numeric",
                       changepctday = "numeric",
                       supply = "integer",
                       mktcap = "numeric",
                       totalvolume24h = "numeric",
                       totalvolume24hto = "numeric"
                     )
                 ))
  expect_error(get_top_exchanges_full("FAKENAME", "USD"),
               "There is no data for the symbol FAKENAME")
  expect_error(get_top_exchanges_full("BTC", "FAKENAME"),
               "There is no data for the toSymbol FAKENAME")
})

test_that("get_top_volumes works", {
  top_volumes_result <- get_top_volumes("USD")
  expect_is(top_volumes_result, "tbl_df")
  expect_equal(ncol(top_volumes_result), 6)
  expect_equal(purrr::map(top_volumes_result, class),
               list(symbol = "character",
                    supply = "numeric",
                    fullname = "character",
                    name = "character",
                    id = "integer",
                    volume24hourto = "numeric"))
  expect_error(get_top_volumes("FAKENAME"),
               "Nothing trades in FAKENAME")
})

test_that("get_top_coins_by_volume works", {
  top_coins_by_volume_result <- get_top_coins_by_volume("USD")
  expect_is(top_coins_by_volume_result, "tbl_df")
  expect_equal(dim(top_coins_by_volume_result), c(10, 17))
  expect_equal(purrr::map(top_coins_by_volume_result, class),
               list(id = "integer",
                    name = "character",
                    full_name = "character",
                    internal = "character",
                    image_url = "character",
                    url = "character",
                    algorithm = "character",
                    proof_type = "character",
                    type = "integer",
                    document_type = "character",
                    conversion = "character",
                    conversion_symbol = "character",
                    currency_from = "character",
                    currency_to = "character",
                    market = "character",
                    supply = "numeric",
                    total_volume24h = "numeric"))
  expect_error(get_top_coins_by_volume("FAKENAME"),
               "Nothing trades in FAKENAME")
})

test_that("get_price_avg works", {
  price_avg_result <- get_price_avg("BTC",
                                    "USD",
                                    exchanges = c("Coinbase",
                                                  "Kraken",
                                                  "Bitfinex"))
  expect_is(price_avg_result, "tbl_df")
  expect_equal(dim(price_avg_result), c(1, 19))
  expect_equal(purrr::map(price_avg_result, class),
               list(market = "character",
                    fromsymbol = "character",
                    tosymbol = "character",
                    flags = "integer",
                    price = "numeric",
                    lastupdate = c("POSIXct", "POSIXt"),
                    lastvolume = "numeric",
                    lastvolumeto = "numeric",
                    lasttradeid = "integer",
                    volume24hour = "numeric",
                    volume24hourto = "numeric",
                    open24hour = "numeric",
                    high24hour = "integer",
                    low24hour = "integer",
                    lastmarket = "character",
                    change24hour = "numeric",
                    changepct24hour = "numeric",
                    changeday = "integer",
                    changepctday = "integer"))
  expect_error(get_price_avg("FAKENAME", "USD", c("Coinbase", "Kraken")),
               "There is no data for the symbol FAKENAME")
  expect_error(get_price_avg("BTC", "FAKENAME", c("Coinbase", "Kraken")),
               "There is no data for the toSymbol FAKENAME")
  expect_error(get_price_avg("BTC", "USD", c("FAKENAME", "Kraken")),
               "fakename market does not exist for this coin pair")
})

test_that("get_day_avg works", {
  day_avg_result <- get_day_avg("BTC", "USD")
  expect_is(day_avg_result, "tbl_df")
  expect_equal(dim(day_avg_result), c(1, 4))
  expect_equal(purrr::map(day_avg_result, class),
               list(date = "Date",
                    fsym = "character",
                    tsym = "character",
                    daily_avg = "numeric"))
  expect_error(get_day_avg("FAKENAME", "USD"),
               "There is no data for the symbol FAKENAME")
  expect_error(get_day_avg("BTC", "FAKENAME"),
               "There is no data for the toSymbol FAKENAME")
})
