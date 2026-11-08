# PS5 data update plan (instructor only; not in the student release)

Written 2026-11-04. Status: **done 2026-11-08**: 203 trades, seven per ticker, from the options archive
`data-options-eod-2026-11-06`.

## Why

PS5 currently ships the PS4 data unchanged (`data/trades.csv`, `parameters.csv`,
`benchmark.csv`): 174 trades, six back-to-back monthly trades on each of 29 tickers,
entered 2026-04-13 to 2026-09-11. The rolls stop there because the published options
archive, `data-options-eod-2026-10-16`, ends on 2026-10-16, and the builder only
opens a trade whose expiration is on or before the archive's last session.

- 27 tickers' rolls end with an expiration of **2026-10-02**. Their next trade would
  enter 2026-10-02 and expire about **2026-10-30** (the expiration closest to 30 days,
  within 25 to 35).
- 2 tickers' rolls end **2026-10-09**. Their next trade would expire about
  **2026-11-06**.

The daily collection (31 tickers, every session) continues past 2026-10-16. With data
through **Friday 2026-11-06's close**, every ticker should get a **seventh** trade
(October), about 203 trades in all. This is inferred from the dates and the weekly
Friday expirations; the builder confirms it (a ticker without a weekly expiration in
the 25-35 day window rolls forward a session and may skip).

## Steps

1. **Make the new quotes visible to the course loaders.** PS4's builder reads the
   archive through the course package: `MyOptionsEODDataSet(ticker = ...)` for the
   chains and `MyOptionsEODUnderlyingDataSet()` for the daily closes. Point them at
   data through 2026-11-06 (a new archive build, for example
   `data-options-eod-2026-11-06`, or the local collection).
2. **Rebuild the three files with PS4's code** (public in
   `varnerlab/PS4-CHEME-4660-5660-Fall-2026`, `src/Trades.jl` and `src/Models.jl`),
   with PS4's `config/defaults.toml` unchanged:
   - `build_trade_table(config)` gives the trades. Check the log: PS4 skipped
     BMY 2026-09-04 and PFE 2026-05-15.
   - `trade_parameters(trades, price_history(config.tickers), config)` gives the
     trailing drift and volatility. The course price data end 2026-09-04, so the new
     October entries use the archive's closes after that date, as PS4 did.
   - `archive_closes("SPY")` gives `benchmark.csv`; it must cover every first entry
     and last expiration date.
   - Write them with the PS4 column order (`load_trade_table` checks it).
3. **Copy them into `data/`** here and update `data/README.md`: the provenance
   (archive or collection end date), counts, skips, and the SHA-256 hashes.
4. **Rebuild `data/strike_increments.csv`** from the new trades and the options
   archive the trades came from:
   `julia --project=. --startup-file=no instructor/build_strike_increments.jl <archive-dir>`
   (the unpacked `options_eod` artifact, one `<TICKER>.csv.gz` per ticker). Update
   its hash and its list of spacings in `data/README.md`, and the range "from 0.50 USD
   (PFE) to 5 USD" in `README.md` and on companion slide 8 if it changes. No other code changes are needed:
   `ticker_rolls` and the model use the number of trades each ticker has, so seven
   (or a mix of six and seven) works. Each extra trade adds about a sixth to the
   checker's run time (about 80 s Standard and 100 s Advanced with six trades).
5. **Update the text that says six:**
   - `README.md`: "174 real monthly calls, six on each ticker", "Each ticker has six
     trades, entered from April 13 to September 11", "ending by October 9", "about
     half a year", the BMY/PFE gap sentence (check the new skips).
   - `reports/Fund.jl`: "the model simulates six months of share prices";
     "about half a year".
   - `docs/PS5-Mathematical-Companion.tex`: "$N=6$", "six back-to-back trades",
     "six months", "about $0.47$ year"; rebuild with `make -C docs` and render the
     pages to check for overflow.
   - `responses/*.md`: "half-year" in Questions 1a and 3b (check it still fits).
   - `instructor/canvas-assignment-description.html` and `instructor/release-notes.md`:
     "174 real monthly calls from April to October 2026".
6. **Validate.**
   - Recreate the reference solutions (gitignored, so not in this repo):
     copy `src/Standard.jl` and `src/Advanced.jl` to `instructor/reference/` and
     replace each `error("Complete ...")` line with the code its TODO hint gives.
   - `julia --project=. --startup-file=no check_submission.jl --solution` on both
     tracks (`TRACK.txt` = `advanced`, then `standard`): 20/20 and 12/12, report reads
     sensibly, every number quoted in the README still true.
   - Reset `TRACK.txt` to `standard`; run the starter checker on both tracks (0/12,
     0/20, UNAVAILABLE, TODO warnings).
   - Build and check the student ZIP: `python3 instructor/build_release.py`, then the
     `validate_release.py` checks (they read the committed tree, so commit first).
   - Codex audit of the changed files.

## Then release

- Make the GitHub repository public (it was created private as a draft).
- Tag `ps5-cheme-4660-5660-2026.1`; the workflow drafts the GitHub release.
  The README and the Canvas copy already link to that tag.
