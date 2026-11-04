# PS5 grading rules

Your selected track is graded out of **4**. An Advanced score of 4, confirmed
by the teaching team, also earns **one Magic Point**, at most one for PS5.
Select your track in `TRACK.txt`.

| Score | Checks passed | Other requirements |
|:--:|:--|:--|
| 0 | None, or the selected source file cannot load | — |
| 1 | At least one, but no more than half | — |
| 2 | More than half, but fewer than all | — |
| 3 | All | At least one requirement for a 4 (below) is not met |
| 4 | All | Every requirement for a 4 is met |

The checks are the public checks that `check_submission.jl` runs. Standard has
**12 checks**, four for each function. Advanced has **20 checks**: the same 12
plus four for each Advanced function, so completing only the shared work earns
at most 2. Standard cutoffs are 1–6 checks for score 1 and 7–11 for score 2;
Advanced cutoffs are 1–10 and 11–19. On either track, passing every check
gives a 3 or a 4, depending on the requirements for a 4.

Checks run separately, so an unfinished function does not block the others.
Failed checks do not cause a Frozen Zero: a readable ZIP with attempted work by
the deadline still qualifies for revisions.

## Requirements for a 4

- **Pricing:** Price each option with the course `build` function and the
  American contract types, `MyAmericanCallContractModel` (and, for Advanced,
  `MyAmericanPutContractModel`), and the course `binomial_premium` function
  with `method = :crr` and `h = 60`. Use the share price, strike, time,
  volatility, and rate passed in; do not hard-code them.
- **Wealth ratio:** Compute the covered call fund's monthly wealth ratio from
  the share prices, the strike, and the premium grown by the accumulation
  factor, as in the course example. Do not change the arguments.
- **Growth rate:** Add the logs of the wealth ratios and divide by the time in
  years. Leave the ratios unchanged.
- **Advanced:** Price the put and compute the collar fund's monthly wealth
  ratio with the same rules, and complete the Advanced copies of the three
  Standard functions.
- **Documentation:** Keep the supplied docstrings. Document each helper's
  purpose, inputs, and output, and comment non-obvious steps. Load helper
  files under `src` through `Include.jl`.
- **Written work:** Answer every lettered part of all three questions in the
  selected response file with the requested numbers, units, and reasoning.
  Include the prediction and its reconsideration. Cite selected values rather
  than reproducing the tables. Give growth rates in 1/yr. Distinguish the
  model's promise (Study 1) from what happened (Study 2), and use the mid-price
  results as the headline and the bid results only as a comparison. For
  Advanced, compare the collar fund with the covered call fund and the shares.
- **Finished work:** Remove completed TODOs and starter errors from the
  selected track's source and response files. Leave the other track unchanged.

We do not require the fund to beat the shares, the model to match the
outcomes, or your prediction to be right. We assess the calculations and your
interpretation.

## How we check submissions

As in PS3 and PS4, grading copies the selected source and response files, custom
helpers under `src`, `Include.jl`, and `TRACK.txt` into a fresh copy of the
assignment. Edits to any other file, such as the supplied data,
`config/defaults.toml`, the files in `test`, or the checker, are not used.
Helper files must not define functions with the same names as the track
functions or course functions such as `build` and `binomial_premium`.

The checker gives feedback; the teaching team assigns the grade. For work
that passes every check, the teaching team assigns 3 or 4 after reading the
documentation and answers.

## Initial submission and revisions

PS5 is released **November 8, 2026**. Submit a readable ZIP with attempted
work by **November 22, 2026 at 11:59 PM ET**. A missing, empty, or unreadable
submission receives a **Frozen Zero** and cannot be revised for credit or
earn a Magic Point. Incomplete attempted work and failed checks qualify
for revisions.

After a qualifying initial submission, revisions are allowed until **December
19, 2026 at 11:59 PM ET**, with no limit on attempts. Use **New Attempt** on
the same Canvas assignment. Revisions have no late penalty, even if Canvas
labels them late. We keep your highest score, even if you change tracks. An
Advanced score of 4 confirmed through a revision also earns the one-time Magic
Point.

## Independent work

You may discuss ideas and use course materials, books, documentation, the
internet, and AI tools. Submit your own work. Do not share code or solutions.

The reference solution will be released after the initial deadline. Use it
to understand errors and debug your work, but do not copy it. Copying it
results in a score of 0 for PS5 that revisions cannot change. These rules
also apply to revisions.
