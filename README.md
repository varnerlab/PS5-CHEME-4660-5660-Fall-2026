# Problem Set 5 (PS5): Does a Covered Call Fund Beat Holding Its Shares?

A covered call fund owns shares and, every month, sells one call contract for
every 100 shares it owns.
The buyer pays the fund a premium today. If the share price stays below the
strike, the call expires worthless and the fund keeps the shares and the
premium. If the share price rises above the strike, the call is exercised: the
fund gives up every gain above the strike. Covered call funds such as FEPI
own large technology stocks and sell slightly out-of-the-money calls on the
stocks they hold, collecting the premiums as income. Their investors accept a trade: a steady premium in
exchange for the best months.

These trade-offs lead to the central question of PS5: **Does a covered call
fund beat simply holding the shares, and what does it give up?**

You'll answer it twice for each of **29 stocks and funds**. First, in a model:
you simulate the share price with geometric Brownian motion, price the calls on
the binomial tree, and run the fund over thousands of simulated half-years, as
in the course example. Then, in history: you replay the fund's **174 real
monthly calls**, six on each ticker, sold from April to September 2026 at real
option prices, and compare it with holding the shares, SPY, and cash over the same
days.

PS5 has two tracks, and you choose one. **Standard** covers the covered call
fund. **Advanced** adds a **collar fund**, which also buys a put each month,
paid for in part by the call, as in the course's protective collar example. The
put sets a floor under each month's loss, and Advanced asks whether that
protection paid for itself.

## Course materials and mathematical companion

PS5 builds on two course examples from the covered calls and collars lecture:

- [A Covered Call Fund on a Hypothetical Stock](https://github.com/varnerlab/CHEME-5660-CourseRepository-Fall-2026/blob/main/lectures/week-11/L11b/CHEME-5660-L11b-Example-CoveredCallFund-SPY-Fall-2026.ipynb),
  which simulates the fund, with its shares and its cash account, and
  compares its growth rate with that of holding the same shares and cash.
  Every Standard function copies a few lines from this example.
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
   | Standard | Three functions in [src/Standard.jl](src/Standard.jl): `call_premium`, `covered_call_month`, and `growth_rate` | [responses/Standard.md](responses/Standard.md) |
   | Advanced | All five functions in [src/Advanced.jl](src/Advanced.jl): the same three plus `put_premium` and `collar_month` | [responses/Advanced.md](responses/Advanced.md) |
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
   calculations show `UNAVAILABLE`. Run it as you work. Once your functions
   run, the report prices every call on every simulated path, so a full run
   takes one to two minutes.

Edit only `TRACK.txt`, your track's source and response files, `Include.jl`,
and helper files you add. Put helper functions in `.jl` files under
[src](src), load them from [Include.jl](Include.jl), and document each one.

## The fund, the data, and the model

### One month of the fund

The fund holds 1,000 shares in the report (10 contracts of 100 shares) and a
cash account. It opens with cash equal to 5% of the value of its shares
(`cash_reserve` in [config/defaults.toml](config/defaults.toml)). At the start
of each month it sells one call contract for every 100 shares, about a month
from expiration, and follows the same steps as the course example:

1. Its **wealth at the start** of the month, before it sells the calls, is its
   shares plus its cash.
2. The **premium goes into the cash**, and over the month the cash earns the
   risk-free rate.
3. At expiration, when the share price is above the strike, **the calls are
   exercised**: the fund sells its shares to the call buyers at the strike and
   buys the same number of new shares at the share price, so its cash falls by
   the calls' payoff. Otherwise the calls expire worthless and the fund keeps
   its shares and the premium.
4. Its **wealth at the end** of the month is its shares plus its cash. When the
   cash runs out, the fund borrows at the risk-free rate (cash below zero).

The fund then sells new calls for the next month. We measure each month by the
fund's **wealth ratio**, its wealth at the end of the month divided by its
wealth at the start. The fund is compared with **holding the shares**: the
same shares and the same opening cash, selling no calls, so its cash only
earns the risk-free rate.

**A worked example** (a check's test month). The fund holds 1,000 shares at
100 USD/share and 5,000 USD of cash. It sells calls with a strike of 102 for a
premium of 0.87 USD/share, so 870 USD goes into its cash, and the cash grows by
the factor 1.00345 over the month.

| Share price at expiration (USD/share) | Fund's cash at the end (USD) | Fund's wealth ratio | Holding's wealth ratio |
|--:|--:|--:|--:|
| 99.66 | 5,890.25 | 1.0052 | 0.9969 |
| 110.00 | −2,109.75 | 1.0275 | 1.0954 |

In a falling month the premium lifts the fund above holding; in a month that
rises past the strike, the fund pays 8 USD/share for its new shares, borrows,
and the strike caps its gain.

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
- **Strikes:** listed options are not FLEX options, so their strikes come from
  a fixed grid. Every month the fund sells the smallest listed strike at or
  above the first trade's strike, as a multiple of the share price, times that
  month's share price. Each ticker's grid uses one strike increment, its most
  common spacing near the share price in the options archive
  ([data/strike_increments.csv](data/strike_increments.csv)), from 0.50 USD
  (PFE) to 5 USD. Real exchanges vary the increment with the share price, so
  this grid is an approximation.
- **Premiums:** your `call_premium` prices the calls on the binomial tree
  every month on every path, once at the historical volatility (as in the
  course example) and once at the call's implied volatility, the volatility
  its market price implies.

### Simplifications and benchmarks

- The fund sells whole contracts: one call contract (100 shares) for every
  100 shares it holds. Its growth rate does not depend on how many contracts
  it sells.
- The fund borrows at the risk-free rate, with no limit, when its cash runs
  out; a real fund pays more and faces borrowing limits.
- Every call is held to expiration and settled at the close on the expiration
  date. The calls are American, but PS5 assumes no early exercise.
- No commissions, dividends, or taxes. Every growth rate uses closing prices
  only, so the fund, holding the shares, and SPY all omit dividends.

The benchmarks cover each ticker's own dates, from its first entry to its last
expiration. **Holding the shares** holds the fund's shares and opening cash and
sells no calls. **SPY** is bought at the first close and held.
**Cash** earns the risk-free rate, from the 13-week Treasury bill yield of
3.76% per year, the same rate as PS4 (`risk_free_rate` in
[config/defaults.toml](config/defaults.toml)).

## Study 1: What does the model promise?

The model gives, for each ticker, the distribution of the growth rates of the
fund and of holding the shares over half a year, before any of it happened.

1. **Complete `call_premium`.** Build one short American call with the course
   `build` function and `MyAmericanCallContractModel`, then price it with the
   course `binomial_premium` function on a 60-step tree, as in Task 2 of the
   covered call fund example.
2. **Complete `covered_call_month`.** Run one month of the fund, as in the
   main loop of the example's Task 2, and return its wealth ratio and its cash
   at the end of the month. The report passes that cash in as the next
   month's starting cash.
3. **Complete `growth_rate`.** Return the growth rate from a list of wealth
   ratios and the time in years, as in the example's Task 3.
4. **Read the promise.** Run the checker. In `results/Report.md`, read the
   Study 1 tables:
   - **Premiums: model and market** compares, for each ticker, the premium the
     model gives at the historical volatility and at the implied volatility
     with the market's mid price.
   - **The fund and holding the shares in the model** averages, over the
     tickers, each strategy's mean growth rate, its probability of a negative
     growth rate, the probability that the fund grows faster than holding, and
     the probability that the fund's cash goes negative.
   - **Strike choice in the model** repeats the fund with calls at other
     target strikes.
5. **Answer Question 1.**

## Study 2: What happened?

The same functions replay the fund's real calls. The fund sells each month's
calls at their real strike and mid price, each month uses the real share
prices at entry and at expiration, and the cash carries from one month to the
next. Between an expiration and a later entry, the fund holds its shares and
its cash grows.

1. **Rerun the checker** (no new code), then read the Study 2 tables in
   `results/Report.md`:
   - **Growth rates and benchmarks**: the average, median, lowest, and highest
     growth rate over the tickers, for the fund, holding the shares, SPY, and
     cash, and how many tickers' funds beat holding.
   - **Each ticker**: how many months each fund's calls were exercised
     ("called away"), how many months ended with negative cash, its average
     premium, and its growth rate beside that of holding.
   - **Promise versus outcome**: for each ticker, the model's probability
     that the fund would beat holding, whether it did, and where what
     happened falls among the model's simulated outcomes. Here the model
     follows the real roll: each trade keeps its real strike as a multiple of
     the share price, its real dates, and its call's implied volatility. The
     share prices are simulated, each simulated call takes the listed strike
     at or above that multiple, and the binomial tree prices it at the
     implied volatility. A surprise comes mostly from the share prices, and
     partly from the gap between the market's premiums and the model's.
2. **Answer Question 2.**

## Study 3: What can we conclude?

Answer Question 3: compare the fund with holding the shares, SPY, and cash, and decide
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
2. **Complete `collar_month`.** Run one month of the collar fund and return
   its wealth ratio and its cash: the call's premium minus the put's goes into
   the cash, the cash grows, the calls' payoff is paid from it, and the puts'
   payoff, when the share price ends below the put's strike, is added to it.
   The puts and calls each cover all of the fund's shares, and the put's
   strike is the largest listed strike at or below its target.
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
