# Problem Set 5 (PS5): Does a Covered Call Fund Beat Holding Its Shares?

A covered call fund owns shares of stock and sells a call option on those
shares every month. The buyer of the call pays the fund a **premium** up front.
In return, the buyer gets the right to buy the shares at a fixed price, the
**strike**, when the call expires. If the share price ends below the strike,
the fund keeps its shares and the premium. If the share price ends above the
strike, the fund gives up every gain above the strike. Funds such as FEPI use
this strategy on large technology stocks to generate income, which the funds pay to
investors much like a stock dividend or a bond coupon.

> **Does a covered call fund beat holding the shares, and what does it give
> up?**

You will answer this question for 29 tickers (stocks and exchange-traded funds),
in three studies:

- **Study 1: What does the model predict?** You simulate share prices, price
  the calls on a binomial tree, and run the fund over thousands of simulated
  seven-month periods.
- **Study 2: What happened?** You run the fund on the seven monthly calls sold
  on each ticker from April to October 2026, 203 trades in all, at the prices
  in the data.
- **Study 3: What can we conclude?** You compare the fund with holding the
  shares, with SPY, and with cash over the same dates.

Choose one of two tracks. **Standard** studies the covered call fund.
**Advanced** adds a **collar fund**, which also buys a put each month. If the
share price ends below the put's strike, the put pays the fund the difference.
Advanced compares the growth rate of the collar fund with the growth rates of
the covered call fund and of holding the shares.

## Logistics

- **Dates:** Released Sunday, November 8, 2026. Upload a ZIP of your PS5
  folder to Canvas by **11:59 PM ET on Sunday, November 22, 2026**.
- **Revisions:** Submit attempted work by the deadline, even if it is
  unfinished. You may then revise until December 19, 2026 at 11:59 PM ET. We
  keep your highest score, even if you change tracks. A missing, empty, or
  unreadable submission receives a **Frozen Zero** and cannot be revised.
- **Grading:** The maximum score is 4 on either track. An Advanced score of 4,
  confirmed by the teaching team, also earns one Magic Point. A 3 or 4 requires
  passing every check; the teaching team then reviews your code and answers.
  You are graded on your calculations and interpretation, not on whether the
  fund beats holding the shares. See the [grading rubric](RUBRIC.md).
- **Reference solution:** Released after the deadline. Use the solution to
  understand your mistakes, but do not copy the solution. Copying results in a
  score of 0.
- **Collaboration and AI:** You may discuss ideas and use course materials,
  documentation, the internet, and AI tools. Submit your own work, and do not
  share code or solutions.

## Getting started

Use Julia `1.12.7`. The trades and prices are supplied, and the packages are
the same as in PS4.

1. Download the `Source code (zip)` archive from the tagged
   [PS5 GitHub release](https://github.com/varnerlab/PS5-CHEME-4660-5660-Fall-2026/releases/tag/ps5-cheme-4660-5660-2026.2)
   and extract it.
2. In VS Code, open the extracted folder containing
   [Project.toml](Project.toml), and open a terminal there.
3. Install the packages. The installation needs internet access:

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
   calculation. Follow the TODO hint above each `error` line, then delete the
   TODO. Do not change the function names, arguments, docstrings, or return
   statements.
7. Run the checker as you work:

   ```text
   julia --project=. --startup-file=no check_submission.jl
   ```

   The checker runs the 12 Standard or 20 Advanced checks and writes
   `results/Report.md`. Unfinished calculations show `UNAVAILABLE`. Once your
   functions work, the checker takes one to two minutes.

You complete each function by copying a few lines from one of two L11b course
examples:
[A Covered Call Fund on a Hypothetical Stock](https://github.com/varnerlab/CHEME-5660-CourseRepository-Fall-2026/blob/main/lectures/week-11/L11b/CHEME-5660-L11b-Example-CoveredCallFund-SPY-Fall-2026.ipynb)
and
[A Protective Collar on SPY](https://github.com/varnerlab/CHEME-5660-CourseRepository-Fall-2026/blob/main/lectures/week-11/L11b/CHEME-5660-L11b-Example-StandardListed-SPY-ProtectiveCollar-Fall-2026.ipynb).
Each docstring names the example cell to copy and the slide of the
[mathematical companion](docs/PS5-Mathematical-Companion.pdf) with the formulas.

Edit only `TRACK.txt`, your track's source and response files, `Include.jl`,
and any helper files you add. Put helper functions in `.jl` files under
[src](src), load the files from [Include.jl](Include.jl), and document each function.

## One month of the fund

PS5 runs a separate fund on each of the 29 tickers (the 29 stocks and
exchange-traded funds). Each fund holds 1,000 shares of one ticker and has a
separate cash account. The opening cash is 5% of the value of the 1,000 shares.
For example, a fund on a stock priced at 100 USD/share opens with 5,000 USD of
cash. At the start of each month, the fund sells 10 call contracts on that
ticker. Each contract covers 100
shares, so the 10 contracts cover all 1,000 shares. The calls expire in about a
month, and each month has four steps:

1. The fund's **starting wealth** is its shares plus its cash, before the fund
   sells the calls.
2. The premium goes into the cash, and the cash earns the risk-free rate over
   the month.
3. At expiration, the calls are exercised if the share price is above the
   strike. The fund sells its shares to the call buyers at the strike and buys
   the same number of new shares at the share price, so the fund's cash falls by the
   difference. If the share price is at or below the strike, the calls expire
   worthless.
4. The fund's **ending wealth** is its shares plus its cash. If the cash is
   below zero, the fund has borrowed at the risk-free rate.

The fund's **wealth ratio** for the month is its ending wealth divided by its
starting wealth. We compare the fund with **holding the shares**: the same
shares and the same opening cash, with no calls sold.

For example, suppose the fund holds 1,000 shares at 100 USD/share and 5,000 USD
of cash. The fund sells 10 call contracts with a strike of 102 USD/share for a
premium of 0.87 USD/share on each of the 1,000 shares, so 870 USD goes into the
fund's cash. The cash grows by a factor of 1.00345 over the month.

| Share price at expiration (USD/share) | Fund's ending cash (USD) | Fund's wealth ratio | Holding's wealth ratio |
|--:|--:|--:|--:|
| 99.66 | 5,890.25 | 1.0052 | 0.9969 |
| 110.00 | −2,109.75 | 1.0275 | 1.0954 |

If the share price falls to 99.66 USD/share, the calls expire worthless. The
fund keeps the 870 USD premium, so the fund's wealth ratio is above the wealth
ratio of holding the shares.

If the share price rises to 110 USD/share, the calls are exercised. The fund
sells its 1,000 shares to the call buyers at 102 USD/share and buys 1,000 new
shares at 110 USD/share. The fund pays 8 USD/share more than the fund receives,
8,000 USD in all, and the fund's cash falls below zero. The fund gives up the
gain above the strike, so the fund's wealth ratio is below the wealth ratio of
holding the shares.

**Growth rate.** PS5 measures performance by the growth rate, in 1/yr. To
compute the growth rate, divide final wealth by initial wealth, take the natural
log of the result, and divide by the time in years. The `growth_rate` function
gets the same number by adding the logs of the monthly wealth ratios and
dividing by the time in years. The fund **beats** holding the shares when the
fund's growth rate is higher than the growth rate of holding the shares.

## The data

PS5 uses the 203 option trades in [data/trades.csv](data/trades.csv). A
**trade** is a set of options on one ticker, all opened on one day, the **entry
date**, and all held until they expire about a month later, on the **expiration
date**. Each of the 29 tickers has seven trades, and each trade lasts 28 to 32
days. A ticker's **first trade** is its earliest trade, with an entry date of
April 13 or 15, 2026. A ticker's seventh trade has an expiration date of October
30 or November 6, 2026. Each trade usually starts on the day the previous trade
expires, and the [data notes](data/README.md) explain the two exceptions. PS5
uses two options from each trade:

- `short_call` is the call the fund sells. The call's delta is nearest 0.25,
  which puts the call's strike a few percent above the share price.
- `long_put` (Advanced) is the put the collar fund buys. The put's delta is
  nearest 0.10 in absolute value, which puts the put's strike below the share
  price.

The quotes come from the broker Alpaca's free-plan **indicative** feed, which
only approximates exchange quotes. The graded results use each option's **mid
price**, halfway between the quoted bid and ask. The report also shows the
fund's growth rate when the fund sells each call at the bid. The difference
between that growth rate and the growth rate at the mid price is an estimate of
the trading cost.

**Benchmarks.** Each ticker has three benchmarks. Each benchmark runs from the
entry date of the ticker's first trade to the expiration date of the ticker's
seventh trade:

- **Holding the shares** keeps the fund's shares and opening cash and sells no
  calls.
- **SPY** is bought at its closing price on the first of those two dates and
  sold at its closing price on the second.
- **Cash** earns the risk-free rate, based on the 13-week Treasury bill yield of
  3.76% per year, the same rate as PS4.

**Simplifications.** PS5 makes these assumptions:

- The fund can borrow any amount at the risk-free rate.
- The fund sells a call every month, even when the strike is below the price
  the fund paid for its shares.
- Every call is held to expiration and settled at the closing share price on
  the expiration date. The calls are American, so a buyer could exercise a call
  early, but PS5 assumes that no buyer does.
- There are no commissions or taxes. The fund, holding the shares, and SPY
  receive no dividends, and their growth rates use closing prices only.

## Study 1: What does the model predict?

The **model** is a simulation of each ticker's fund over seven months. The
model takes four values from the ticker's first trade:

- The **share price** on the entry date. Every simulated path starts at this
  price.
- The **number of days** to expiration. Every simulated month has this many days.
- The **call's strike divided by the share price**. Each simulated month, the
  fund's target strike is this number times that month's share price.
- The **call's implied volatility**, the volatility at which a pricing model
  matches the option's market price.

For example, AAPL's first trade has an entry date of April 13, 2026, a share
price of 259.13 USD/share, and a call with a strike of 275 USD/share that
expires in 32 days. The simulated AAPL paths start at 259.13 USD/share, each simulated month has 32 days.

Options are sold only at certain strikes, called the **listed strikes**. In the
model, each ticker's listed strikes are evenly spaced, and the fund sells the
lowest listed strike at or above a target. The
[companion](docs/PS5-Mathematical-Companion.pdf) explains the listed strikes.

- **Share prices** follow geometric Brownian motion for seven months on 10,000
  simulated paths. The drift and volatility are estimated from the **training
  data**, the last 253 daily closing prices before the first trade's entry date.
  None of those prices fall inside the seven months the fund runs.
- **Premiums** come from your `call_premium` function, every month on every
  path. The report runs the model twice, and each run uses one volatility for
  all seven months and all paths. The first run uses the historical volatility,
  estimated from the training data. The second run uses the implied volatility
  of the call in the first trade. Neither volatility is updated as the simulated
  months pass.

Complete these functions, which follow Tasks 2 and 3 of the covered call fund
example:

1. **`call_premium`** returns the premium of one month's call. Build one short
   American call with the course `build` function and
   `MyAmericanCallContractModel`. Then price the call with the course
   `binomial_premium` function on a 60-step tree.
2. **`covered_call_month`** runs one month of the fund and returns the fund's
   wealth ratio and ending cash. The report passes the ending cash in as the
   next month's starting cash.
3. **`growth_rate`** returns the growth rate from a list of wealth ratios and
   the time in years.

Run the checker, read these tables in `results/Report.md`, and answer
Question 1:

| Table | What it shows |
|:--|:--|
| **Premiums: model and market** | For each ticker's first trade, the premium from your `call_premium` function at each volatility, next to the call's mid price in the data. |
| **The fund and holding the shares in the model** | Averages over the tickers: the mean growth rate and the probability of a negative growth rate for the fund and for holding the shares, the probability that the fund beats holding the shares, and the probability that the fund's cash is negative at the end of at least one month. |
| **Strike choice in the model** | The same fund on the same simulated paths, with target strikes of 1.00, 1.02, 1.05, and 1.10 times the share price. |

## Study 2: What happened?

You write no new code for this study. The report now runs your
`covered_call_month` and `growth_rate` functions on each ticker's seven trades
in the data. Each month, the fund sells calls at the strike and mid price of
that trade's `short_call`. The share prices at the start and end of the month
are the closing prices on the entry date and the expiration date. The fund's
cash carries over from one month to the next.

Rerun the checker, read these tables, and answer Question 2:

| Table | What it shows |
|:--|:--|
| **Growth rates and benchmarks** | The average, median, lowest, and highest growth rate over the tickers for the fund, the fund selling at the bid, holding the shares, SPY, and cash, and how many funds beat holding the shares. |
| **Each ticker** | The number of months the calls were exercised ("called away"), the number of months that ended with negative cash, the average premium, the growth rates of the fund and of holding the shares, and whether the fund beat holding the shares. |
| **Simulation versus real** | For each ticker, the fraction of simulated paths on which the fund beat holding the shares, whether the fund beat holding the shares on the trades in the data, the fund's growth rate minus the growth rate of holding the shares on those trades, and the percentage of simulated paths on which that difference was at or below the difference on the trades in the data. |

For **Simulation versus real**, the report runs a second simulation of each
ticker's fund. Only the share prices are simulated. Each of the ticker's seven
trades keeps its number of days, its strike divided by the share price at
entry, and its call's implied volatility, and the days between trades stay the
same. Each simulated call has the lowest listed strike at or above its target,
and the call's premium comes from the binomial tree at the call's implied
volatility, not from the mid price in the data.

## Study 3: What can we conclude?

Answer Question 3. Compare the growth rate of the fund with the growth rates of
holding the shares, SPY, and cash. Then explain why 29 tickers over the same
seven months are weaker evidence than 29 separate seven-month periods would be.
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
   expiration and does not exercise early.
2. **`collar_month`** runs one month of the collar fund and returns the
   collar fund's wealth ratio and ending cash. The call's premium minus the
   put's premium goes into the cash, and the cash earns the risk-free rate over
   the month. The calls' payoff is then paid from the cash, and the puts' payoff
   is added to the cash. The fund's calls and puts each cover all of the fund's
   shares.

Rerun the checker. The Study 1 tables now include the collar fund in the model.
The **Advanced: the collar fund** table shows, for each ticker, the number of
months the put paid, the number of months the calls were exercised, the put's
average cost, and the growth rates of the collar fund, the covered call fund,
and holding the shares. Answer Question 3, including part c.

## Check and submit your work

1. Save your code and answers, and run the checker one more time:

   ```text
   julia --project=. --startup-file=no check_submission.jl
   ```

   The checker flags unanswered questions and writes `MANIFEST.txt`.
2. ZIP the whole PS5 folder as `CHEME-5660-PS5-<your netid>.zip`.
3. Upload the ZIP to the PS5 assignment on Canvas.
