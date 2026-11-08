# Build data/strike_increments.csv: the spacing of each ticker's listed strikes, which the
# PS5 model uses to put every simulated strike on a listed strike.
#
# Usage, from the PS5 folder:
#   julia --project=. --startup-file=no instructor/build_strike_increments.jl <options-archive-dir>
#
# <options-archive-dir> is the unpacked course options archive (the `options_eod` artifact of the
# course repository), with one `<TICKER>.csv.gz` chain panel per ticker. For each trade in
# data/trades.csv, the script takes the strikes listed on the entry date for the trade's
# expiration, calls from the share price S0 to 1.15*S0 and puts from 0.85*S0 to S0 (the model
# rounds call targets up and put targets down), and records the spacing between neighboring
# strikes. A ticker's increment is its most common spacing over all of its trades and both sides
# (ties go to the smaller spacing). Rerun it whenever data/trades.csv is rebuilt.
using CSV, DataFrames, Dates

# checks -
length(ARGS) == 1 || error("usage: julia --project=. instructor/build_strike_increments.jl <options-archive-dir>");
const ARCHIVE = ARGS[1];
const ROOT = normpath(joinpath(@__DIR__, ".."));
const BAND = 0.15; # calls from S0 to (1 + BAND)*S0 and puts from (1 - BAND)*S0 to S0 count

# initialize -
trades = CSV.read(joinpath(ROOT, "data", "trades.csv"), DataFrame);
rows = NamedTuple[];

# main loop: one ticker at a time -
for ticker in sort(unique(String.(trades.ticker)))

    # This ticker's option chain, and the count of each spacing -
    chain = CSV.read(joinpath(ARCHIVE, ticker * ".csv.gz"), DataFrame);
    counts = Dict{Float64,Int}(); # spacing (USD) => number of times it appears

    # one trade at a time -
    for t in eachrow(trades[trades.ticker .== ticker, :])

        # The contracts listed on the trade's entry date for the trade's expiration -
        listed = chain[(chain.date .== t.entry) .& (chain.expiration .== t.expiration), :];

        # The strikes near the share price, for calls and for puts -
        sides = (
            Float64[k for k in listed[listed.type .== "call", :strike] if t.S0 <= k <= (1 + BAND) * t.S0],
            Float64[k for k in listed[listed.type .== "put", :strike] if (1 - BAND) * t.S0 <= k <= t.S0]);

        # Count the spacing between each pair of neighboring strikes -
        for side in sides
            strikes = sort(unique(side));
            for (a, b) in zip(strikes[1:end-1], strikes[2:end])
                spacing = round(b - a; digits = 3);
                counts[spacing] = get(counts, spacing, 0) + 1;
            end
        end
    end

    # A ticker with no listed strikes cannot be given an increment -
    if isempty(counts)
        error("no listed strikes found for $(ticker)");
    end

    # The most common spacing; ties go to the smaller spacing -
    best = maximum(values(counts));
    increment = minimum(k for (k, n) in counts if n == best);
    push!(rows, (ticker = ticker, strike_increment = increment));
end

# write -
CSV.write(joinpath(ROOT, "data", "strike_increments.csv"), DataFrame(rows));
println("wrote data/strike_increments.csv for $(length(rows)) tickers");
