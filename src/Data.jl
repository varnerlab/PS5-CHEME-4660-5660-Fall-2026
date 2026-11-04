# PS5 data: read the supplied trade table and arrange each ticker's trades into a monthly roll.
using CSV, DataFrames, Dates

# The six option legs recorded for every trade in data/trades.csv (the PS4 trade table).
# PS5 uses two of them: the fund sells `short_call`, and the Advanced collar buys `long_put`.
const PS5_ROLES = (:atm_call, :atm_put, :short_call, :short_put, :long_call, :long_put);

# Calendar days per year, for the time to expiration and the length of each roll.
const PS5_CALENDAR_DAYS = 365;

"""
    trade_columns() -> Vector{Pair{String,Type}}

List the columns of the trade table in order, with the type of each: `trade_id`,
`ticker`, `group`, `entry`, `expiration`, `days`, `S0`, `ST`, `atm_iv`, then
`<leg>_K`, `<leg>_bid`, `<leg>_ask`, `<leg>_mid`, `<leg>_iv`, and `<leg>_delta`
for each leg in `PS5_ROLES`, then `screened`. The implied volatility and delta
may be `missing`.
"""
function trade_columns()::Vector{Pair{String,Type}}

    # Trade columns -
    columns = Pair{String,Type}["trade_id" => Int, "ticker" => String, "group" => String,
        "entry" => Date, "expiration" => Date, "days" => Int, "S0" => Float64, "ST" => Float64,
        "atm_iv" => Float64];

    # Six columns for each leg -
    for role in PS5_ROLES
        push!(columns, "$(role)_K" => Float64);
        push!(columns, "$(role)_bid" => Float64);
        push!(columns, "$(role)_ask" => Float64);
        push!(columns, "$(role)_mid" => Float64);
        push!(columns, "$(role)_iv" => Union{Missing,Float64});
        push!(columns, "$(role)_delta" => Union{Missing,Float64});
    end

    push!(columns, "screened" => Int);
    return columns;
end

"""
    load_trade_table(path::AbstractString) -> DataFrame

Read the supplied trade table, `data/trades.csv`.

### Returns

- The trade table with the columns and types of `trade_columns()`. Throws an
  `ArgumentError` when the file's columns differ from the trade-table columns.
"""
function load_trade_table(path::AbstractString)::DataFrame

    # Read the file with the column types of the trade table -
    columns = trade_columns();
    table = CSV.read(path, DataFrame; stringtype = String, types = Dict(columns));

    # Check the column names and order -
    if names(table) != [name for (name, _) in columns]
        throw(ArgumentError("The file does not have the trade-table columns in the expected order."));
    end
    return table;
end

"""
    leg_iv(row, role::Symbol) -> Float64

The implied volatility of one leg, or the trade's at-the-money value `atm_iv`
when the leg's is missing.
"""
function leg_iv(row, role::Symbol)::Float64
    value = row[Symbol(role, "_iv")];
    return ismissing(value) ? Float64(row.atm_iv) : Float64(value);
end

"""
    ticker_rolls(trades::DataFrame, parameters::DataFrame) -> Vector{NamedTuple}

Arrange each ticker's trades, in order of entry, into the fund's monthly roll.

### Arguments

- `trades`: The trade table, from `load_trade_table`.
- `parameters`: The trailing drift and volatility of each trade (`data/parameters.csv`).

### Returns

One `NamedTuple` per ticker, in alphabetical order, with:

- `ticker`, `group`, `first_entry`, `last_expiration`, and `T`, the years from
  the first entry to the last expiration (calendar days / 365).
- `months`: one `NamedTuple` per trade with `entry`, `expiration`, `days`,
  `S_start` and `S_end` (the closes on the entry and expiration dates,
  USD/share), the sold call's strike `K_call`, prices `call_mid` and
  `call_bid`, and implied volatility `call_iv`, and the collar put's strike
  `K_put`, prices `put_mid` and `put_ask`, and implied volatility `put_iv`.
- `gaps`: the share-price ratios `S_start` of a trade over `S_end` of the one
  before, for the days between an expiration and the next entry (usually none).
- `plan`: what the fund knew on its first entry date: `S0`, the first trade's
  time to expiration `term` (years, `days / 365`), the strikes as
  multiples of the share price (`call_moneyness`, `put_moneyness`), the
  implied volatilities `call_iv` and `put_iv`, the trailing drift `μ` and
  volatility `σ̂`, and the premiums as fractions of the share price
  (`call_fraction`, `put_fraction`).
"""
function ticker_rolls(trades::DataFrame, parameters::DataFrame)::Vector{NamedTuple}

    # Initialize -
    by_id = Dict(p.trade_id => p for p in eachrow(parameters));
    rolls = NamedTuple[];

    for ticker in sort(unique(trades.ticker))

        # This ticker's trades, in order of entry -
        rows = sort(trades[trades.ticker .== ticker, :], :entry);
        months = NamedTuple[];
        for row in eachrow(rows)
            push!(months, (entry = row.entry, expiration = row.expiration, days = row.days,
                S_start = row.S0, S_end = row.ST,
                K_call = row.short_call_K, call_mid = row.short_call_mid, call_bid = row.short_call_bid,
                call_iv = leg_iv(row, :short_call),
                K_put = row.long_put_K, put_mid = row.long_put_mid, put_ask = row.long_put_ask,
                put_iv = leg_iv(row, :long_put)));
        end

        # The days between one expiration and the next entry, when the fund holds only shares -
        gaps = Float64[];
        for j in 2:length(months)
            if months[j].entry != months[j-1].expiration || months[j].S_start != months[j-1].S_end
                push!(gaps, months[j].S_start / months[j-1].S_end);
            end
        end

        # What the fund knew on its first entry date -
        first_row = rows[1, :];
        p = by_id[first_row.trade_id];
        plan = (S0 = first_row.S0, term = first_row.days / PS5_CALENDAR_DAYS,
            call_moneyness = first_row.short_call_K / first_row.S0,
            put_moneyness = first_row.long_put_K / first_row.S0,
            call_iv = leg_iv(first_row, :short_call), put_iv = leg_iv(first_row, :long_put),
            μ = Float64(p.μ), σ̂ = Float64(p.σ̂),
            call_fraction = first_row.short_call_mid / first_row.S0,
            put_fraction = first_row.long_put_mid / first_row.S0);

        first_entry = months[1].entry;
        last_expiration = months[end].expiration;
        push!(rolls, (ticker = ticker, group = first_row.group, first_entry = first_entry,
            last_expiration = last_expiration,
            T = Dates.value(last_expiration - first_entry) / PS5_CALENDAR_DAYS,
            months = months, gaps = gaps, plan = plan));
    end

    return rolls;
end
