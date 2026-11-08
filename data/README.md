# PS5 supplied data

PS5 reads the four files in this folder: `trades.csv`, `parameters.csv`, and `benchmark.csv`, which hold the PS4 data and one more trade on each ticker, entered in October 2026, and `strike_increments.csv`, new for PS5 (see the SHA-256 hashes at the end). Do not edit these files.

## How PS5 uses the data

- **The roll.** Each ticker's seven trades, in order of entry, are the fund's seven months. On each trade the fund sells the `short_call` leg: the leg's strike is `short_call_K`, and graded results sell the leg at `short_call_mid` (the report's comparison sells at `short_call_bid`). The Advanced collar fund also buys the `long_put` leg at `long_put_mid`. A month uses the closes `S0` (entry) and `ST` (expiration), and the fund's cash, including the premium, grows at the risk-free rate for `days` calendar days. The cash carries from one trade to the next.
- **Gaps.** When a trade enters after the previous one's expiration (BMY on 2026-09-08 after 2026-09-04, and PFE on 2026-05-18 after 2026-05-15), the fund holds its shares and its cash in between: the shares move from one close to the next, and the cash grows at the risk-free rate for the days between. Holding the shares does the same.
- **Length of the roll.** A ticker's growth rates use the calendar days from its first entry to its last expiration, divided by 365.
- **The model.** Study 1 uses each ticker's first trade only: `S0`, the moneyness values `short_call_K / S0` and `long_put_K / S0`, the implied volatilities `short_call_iv` and `long_put_iv`, and the trailing drift `μ` and volatility `σ̂` from `parameters.csv`. These values are what the fund knew on its first entry date. Each simulated strike is put on the ticker's grid of listed strikes, `strike_increment` apart (`strike_increments.csv`): the smallest listed strike at or above the call's target, and the largest at or below the put's.
- **Benchmark.** SPY's growth rate for a ticker uses SPY's closes on that ticker's first entry date and last expiration date.

The rest of this file is the PS4 data notes, updated for the added trades.

## Sources

- Options: the course options archive, release `data-options-eod-2026-11-06`. The archive holds Alpaca end-of-day option quotes, and each underlying's daily close, for the sessions 2026-04-13 to 2026-11-06.
- Historical drift and volatility (`parameters.csv`): from the last 253 daily closes before each entry date, which give 252 daily changes, taken from the course daily price datasets. Those datasets end 2026-09-04, so a trade entered after 2026-09-04 uses the options archive's closes of the underlying for the days after 2026-09-04.
- The quotes come from Alpaca's free-plan indicative feed, not the official consolidated exchange quotes (OPRA). Graded results use mid prices, the midpoint of bid and ask. The bid and ask are used to choose and screen legs, and the report's comparison sells each call at the bid.
- The risk-free rate in `config/defaults.toml` is 0.0376, the mean investment rate (bond-equivalent yield) of 13-week Treasury bills over 20 auctions, from 2026-04-13 to 2026-08-24, the last auction in the course Treasury bill data.
- IWM and META are in the archive but excluded, because the course price datasets, which supply the historical drift and volatility, do not contain those two tickers.
- Benchmark: the daily closes of SPY, the `benchmark_ticker` in `config/defaults.toml`, from the same options archive.

## How the trades were chosen

- Each ticker is traded in a roll of back-to-back trades. The first entry is the first session on which the archive has the ticker's option quotes: 2026-04-13 for most tickers; 2026-04-15 for AMGN, AVGO, BMY, GOOG, PFE, QCOM, and UNH. Each trade is held to expiration, and the next one enters on the first session on or after that expiration. If no trade can be opened on a session, for example because a required leg is missing (see Counts), the roll tries the next session. The roll ends when the next expiration would fall after 2026-11-06, the archive's last session.
- The expiration is the one closest to 30 calendar days away, accepting 25 to 35 days.
- The at-the-money (ATM) strike is the strike closest to the underlying's close on the entry date, among strikes whose call and put both have a positive bid.
- The short call and short put are the strikes whose delta is closest to 0.25 in absolute value. Each wing (long call and long put) is the strike farther out than its short strike, with a mid below that short leg's mid, whose delta is closest to 0.1 in absolute value. The wings are chosen after the quote screen (below) has checked, and possibly moved, the short legs.
- Every trade is held to expiration and settled at the underlying's close in the archive on the expiration date (`ST`).

## Quote screen

Indicative quotes are sometimes implausibly wide, so each chosen leg is screened. A leg fails when its bid-ask spread is both more than 3.0 times the median spread of its neighbors and wider than 0.25 USD per share. A leg's neighbors are the two nearest strikes of the same type on each side, or fewer at the edge of the chain. A failed leg is replaced by the candidate whose delta is closest to the leg's target among those that pass the screen, have a narrower spread than the failed leg, and, for a wing, still meet the wing rules above; if there is none, the leg is kept. The ATM call and put move together, to the next-nearest strike where both pass and the wider of their two spreads is narrower than before.

## Counts

- Trades: 203 (7 per ticker on 29 tickers).
- Skipped candidate entries: 2. In each case the roll entered on the next session instead.
- BMY, entry 2026-09-04 (expiration 2026-10-02): skipped because every candidate protective put was priced at or above the short put it would protect, whose mid was 0.765 USD/share.
- PFE, entry 2026-05-15 (expiration 2026-06-12): skipped because no protective put strike with a quote and a delta lies beyond the short put strike of 24.0 USD/share.
- Entries whose expiration would fall after 2026-11-06 end the roll, as described above, and are not counted as skips.
- Legs moved by the quote screen: 15, on 10 trades (the `screened` column counts the moved legs for each trade).

## `trades.csv` (one row per trade)

Prices are USD per share, strikes are USD, volatilities are annualized decimals.

- `trade_id`: trade number, 1 to 203 (alphabetical by ticker, then by entry date).
- `ticker`: underlying symbol.
- `group`: sector label of the ticker from the archive (for example Technology, or Exchange-traded funds).
- `entry`: entry date.
- `expiration`: expiration date.
- `days`: calendar days from entry to expiration.
- `S0`: closing price of the underlying on the entry date (USD).
- `ST`: closing price of the underlying on the expiration date (USD).
- `atm_iv`: mean implied volatility of the ATM call and put, annualized decimal.
- For each leg in `atm_call`, `atm_put`, `short_call`, `short_put`, `long_call`, `long_put`, six columns:
  - `<leg>_K`: strike (USD).
  - `<leg>_bid`: bid (USD per share).
  - `<leg>_ask`: ask (USD per share).
  - `<leg>_mid`: midpoint of bid and ask (USD per share).
  - `<leg>_iv`: implied volatility, annualized decimal (may be empty; the leg then uses `atm_iv`).
  - `<leg>_delta`: option delta (may be empty only for an ATM leg, which is chosen by strike).
- `screened`: number of legs the quote screen moved (0 to 6).

## `parameters.csv` (one row per trade)

- `trade_id`: matches `trades.csv`.
- `ĝ`: annualized mean log growth rate (mean daily log return times 252).
- `σ̂`: annualized volatility (standard deviation of daily log returns times the square root of 252), the models' historical volatility.
- `μ`: annualized drift of the price, `ĝ` plus half of `σ̂` squared, the models' historical drift.
- `n_obs`: number of daily returns used (252).

## `benchmark.csv` (one row per session)

The daily closes of SPY from the options archive, the same source as `S0` and `ST` in `trades.csv`, so every trade's entry and expiration dates have a close.

- `ticker`: the benchmark ticker, SPY on every row.
- `date`: session date, 2026-04-13 to 2026-11-06 (136 archive sessions).
- `close`: closing price on that date (USD per share).

## `strike_increments.csv` (one row per ticker)

The spacing of each ticker's listed strikes, which the model uses to put every simulated strike on a listed strike. Listed options are not FLEX options, so their strikes come from a fixed grid.

- `ticker`: underlying symbol.
- `strike_increment`: the most common spacing between neighboring listed strikes, calls from `S0` to 1.15 times `S0` and puts from 0.85 times `S0` to `S0`, over the expirations of the ticker's trades, on their entry dates, in the course options archive (USD). Ties go to the smaller spacing.

The spacing is 0.50 USD for PFE, 1 USD for BAC, BMY, INTC, MRNA, OXY, QQQ, SPY, TGT, UPS, WFC, WMT, and XOM, 2.50 USD for QCOM, and 5 USD for the other tickers. Exchanges vary the spacing with the share price and the expiration, and the archive's first captures in April list fewer strikes, so a few real strikes (for example BAC's 57.5 call in April) are not on the grid, and the model's strike can differ from the strike a real chain would offer. One spacing per ticker is an approximation for the model; Study 2 uses the real strikes.

## SHA-256

Use these hashes to confirm that the files are unchanged.

- `trades.csv`: `ec0c3ec14191bf66ea0ff8f59742a73f86019903c4be35cbcbd4b03ff5446721`
- `parameters.csv`: `270469c9657da41acaee3bc978f591a618d1267280a3f2cf091453f8b1949a21`
- `benchmark.csv`: `5a0fb6ddf16960d0fbfdde9abb7e065ec988086460ed78e992a6d9c3caae74e3`
- `strike_increments.csv`: `9f0d26a186ee9016c5f3aaf3ea27c8aca758caeb749b89c1a6d6fc32b1e677ac`
