# PS5 assignment conventions

- Keep the README and response files free of equations, LaTeX commands, and
  math delimiters. Explain the task in plain language and link to the
  mathematical companion. Mathematics goes in
  `docs/PS5-Mathematical-Companion.tex`.
- Organize the assignment around its central question: does a covered call
  fund beat holding the shares, and what does it give up? Study 1 is the
  model's promise, Study 2 what happened, Study 3 the conclusion. Preserve the
  agreed Standard (covered call fund) and Advanced (collar fund) scope.
- Every student function copies a cell of the course examples "A Covered Call
  Fund on SPY" or "A Protective Collar on SPY" (L11b) and uses course types.
  No student data wrangling.
- The data are the PS4 files, unchanged. Default fill is mid; the bid is a
  comparison row only. The README states the quotes are Alpaca's indicative
  free-plan feed and never calls them real bid/ask prices.
- Performance is a growth rate, g = (1/T) ln(W_T/W_0) in 1/yr, never a
  return. Benchmarks: the shares, SPY (`benchmark_ticker`), and cash over each
  ticker's own dates.
- Put mathematical details in the companion and its compiled PDF, using the
  supplied course lecture styling. Render and inspect changed slides before
  delivery. Rebuild with `make -C docs`.
- Keep instructor solutions and numerical results out of the student release.
