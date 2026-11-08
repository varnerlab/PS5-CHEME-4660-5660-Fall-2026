# PS5 Standard responses

**Central question:** Does a covered call fund beat holding the shares, and
what does it give up?

Write a few sentences for each lettered part, and label each part with its
letter. Cite numbers from `results/Report.md`, and give growth rates in 1/yr.
Put your answer between each question's `<!-- answer-N:start -->` and
`<!-- answer-N:end -->` markers, in place of the TODO.

## 1. What does the model promise?

**a. What do you predict?** Answer before you write any code; accuracy is not
graded. On how many of the 29 tickers will the fund grow faster than holding
the shares over the seven months? Will the market's premiums be larger or smaller
than the model's premiums at the historical volatility? Why?

**b. What does the fund give up?** In **The fund and holding the shares in the
model**, use the fund with calls priced at implied volatility. Compare the fund
with holding the shares: the average mean growth rate and the probability of a
negative growth rate. How likely is the fund to beat holding? Then use **Strike
choice in the model**: how does a farther strike change these numbers, and why?

**c. Which volatility prices the call better?** In **Premiums: model and
market**, which volatility gives premiums closer to the market's, on average?
Name one ticker where the premium at the historical volatility is far from the
market's. Explain the gap using that ticker's two volatilities.

<!-- answer-1:start -->
TODO: Answer parts a, b, and c.
<!-- answer-1:end -->

## 2. What happened?

**a. Why did the fund win on some tickers and lose on others?** On how many
tickers did the fund beat holding the shares, and how many did the model expect?
Using **Each ticker**, what separates the tickers where the fund won from those
where it lost? Cite the growth rates of holding and the months called away.

**b. Which outcomes did the model not expect?** Name the two tickers whose outcomes
were rarest under the model (percentile nearest 0% or 100%). What did their
shares do that the model did not expect? What does that say about the drift and
volatility the model took from the year before? The model prices each simulated
call at its implied volatility, not at the market's mid price. Could this
difference also explain those outcomes?

<!-- answer-2:start -->
TODO: Answer parts a and b.
<!-- answer-2:end -->

## 3. What can we conclude?

**a. Did the fund beat holding the shares?** In **Growth rates and benchmarks**,
compare the fund with holding the shares, SPY, and cash: the average, median,
lowest, and highest growth rate. What did the fund give up, and what did it get?
How much did selling at the bid cost? Did your prediction hold?

**b. Why are seven months weak evidence?** All 29 funds ran over the same
seven months. Using the SPY row, describe the market over these dates. Give two
reasons why one shared period is weaker evidence than 29 separate seven-month
periods would be.

<!-- answer-3:start -->
TODO: Answer parts a and b.
<!-- answer-3:end -->
