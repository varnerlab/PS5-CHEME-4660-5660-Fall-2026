# PS5 Advanced responses

**Central question:** Does a covered call fund beat holding the shares, and
what does it give up?

Write a few sentences for each lettered part, and label each part with its
letter. Cite numbers from `results/Report.md`, and give growth rates in 1/yr.
Put your answer between each question's `<!-- answer-N:start -->` and
`<!-- answer-N:end -->` markers, in place of the TODO.

## 1. What does the model predict?

**a. What do you predict?** Answer before you write any code; accuracy is not
graded. On how many of the 29 tickers will the fund grow faster than holding
the shares over the seven months? Will the market premiums (the calls' mid
prices in the data) be larger or smaller than the model's premiums at the
historical volatility? Will the collar fund
grow faster or slower than the covered call fund? Why?

**b. What does the fund give up in the model?** In **The fund and holding the
shares in the model**, use the row **Fund, implied volatility**. Compare this
row with the row for holding the shares: the average mean growth rate and the
average probability of a negative growth rate. What is the average probability
that the fund beats holding the shares? Then use **Strike choice in the model**:
how do these numbers change as the target strike rises from 1.00 to 1.10 times
the share price, and why?

**c. Which volatility gives premiums closer to the market premiums?** In
**Premiums: model and market**, which volatility gives premiums closer to the
market premiums, on average? Name one ticker where the premium at the historical
volatility is far from the market premium. Explain the difference using that
ticker's historical volatility and implied volatility.

<!-- answer-1:start -->
TODO: Answer parts a, b, and c.
<!-- answer-1:end -->

## 2. What happened?

**a. Why did the fund beat holding the shares on some tickers but not on
others?** On how many tickers did the fund beat holding the shares, and on how
many did the model expect the fund to beat holding the shares? The sentence
above the **Simulation versus real** table gives both numbers. Using **Each
ticker**, how do the tickers where the fund beat holding the shares differ from
the tickers where the fund did not? Cite the holding growth rates and the months
called away (the months the calls were exercised).

**b. On which tickers was the result far from the simulated results?** In
**Simulation versus real**, name the two tickers whose model percentile is
nearest 0% or 100%. Using their holding growth rates in **Each ticker**, how did
the share prices of those two tickers differ from what the model's drift and
volatility would produce? What does that say about the drift and volatility
estimated from the training data? The model prices each simulated
call at the call's implied volatility, not at the mid price in the data. Could
the difference between those two premiums also explain those percentiles?

<!-- answer-2:start -->
TODO: Answer parts a and b.
<!-- answer-2:end -->

## 3. What can we conclude?

**a. Did the fund beat holding the shares?** In **Growth rates and benchmarks**,
compare the fund with holding the shares, SPY, and cash: the average, median,
lowest, and highest growth rate. What did the fund give up by selling calls,
and what did the fund receive? How much lower is the fund's average growth rate
when the fund sells at the bid instead of the mid price? Was your prediction in
part 1a right?

**b. Why are seven months weak evidence?** All 29 funds ran over the same
seven months. Using the SPY row, describe how the stock market moved over these
dates. Give two reasons why one seven-month period shared by all 29 funds is
weaker evidence than 29 separate seven-month periods would be.

**c. Did buying the puts raise the fund's growth rate?** In **Advanced: the
collar fund**, how many months did a put pay in total over the tickers, and what
was the average put cost? Compare the collar fund's growth rates with the growth
rates of the covered call fund and of holding the shares, and with the row
**Collar fund, implied volatility** in **The fund and holding the shares in the
model**. In what kind of seven-month period would the collar fund have a higher
growth rate than the covered call fund?

<!-- answer-3:start -->
TODO: Answer parts a, b, and c.
<!-- answer-3:end -->
