# Problem Set 5 (PS5): Does a Covered Call Fund Beat Its Shares?

A covered call fund owns shares and, every month, sells one call on each share.
The buyer pays the fund a premium today. If the share price stays below the
strike, the call expires worthless and the fund keeps the shares and the
premium. If the share price rises above the strike, the call is exercised: the
fund gives up every gain above the strike. Covered call funds such as JEPI
and JEPQ own large U.S. stocks and sell calls against them, seeking monthly
income from the premiums. Their investors accept a trade: a steady premium in
exchange for the best months.

These trade-offs lead to the central question of PS5: **Does a covered call
fund beat simply holding the shares, and what does it give up?**

You'll answer it twice for each of **29 stocks and funds**. First, in a model:
you simulate the share price with geometric Brownian motion, price the calls on
the binomial tree, and run the fund over thousands of simulated half-years, as
in the course example. Then, in history: you replay the fund's **174 real
monthly calls**, six on each ticker, sold from April to September 2026 at real
option prices, and compare it with the shares, SPY, and cash over the same
days.

PS5 has two tracks, and you choose one. **Standard** covers the covered call
fund. **Advanced** adds a **collar fund**, which also buys a put each month,
paid for in part by the call, as in the course's protective collar example. The
put sets a floor under each month's loss, and Advanced asks whether that
protection paid for itself.

## Course materials and mathematical companion

PS5 builds on two course examples from the covered calls and collars lecture:

- [A Covered Call Fund on SPY](https://github.com/varnerlab/CHEME-5660-CourseRepository-Fall-2026/blob/main/lectures/week-11/L11b/CHEME-5660-L11b-Example-CoveredCallFund-SPY-Fall-2026.ipynb),
  which simulates the fund and compares its growth rate with that of the
  shares. Every Standard function copies a line or two from this example.
- [A Protective Collar on SPY](https://github.com/varnerlab/CHEME-5660-CourseRepository-Fall-2026/blob/main/lectures/week-11/L11b/CHEME-5660-L11b-Example-StandardListed-SPY-ProtectiveCollar-Fall-2026.ipynb),
  which builds the collar that the Advanced track rolls every month.

The [PS5 mathematical companion](docs/PS5-Mathematical-Companion.pdf) gives the
formulas. Each function's docstring names its example cell and its companion
slide.

## Dates and grading

- **Release:** Sunday, November 8, 2026.
- **Due:** Sunday, November 22, 2026 at 11:59 PM ET. Upload a ZIP of your
  project folder to Canvas.
- **Revisions:** Allowed until December 19, 2026 at 11:59 PM ET if your
  initial submission qualifies (below). We keep your highest score, even if
  you change tracks.
- **Score:** Out of 4 on either track. An Advanced score of 4, confirmed by
  the teaching team, also earns one Magic Point.

Submit a readable ZIP with attempted work by the deadline, even if it is
unfinished. A missing, empty, or unreadable submission receives a **Frozen
Zero** and cannot be revised. See the [grading rubric](RUBRIC.md).

## Getting started

Use Julia `1.12.7`. The trades and prices are supplied, and the packages are
the same as in PS4.

1. Download the `Source code (zip)` archive from the tagged
   [PS5 GitHub release](https://github.com/varnerlab/PS5-CHEME-4660-5660-Fall-2026/releases/tag/ps5-cheme-4660-5660-2026.1)
   and extract it.
2. In VS Code, open the extracted folder (the one containing
   [Project.toml](Project.toml)) and open a terminal there.
3. Install the packages (needs internet; fast if PS4 is installed on the same
   computer):

   ```text
   julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
   ```

4. Set [TRACK.txt](TRACK.txt) to exactly `standard` or `advanced`:

   | Track | Code to complete | Questions to answer |
   |:--|:--|:--|
   | Standard | Three functions in [src/Standard.jl](src/Standard.jl): `call_premium`, `covered_call_ratio`, and `growth_rate` | [responses/Standard.md](responses/Standard.md) |
   | Advanced | All five functions in [src/Advanced.jl](src/Advanced.jl): the same three plus `put_premium` and `collar_ratio` | [responses/Advanced.md](responses/Advanced.md) |
5. Before you write any code, answer Question 1a, your prediction.
6. Complete the functions as the sections below describe. Replace each
   `error("Complete ...")` with your calculation, following the TODO hint
   above it, then delete the TODO. Don't change the supplied signatures,
   docstrings, or return statements; some checks verify them.
7. Save your code and run the checker:

   ```text
   julia --project=. --startup-file=no check_submission.jl
   ```

   The checker runs the 12 Standard or 20 Advanced graded checks, then runs
   your functions on every ticker and writes `results/Report.md`. Unfinished
   calculations show `UNAVAILABLE`. Run it as you work; the first run is slow.

Edit only `TRACK.txt`, your track's source and response files, `Include.jl`,
and helper files you add. Put helper functions in `.jl` files under
[src](src), load them from [Include.jl](Include.jl), and document each one.

## The fund, the data, and the model

### One month of the fund

At the start of each month the fund owns its shares and sells one call per
share, about a month from expiration. The fund holds the premium as cash, which
earns the risk-free rate until the call expires. At expiration:

- **The call expires worthless** when the share price is at or below the
  strike. The fund keeps its shares and the premium.
- **The call is exercised** when the share price is above the strike. The fund
  delivers its shares at the strike, so it is worth the strike plus the
  premium, however high the share price went.

The fund then sells a new call for the next month and reinvests everything. We
measure each month by the fund's **wealth ratio**, its wealth at the end of the
month divided by its wealth at the start. Holding the shares instead gives the
share price at the end of the month divided by the price at the start.

**A worked example** (the checks' test month). The share price starts at 100
USD/share. The fund sells a call with a strike of 102 for a premium of 0.87,
which grows to 0.873 by expiration at the risk-free rate.

| Share price at expiration (USD/share) | Fund's wealth ratio | Shares' wealth ratio |
|--:|--:|--:|
| 99.66 | 1.0053 | 0.9966 |
| 110.00 | 1.0287 | 1.1000 |

In a falling month the premium lifts the fund above the shares; in a month
that rises past the strike, the strike caps it.

### Growth rate

Over several months, the fund's growth rate is the natural log of its final
wealth over its initial wealth, divided by the time in years. It is also the
sum of the logs of the monthly wealth ratios, divided by the time, which is how
`growth_rate` computes it. Every growth rate in PS5 is per year (units 1/yr),
as in the course example.

### The trades

The trades are the PS4 trade table, from the course options archive of
end-of-day option quotes on 29 tickers: AAPL, ABBV, AMD, AMGN, AVGO, BAC, BMY,
CVX, GOOG, GS, INTC, JNJ, JPM, LLY, MRNA, MSFT, MU, NVDA, OXY, PFE, QCOM, QQQ,
SPY, TGT, UNH, UPS, WFC, WMT, and XOM.

Each ticker has six trades, entered from April 13 to September 11, 2026. Each
expires 28 to 32 days after its entry, and the next one enters on the
expiration date, so the six trades cover about half a year back to back, ending
by October 9, 2026. On
two occasions (BMY and PFE) the next trade entered a few days later; on those
days the fund holds only its shares. PS5 uses two of each trade's option legs:

- `short_call`: the call the fund sells, with delta nearest 0.25, which puts
  its strike a few percent above the share price.
- `long_put` (Advanced): the put the collar fund buys, with delta nearest 0.10
  in absolute value, farther below the share price.

The quotes come from the broker Alpaca's free-plan **indicative** feed, which
approximates the exchange quotes. Graded results sell each call at its **mid
price**, halfway between the quoted bid and ask. The report adds the same fund
selling at the bid; the gap is a rough cost of trading if the quoted spreads
were real. The [data notes](data/README.md) give the details.

### The model

For each ticker, the model uses what the fund knew on its first entry date:

- **Share prices:** geometric Brownian motion with the drift and volatility
  estimated from the year of daily closes before that date, simulated for six
  months on 10,000 paths. Each month lasts as long as the first trade. These paths are a belief about the share
  price, as in the course example.
- **Strikes:** every month the fund sells a call at the first trade's strike
  as a multiple of the share price, so its strike moves with the share price.
- **Premiums:** your `call_premium` prices the call on the binomial tree, once
  at the historical volatility (as in the course example) and once at the
  call's implied volatility, the volatility its market price implies.

Because the strike is a fixed multiple of the share price, the premium is the
same percentage of the share price every month, so the report prices each call
once per ticker.

### Simplifications and benchmarks

- One call per share; every amount is in USD per share.
- Every call is held to expiration and settled at the close on the expiration
  date. The calls are American, but PS5 assumes no early exercise.
- No commissions, dividends, or taxes. Every growth rate uses closing prices
  only, so the fund, the shares, and SPY all omit dividends.

The benchmarks cover each ticker's own dates, from its first entry to its last
expiration. **The shares** and **SPY** are bought at the first close and held.
**Cash** earns the risk-free rate, from the 13-week Treasury bill yield of
3.76% per year, the same rate as PS4 (`risk_free_rate` in
[config/defaults.toml](config/defaults.toml)).

## Study 1: What does the model promise?

The model gives, for each ticker, the distribution of the fund's and the
shares' growth rates over half a year, before any of it happened.

1. **Complete `call_premium`.** Build one short American call with the course
   `build` function and `MyAmericanCallContractModel`, then price it with the
   course `binomial_premium` function on a 60-step tree, as in Task 2 of the
   covered call fund example.
2. **Complete `covered_call_ratio`.** Return the fund's wealth ratio for one
   month, as in the example's Task 2.
3. **Complete `growth_rate`.** Return the growth rate from a list of wealth
   ratios and the time in years, as in the example's Task 3.
4. **Read the promise.** Run the checker. In `results/Report.md`, read the
   Study 1 tables:
   - **Premiums: model and market** compares, for each ticker, the premium the
     model gives at the historical volatility and at the implied volatility
     with the market's mid price.
   - **The fund and the shares in the model** averages, over the tickers, each
     strategy's mean growth rate, its probability of a negative growth rate,
     and the probability that the fund grows faster than the shares.
   - **Strike choice in the model** repeats the fund with calls at other
     strikes.
5. **Answer Question 1.**

## Study 2: What happened?

The same functions replay the fund's real calls. The fund sells each call at
its real mid price, and each month's wealth ratio uses the real share prices
at entry and at expiration.

1. **Rerun the checker** (no new code), then read the Study 2 tables in
   `results/Report.md`:
   - **Growth rates and benchmarks**: the average, median, lowest, and highest
     growth rate over the tickers, for the fund, the shares, SPY, and cash, and
     how many tickers' funds beat their shares.
   - **Each ticker**: how many months each fund's calls were exercised
     ("called away"), its average premium, and its growth rate beside that of
     the shares.
   - **Promise versus outcome**: for each ticker, the model's probability
     that the fund would beat the shares, whether it did, and where what
     happened falls among the model's simulated outcomes. Here the model
     follows the real roll: each trade keeps its real strike, premium, and
     dates, and only the share prices are simulated, so a surprise comes from
     the share prices.
2. **Answer Question 2.**

## Study 3: What can we conclude?

Answer Question 3: compare the fund with the shares, SPY, and cash, and decide
what one half-year of history on 29 tickers can and cannot tell you. Standard
students write no more code; Advanced students first complete the section
below.

## Advanced: The collar fund

The collar fund holds the shares, sells the same call, and also buys the
`long_put` each month. Below the put's strike, the put pays the difference, so
the fund's monthly loss has a floor; the call caps its gain as before. The
put's price comes out of the call's premium.

1. **Complete `put_premium`.** Price one long American put on the binomial
   tree, as `call_premium` does for the call. Listed puts are American, so
   their price includes the right to exercise early; the collar fund holds
   each put to expiration and does not use that right, which is worth little
   for a one-month put well below the share price.
2. **Complete `collar_ratio`.** Return the collar fund's wealth ratio for one
   month: the shares held between the floor and the cap, plus the call's
   premium minus the put's, grown to expiration.
3. **Read the collar.** Rerun the checker. The Study 1 tables add the collar
   fund in the model, and the report's **Advanced: the collar fund** table
   shows each ticker's real collar fund, with the months its put paid.
4. **Answer Question 3, including part c.**

## Check and submit your work

1. Save your code and answers, then run the checker again:

   ```text
   julia --project=. --startup-file=no check_submission.jl
   ```

   It flags unanswered questions and writes `MANIFEST.txt`.
2. ZIP the whole project folder as `CHEME-5660-PS5-<your netid>.zip`.
3. Upload the ZIP to the PS5 assignment on Canvas.

You are graded on correct calculations and interpretation, not on whether the
fund wins. A 3 or 4 requires passing every check; the teaching team then
reviews your code and answers. See the [rubric](RUBRIC.md).
