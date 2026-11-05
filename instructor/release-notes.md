# CHEME 5660 Problem Set 5

This is the Fall 2026 student release of PS5: *Does a Covered Call Fund Beat Holding Its Shares?*

Download **Source code (zip)** below, extract it, and begin with `README.md`. The release contains the starter code for both tracks, the trades and parameters for 29 stocks and funds (the PS4 data) and their listed strike increments, the mathematical companion, public tests, response files, the submission checker, and the grading rubric. The reference solutions are not included.

Choose Standard or Advanced in `TRACK.txt`.
* __Standard__ runs a covered call fund, which owns shares and sells a call on them every month, first in a model of the share price and then on 174 real monthly calls, and compares it with holding the same shares and cash without selling calls.
* __Advanced__ adds a collar fund, which also buys a put each month, and asks whether that protection paid for itself.

Write your prediction in Question 1a before you view any results.

Use **Julia 1.12.7** and follow the package setup in the README. `check_submission.jl` checks your code, prints the comparison report, and gives the instructions for building your ZIP.

The initial submission is due on Canvas by **11:59 PM ET on Sunday, November 22, 2026**. Eligible revisions are accepted until **December 19, 2026 at 11:59 PM ET**. An accepted Advanced score of 4 earns one Magic Point.
