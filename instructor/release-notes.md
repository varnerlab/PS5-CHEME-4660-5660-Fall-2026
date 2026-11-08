# CHEME 5660 Problem Set 5

This is the Fall 2026 student release of PS5: *Does a Covered Call Fund Beat Holding Its Shares?*

This release replaces `ps5-cheme-4660-5660-2026.1`. It rewrites the README, the questions, and the text of the report in plainer language. The data, the functions you complete, and the grading are unchanged, so work you started on the earlier release still counts.

Download **Source code (zip)** below, extract it, and begin with `README.md`. The release contains the starter code for both tracks, the trades and parameters for 29 tickers (stocks and exchange-traded funds, the PS4 data and one more trade on each ticker) and their listed strike increments, the mathematical companion, public tests, response files, the submission checker, and the grading rubric. The reference solutions are not included.

Set `TRACK.txt` to `standard` or `advanced`.
* __Standard__ runs a covered call fund, which owns shares and sells a call on them every month, first in a model of the share price and then on the 203 trades in the data, and compares it with holding the same shares and cash without selling calls.
* __Advanced__ adds a collar fund, which also buys a put each month, and compares the growth rate of the collar fund with the growth rates of the covered call fund and of holding the shares.

Write your prediction in Question 1a before you view any results.

Use **Julia 1.12.7** and follow the package setup in the README. `check_submission.jl` checks your code, prints the comparison report, and gives the instructions for building your ZIP.

The initial submission is due on Canvas by **11:59 PM ET on Sunday, November 22, 2026**. Eligible revisions are accepted until **December 19, 2026 at 11:59 PM ET**. An accepted Advanced score of 4 earns one Magic Point.
