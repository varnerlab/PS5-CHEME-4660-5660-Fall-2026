# Problem Set 5 (PS5): Does a Covered Call Fund Beat Holding Its Shares?

A covered call fund owns shares of stock and sells a call option on those
shares every month. The buyer of the call pays the fund a **premium** up front.
In return, the buyer gets the right to buy the shares at a fixed price, the
**strike**, when the call expires. If the share price ends below the strike,
the fund keeps its shares and the premium. If the share price ends above the
strike, the fund gives up every gain above the strike. Funds such as FEPI use
this strategy on large technology stocks to generate income which they pay out to fund investors, similar in many ways to a dividend-paying stock, or coupon payments for bonds. 
In exchange for this income, investors give up any gains above the strike.

PS5 asks:

> **Does a covered call fund beat simply holding the shares, and what does it
> give up?**

You will answer this question for 29 stocks and funds, in three studies:

- **Study 1: What does the model promise?** You simulate share prices, price
  the calls on a binomial tree, and run the fund over thousands of simulated
  half-years.
- **Study 2: What happened?** You replay six monthly calls on each ticker, 174
  trades in all, sold from April to September 2026 at the market's quoted
  prices.
- **Study 3: What can we conclude?** You compare the fund with holding the
  shares, with SPY, and with cash over the same dates.

Choose one of two tracks. **Standard** covers the covered call fund.
**Advanced** adds a **collar fund**, which also buys a put each month. The put
limits how much the fund can lose in a month, and Advanced asks whether the
puts were worth what they cost.

## Logistics

- **Dates:** Released Sunday, November 8, 2026. Upload a ZIP of your project
  folder to Canvas by **11:59 PM ET on Sunday, November 22, 2026**.
- **Revisions:** Submit attempted work by the deadline, even if it is
  unfinished. You may then revise until December 19, 2026 at 11:59 PM ET. We
  keep your highest score, even if you change tracks. A missing, empty, or
  unreadable submission receives a **Frozen Zero** and cannot be revised.
- **Grading:** The maximum score is 4 on either track. An Advanced score of 4,
  confirmed by the teaching team, also earns one Magic Point. A 3 or 4 requires
  passing every check; the teaching team then reviews your code and answers.
  You are graded on your calculations and interpretation, not on whether the
  fund wins. See the [grading rubric](RUBRIC.md).
- **Reference solution:** Released after the deadline. Use it to understand
  your mistakes, but do not copy it. Copying it results in a score of 0.
- **Collaboration and AI:** You may discuss ideas and use course materials,
  documentation, the internet, and AI tools. Submit your own work, and do not
  share code or solutions.

## Getting started

Use Julia `1.12.7`. The trades and prices are supplied, and the packages are
the same as in PS4.

1. Download the `Source code (zip)` archive from the tagged
   [PS5 GitHub release](https://github.com/varnerlab/PS5-CHEME-4660-5660-Fall-2026/releases/tag/ps5-cheme-4660-5660-2026.1)
   and extract it.
2. In VS Code, open the extracted folder containing
   [Project.toml](Project.toml), and open a terminal there.
3. Install the packages. This needs internet access:

   ```text
   julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
   ```

4. Set [TRACK.txt](TRACK.txt) to exactly `standard` or `advanced`:

   | Track | Functions to complete | Questions to answer |
   |:--|:--|:--|
   | Standard | Three functions in [src/Standard.jl](src/Standard.jl): `call_premium`, `covered_call_month`, and `growth_rate` | [responses/Standard.md](responses/Standard.md) |
   | Advanced | Five functions in [src/Advanced.jl](src/Advanced.jl): the same three plus `put_premium` and `collar_month` | [responses/Advanced.md](responses/Advanced.md) |

5. Answer Question 1a, your prediction, before you write any code.
6. Complete each function by replacing each `error("Complete ...")` with your
   calculation. Follow the TODO hint above it, then delete the TODO. Do not
   change the function names, arguments, docstrings, or return statements.
7. Run the checker as you work:

   ```text
   julia --project=. --startup-file=no check_submission.jl
   ```

   The checker runs the 12 Standard or 20 Advanced checks and writes
   `results/Report.md`. Unfinished calculations show `UNAVAILABLE`. Once your
   functions run, a full run takes one to two minutes.

Each function copies a few lines from one of two L11b course examples:
[A Covered Call Fund on a Hypothetical Stock](https://github.com/varnerlab/CHEME-5660-CourseRepository-Fall-2026/blob/main/lectures/week-11/L11b/CHEME-5660-L11b-Example-CoveredCallFund-SPY-Fall-2026.ipynb)
and
[A Protective Collar on SPY](https://github.com/varnerlab/CHEME-5660-CourseRepository-Fall-2026/blob/main/lectures/week-11/L11b/CHEME-5660-L11b-Example-StandardListed-SPY-ProtectiveCollar-Fall-2026.ipynb).
Each docstring names the example cell to copy and the slide of the
[mathematical companion](docs/PS5-Mathematical-Companion.pdf) with the formulas.

Edit only `TRACK.txt`, your track's source and response files, `Include.jl`,
and any helper files you add. Put helper functions in `.jl` files under
[src](src), load them from [Include.jl](Include.jl), and document each one.

## One month of the fund

PS5 runs a separate fund on each of the 29 tickers (the 29 stocks and
exchange-traded funds). Each fund holds 1,000 shares of its one ticker and has
its own cash. Its opening cash is 5% of the value of its own 1,000 shares. For
example, a fund on a stock priced at 100 USD/share opens with 5,000 USD of cash. At the start of each month,
the fund sells 10 call contracts on that ticker. Each contract covers 100
shares, so the 10 contracts cover all 1,000 shares. The calls expire in about a
month, and each month has four steps:

1. The fund's **starting wealth** is its shares plus its cash, before it sells
   the calls.
2. The premium goes into the cash, and the cash earns the risk-free rate over
   the month.
3. At expiration, the calls are exercised if the share price is above the
   strike. The fund sells its shares to the call buyers at the strike and buys
   the same number of new shares at the share price, so its cash falls by the
   difference. If the share price is at or below the strike, the calls expire
   worthless.
4. The fund's **ending wealth** is its shares plus its cash. If the cash is
   below zero, the fund has borrowed at the risk-free rate.

The fund's **wealth ratio** for the month is its ending wealth divided by its
starting wealth. We compare the fund with **holding the shares**: the same
shares and the same opening cash, with no calls sold.

For example, suppose the fund holds 1,000 shares at 100 USD/share and 5,000 USD
of cash. It sells calls with a strike of 102 USD/share for a premium of 0.87
USD/share, so 870 USD goes into its cash. The cash grows by a factor of 1.00345
over the month.

| Share price at expiration (USD/share) | Fund's ending cash (USD) | Fund's wealth ratio | Holding's wealth ratio |
|--:|--:|--:|--:|
| 99.66 | 5,890.25 | 1.0052 | 0.9969 |
| 110.00 | −2,109.75 | 1.0275 | 1.0954 |

When the share price falls, the premium puts the fund ahead of holding. When
the share price rises past the strike, the fund pays 8 USD/share to replace its
shares, and holding comes out ahead.

**Growth rate.** PS5 measures performance by the growth rate, in 1/yr: the
natural log of final wealth divided by initial wealth, divided by the time in
years. The `growth_rate` function computes it by adding the logs of the monthly
wealth ratios and dividing by the time.

## The data

PS5 uses the 174 option trades in [data/trades.csv](data/trades.csv). This is
the same file you used in PS4, and it is included in this folder. A **trade** is
a set of options entered on one date and held until they expire about a month
later. Each ticker has six trades in a row, entered from April 13 to September
11, 2026. Each trade lasts 28 to 32 days,
and the next trade usually starts on the day the last one expires. The
[data notes](data/README.md) explain the two exceptions. PS5 uses two options
from each trade:

- `short_call` is the call the fund sells. Its delta is nearest 0.25, which
  puts its strike a few percent above the share price.
- `long_put` (Advanced) is the put the collar fund buys. Its delta is nearest
  0.10 in absolute value, which puts its strike farther below the share price.

The quotes come from the broker Alpaca's free-plan **indicative** feed, which
only approximates exchange quotes. Graded results sell each call at its **mid
price**, halfway between the quoted bid and ask. The report also shows the fund
selling at the bid, as a rough comparison of what trading might cost.

**Benchmarks.** Each ticker has three benchmarks, measured from its first entry
date to its last expiration date:

- **Holding the shares** keeps the fund's shares and opening cash and sells no
  calls.
- **SPY** is bought at the first close and held.
- **Cash** earns the risk-free rate, based on the 13-week Treasury bill yield of
  3.76% per year, the same rate as PS4.

**Simplifications.** A real fund's results would differ in these ways:

- The fund can borrow any amount at the risk-free rate.
- Every call is held to expiration and settled at the closing price. The calls
  are American, but PS5 assumes no early exercise.
- There are no commissions, dividends, or taxes. The fund, holding the shares,
  and SPY all use closing prices only.

## Study 1: What does the model promise?

For each ticker, the model uses only what the fund knew on its first trade date:

- **Share prices** follow geometric Brownian motion for six months on 10,000
  simulated paths. The drift and volatility are estimated from the year of daily
  closes before that date.
- **Strikes** are set each month at the same multiple of the share price as the
  first trade's strike. The fund then sells the nearest listed strike at or
  above that target. The [companion](docs/PS5-Mathematical-Companion.pdf)
  explains the listed strikes.
- **Premiums** come from your `call_premium` function, every month on every
  path. It runs twice: once at the historical volatility, and once at the
  implied volatility, the volatility at which a pricing model matches the
  option's market price.

Complete these functions, which follow Tasks 2 and 3 of the covered call fund
example:

1. **`call_premium`** returns the premium of one month's call. Build one short
   American call with the course `build` function and
   `MyAmericanCallContractModel`. Then price it with the course
   `binomial_premium` function on a 60-step tree.
2. **`covered_call_month`** runs one month of the fund and returns its wealth
   ratio and ending cash. The report passes that cash in as the next month's
   starting cash.
3. **`growth_rate`** returns the growth rate from a list of wealth ratios and
   the time in years.

Run the checker, read these tables in `results/Report.md`, and answer
Question 1:

| Table | What it shows |
|:--|:--|
| **Premiums: model and market** | For each ticker, the model's premium at each volatility, next to the market's mid price. |
| **The fund and holding the shares in the model** | Averages over the tickers: each strategy's mean growth rate and probability of a negative growth rate, the probability that the fund beats holding, and the probability that the fund's cash goes negative. |
| **Strike choice in the model** | The same fund with calls at other target strikes. |

## Study 2: What happened?

You write no new code for this study. Your functions now replay the trades. Each
month, the fund sells calls at the strike and mid price in the data, and it uses
the closing share prices at entry and expiration. The fund's cash carries over
from one month to the next.

Rerun the checker, read these tables, and answer Question 2:

| Table | What it shows |
|:--|:--|
| **Growth rates and benchmarks** | The average, median, lowest, and highest growth rate over the tickers for the fund, holding the shares, SPY, and cash, and how many funds beat holding. |
| **Each ticker** | The months the calls were exercised ("called away"), the months that ended with negative cash, the average premium, and the growth rates of the fund and holding. |
| **Promise versus outcome** | For each ticker, the model's probability that the fund would beat holding, whether it did, and where the outcome falls among the simulated outcomes. |

For **Promise versus outcome**, the model uses each trade's dates, strike
multiple, and implied volatility, and it simulates only the share prices. When
an outcome is far from what the model expected, the main cause is the share
prices. A smaller cause is the difference between the market's premiums and the
model's premiums.

## Study 3: What can we conclude?

Answer Question 3. Compare the fund with holding the shares, SPY, and cash, and
decide what one half-year of history on 29 tickers can and cannot tell you.
Standard students write no more code. Advanced students complete the next
section first.

## Advanced: The collar fund

The collar fund holds the shares, sells the same call, and also buys the
`long_put` each month. If the share price ends below the put's strike, the put
pays the difference, which limits the fund's loss for the month. The call still
limits the fund's gain. The fund pays for the put with part of the call's
premium.

1. **`put_premium`** returns the premium of one long American put, priced on the
   binomial tree as in `call_premium`. The collar fund holds each put to
   expiration and does not use its right to exercise early, which is worth little
   for a one-month put well below the share price.
2. **`collar_month`** runs one month of the collar fund and returns its wealth
   ratio and ending cash. The call's premium minus the put's premium goes into
   the cash, and the cash grows. The calls' payoff is then paid from the cash,
   and the puts' payoff is added to it. The fund's calls and puts each cover all
   of its shares.

Rerun the checker. The Study 1 tables now include the collar fund in the model.
The **Advanced: the collar fund** table shows each ticker's collar fund and the
months its put paid. Answer Question 3, including part c.

## Check and submit your work

1. Save your code and answers, and run the checker one more time:

   ```text
   julia --project=. --startup-file=no check_submission.jl
   ```

   It flags unanswered questions and writes `MANIFEST.txt`.
2. ZIP the whole project folder as `CHEME-5660-PS5-<your netid>.zip`.
3. Upload the ZIP to the PS5 assignment on Canvas.
