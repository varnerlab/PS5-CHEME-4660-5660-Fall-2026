# Build data/trades.csv, data/parameters.csv, and data/benchmark.csv from the course options
# archive. The selection code is in instructor/TradeSelection.jl, and every value that selects a
# trade, such as the delta of the call the fund sells, is in instructor/trade_selection.toml.
#
# Usage, from the PS5 folder:
#   julia --project=. --startup-file=no instructor/build_trades.jl <options-archive-dir> [output-folder]
#
# <options-archive-dir> is the unpacked course options archive (the `options_eod` artifact of the
# course repository, release data-options-eod-2026-11-06), with underlying.csv and one
# <TICKER>.csv.gz chain file per ticker. The default output folder is data/. Pass another folder to
# compare a build with the supplied files.
# After rebuilding data/, run instructor/build_strike_increments.jl and update the SHA-256 hashes in
# data/README.md.
using CSV, DataFrames, Dates, Statistics, TOML, VLQuantitativeFinancePackage

# checks -
1 <= length(ARGS) <= 2 || error("usage: julia --project=. instructor/build_trades.jl <options-archive-dir> [output-folder]");
const ROOT = normpath(joinpath(@__DIR__, ".."));
include(joinpath(@__DIR__, "TradeSelection.jl"));

# initialize: the archive, the output folder, the selection settings, and the market benchmark -
archive = ARGS[1];
output_folder = joinpath(ROOT, "data");
if length(ARGS) == 2
    output_folder = ARGS[2];
end
settings = load_selection_settings(joinpath(@__DIR__, "trade_selection.toml"));
benchmark_ticker = TOML.parsefile(joinpath(ROOT, "config", "defaults.toml"))["benchmark_ticker"];

# The archive must end on the date in the settings -
underlying = archive_underlying(archive);
archive_end = maximum(underlying.date);
if archive_end != settings.archive_end
    error("the options archive ends on $(archive_end), but trade_selection.toml says $(settings.archive_end)");
end

# Select the trades, and estimate the drift and volatility before each entry date -
built = build_trade_table(settings, archive);
trades = built.trades;
history = price_history(settings.tickers, underlying);
parameters = trade_parameters(trades, history, settings);
benchmark = archive_closes(benchmark_ticker, underlying);

# Every entry and expiration date needs a benchmark close -
if !issubset([trades.entry; trades.expiration], benchmark.date)
    error("a trade's entry or expiration date has no $(benchmark_ticker) close in the archive");
end

# write -
mkpath(output_folder);
CSV.write(joinpath(output_folder, "trades.csv"), trades);
CSV.write(joinpath(output_folder, "parameters.csv"), parameters);
CSV.write(joinpath(output_folder, "benchmark.csv"), benchmark);

# Report what was built, and why any candidate trade was skipped -
println("wrote $(nrow(trades)) trades to $(output_folder), through the archive's last session, $(archive_end)");
println("$(length(built.log)) candidate entries were skipped, and the quote screen moved $(sum(trades.screened)) legs");
for line in built.log
    println(line);
end
