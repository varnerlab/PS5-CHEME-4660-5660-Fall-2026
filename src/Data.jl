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

    # The leg's own implied volatility, or the at-the-money value when the leg has none -
    value = row[Symbol(role, "_iv")];
    return ismissing(value) ? Float64(row.atm_iv) : Float64(value);
end

"""
    load_strike_increments(path::AbstractString, tickers) -> Dict{String,Float64}

Read the spacing of each ticker's listed strikes, `data/strike_increments.csv`.

### Arguments

- `path`: Location of the file, with the columns `ticker` and `strike_increment` (USD).
- `tickers`: The tickers that need an increment.

### Returns

- A `Dict` from ticker to its strike increment (USD). Throws an `ArgumentError`
  when the columns differ, an increment is not positive, or a ticker is missing.
"""
function load_strike_increments(path::AbstractString, tickers)::Dict{String,Float64}

    # Read the file and check its columns -
    table = CSV.read(path, DataFrame; stringtype = String);
    names(table) == ["ticker", "strike_increment"] ||
        throw(ArgumentError("The strike increments must have the columns ticker and strike_increment."));

    # Check each increment, and that every ticker has one -
    increments = Dict{String,Float64}();
    for row in eachrow(table)
        (row.strike_increment isa Real && isfinite(row.strike_increment) && row.strike_increment > 0) ||
            throw(ArgumentError("The strike increment of $(row.ticker) must be a positive number."));
        increments[String(row.ticker)] = Float64(row.strike_increment);
    end
    for ticker in tickers
        haskey(increments, ticker) || throw(ArgumentError("The strike increments have no row for $(ticker)."));
    end
    return increments;
end

"""
    _grid_position(price::Float64, increment::Float64) -> Float64

Return the position of a price on a strike grid, in units of `increment`. A price within rounding
error of a grid line is rounded to that grid line, so that an exact multiple of the increment is not
pushed to the next strike.
"""
function _grid_position(price::Float64, increment::Float64)::Float64

    # The position on the grid, and the nearest grid line -
    q = price / increment;
    r = round(q);

    # Round to the grid line when the difference is only rounding error -
    return abs(q - r) <= 1e-9 * max(1.0, abs(q)) ? r : q;
end

"""
    listed_call_strike(target::Float64, increment::Float64) -> Float64

The smallest strike on a grid of listed strikes `increment` apart that is at or
above `target` (USD/share), as in the course example. For a call, this keeps the
strike at or beyond the target.
"""
listed_call_strike(target::Float64, increment::Float64)::Float64 =
    increment * ceil(_grid_position(target, increment));

"""
    listed_put_strike(target::Float64, increment::Float64) -> Float64

The largest strike on a grid of listed strikes `increment` apart that is at or
below `target` (USD/share). For a put, this keeps the strike at or beyond the
target. When `target` is below one increment, it returns one increment, the
lowest listed strike.
"""
listed_put_strike(target::Float64, increment::Float64)::Float64 =
    increment * max(floor(_grid_position(target, increment)), 1.0);

"""
    ticker_rolls(trades::DataFrame, parameters::DataFrame, increments::AbstractDict) -> Vector{NamedTuple}

Arrange each ticker's trades, in order of entry, into the fund's monthly roll.

### Arguments

- `trades`: The trade table, from `load_trade_table`.
- `parameters`: The trailing drift and volatility of each trade (`data/parameters.csv`).
- `increments`: The spacing of each ticker's listed strikes, from `load_strike_increments`.

### Returns

One `NamedTuple` per ticker, in alphabetical order, with:

- `ticker`, `group`, `first_entry`, `last_expiration`, `T`, the years from
  the first entry to the last expiration (calendar days / 365), and
  `strike_increment`, the spacing of the ticker's listed strikes (USD).
- `months`: one `NamedTuple` per trade with `entry`, `expiration`, `days`,
  `S_start` and `S_end` (the closes on the entry and expiration dates,
  USD/share), the sold call's strike `K_call`, prices `call_mid` and
  `call_bid`, and implied volatility `call_iv`, and the collar put's strike
  `K_put`, prices `put_mid` and `put_ask`, and implied volatility `put_iv`,
  and `gap_days`, the calendar days from the previous trade's expiration to
  this entry (0 for the first trade, and usually 0), when the fund holds only
  its shares and cash.
- `plan`: what the fund knew on its first entry date: `S0`, the first trade's
  time to expiration `term` (years, `days / 365`), the strikes as
  multiples of the share price (`call_moneyness`, `put_moneyness`), the
  implied volatilities `call_iv` and `put_iv`, the trailing drift `μ` and
  volatility `σ̂`, and the premiums as fractions of the share price
  (`call_fraction`, `put_fraction`).
"""
function ticker_rolls(trades::DataFrame, parameters::DataFrame, increments::AbstractDict)::Vector{NamedTuple}

    # Initialize -
    by_id = Dict(p.trade_id => p for p in eachrow(parameters));
    rolls = NamedTuple[];

    # main loop: one ticker at a time, in alphabetical order -
    for ticker in sort(unique(trades.ticker))

        # This ticker's trades, in order of entry -
        rows = sort(trades[trades.ticker .== ticker, :], :entry);
        months = NamedTuple[];
        for (j, row) in enumerate(eachrow(rows))

            # The calendar days since the previous trade expired; trades must not overlap -
            gap_days = j == 1 ? 0 : Dates.value(row.entry - rows[j-1, :expiration]);
            gap_days >= 0 || throw(ArgumentError("$(ticker): a trade enters before the previous one expires."));

            # Keep the fields of this trade that the fund uses -
            push!(months, (entry = row.entry, expiration = row.expiration, days = row.days, gap_days = gap_days,
                S_start = row.S0, S_end = row.ST,
                K_call = row.short_call_K, call_mid = row.short_call_mid, call_bid = row.short_call_bid,
                call_iv = leg_iv(row, :short_call),
                K_put = row.long_put_K, put_mid = row.long_put_mid, put_ask = row.long_put_ask,
                put_iv = leg_iv(row, :long_put)));
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

        # The trades and the gaps between them must cover the whole roll -
        first_entry = months[1].entry;
        last_expiration = months[end].expiration;
        total_days = Dates.value(last_expiration - first_entry);
        sum(m.days + m.gap_days for m in months) == total_days ||
            throw(ArgumentError("$(ticker): the trade days and the gaps do not add up to the roll's length."));

        # Add this ticker's roll to the list -
        push!(rolls, (ticker = ticker, group = first_row.group, first_entry = first_entry,
            last_expiration = last_expiration, T = total_days / PS5_CALENDAR_DAYS,
            strike_increment = increments[ticker], months = months, plan = plan));
    end

    return rolls;
end
