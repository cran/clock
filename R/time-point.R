is_time_point <- function(x) {
  inherits(x, "clock_time_point")
}

check_time_point <- function(x, ..., arg = caller_arg(x), call = caller_env()) {
  check_inherits(x, what = "clock_time_point", arg = arg, call = call)
}

# ------------------------------------------------------------------------------

time_point_clock_attribute <- function(x) {
  attr(x, "clock", exact = TRUE)
}

time_point_precision_attribute <- function(x) {
  attr(x, "precision", exact = TRUE)
}

time_point_duration <- function(x, retain_names = FALSE) {
  if (retain_names) {
    names <- clock_rcrd_names(x)
  } else {
    names <- NULL
  }
  precision <- time_point_precision_attribute(x)
  new_duration_from_fields(x, precision, names)
}

# ------------------------------------------------------------------------------

#' @export
format.clock_time_point <- function(
  x,
  ...,
  format = NULL,
  locale = clock_locale()
) {
  check_clock_locale(locale)

  clock <- time_point_clock_attribute(x)
  precision <- time_point_precision_attribute(x)

  if (is_null(format)) {
    format <- time_point_precision_format(precision)
  }

  labels <- locale$labels
  decimal_mark <- locale$decimal_mark

  out <- format_time_point_cpp(
    fields = x,
    clock = clock,
    format = format,
    precision_int = precision,
    month = labels$month,
    month_abbrev = labels$month_abbrev,
    weekday = labels$weekday,
    weekday_abbrev = labels$weekday_abbrev,
    am_pm = labels$am_pm,
    decimal_mark = decimal_mark
  )

  names(out) <- clock_rcrd_names(x)

  out
}

time_point_precision_format <- function(precision) {
  precision <- precision_to_string(precision)

  switch(
    precision,
    day = "%Y-%m-%d",
    hour = "%Y-%m-%dT%H",
    minute = "%Y-%m-%dT%H:%M",
    second = "%Y-%m-%dT%H:%M:%S",
    millisecond = "%Y-%m-%dT%H:%M:%S",
    microsecond = "%Y-%m-%dT%H:%M:%S",
    nanosecond = "%Y-%m-%dT%H:%M:%S",
    abort("Unknown precision.")
  )
}

# ------------------------------------------------------------------------------

time_point_parse <- function(
  x,
  format,
  precision,
  locale,
  clock,
  ...,
  error_call = caller_env()
) {
  check_dots_empty0(...)
  check_character(x, call = error_call)

  if (is_null(format)) {
    format <- time_point_precision_format(precision)
  }

  check_clock_locale(locale, call = error_call)

  labels <- locale$labels
  mark <- locale$decimal_mark

  time_point_parse_cpp(
    x,
    format,
    precision,
    clock,
    labels$month,
    labels$month_abbrev,
    labels$weekday,
    labels$weekday_abbrev,
    labels$am_pm,
    mark
  )
}

# ------------------------------------------------------------------------------

#' @export
print.clock_time_point <- function(x, ..., max = NULL) {
  clock_print(x, max)
}

# - Each subclass implements a `format()` method
# - Unlike vctrs, don't use `print(quote = FALSE)` since we want to match base R
#' @export
obj_print_data.clock_time_point <- function(x, ..., max) {
  if (vec_is_empty(x)) {
    return(invisible(x))
  }

  x <- max_slice(x, max)

  out <- format(x)

  # Pass `max` to avoid base R's default footer
  print(out, max = max)

  invisible(x)
}

#' @export
obj_print_footer.clock_time_point <- function(x, ..., max) {
  clock_print_footer(x, max)
}

# Align left to match pillar_shaft.Date
# @export - lazy in .onLoad()
pillar_shaft.clock_time_point <- function(x, ...) {
  out <- format(x)
  pillar::new_pillar_shaft_simple(out, align = "left")
}

# ------------------------------------------------------------------------------

#' @export
vec_proxy.clock_time_point <- function(x, ...) {
  .Call(`_clock_clock_rcrd_proxy`, x)
}

#' @export
vec_restore.clock_time_point <- function(x, to, ...) {
  .Call(`_clock_time_point_restore`, x, to)
}

# ------------------------------------------------------------------------------

time_point_ptype <- function(x, ..., type = c("full", "abbr")) {
  check_dots_empty0(...)
  type <- arg_match0(type, values = c("full", "abbr"))

  clock <- time_point_clock_attribute(x)
  clock <- clock_to_string(clock)

  precision <- time_point_precision_attribute(x)
  precision <- precision_to_string(precision)

  name <- switch(
    type,
    full = switch(
      clock,
      sys = "sys_time",
      naive = "naive_time"
    ),
    abbr = switch(
      clock,
      sys = "sys",
      naive = "naive"
    )
  )

  paste0(name, "<", precision, ">")
}

# ------------------------------------------------------------------------------

# Caller guarantees that clocks are identical
ptype2_time_point_and_time_point <- function(x, y, ...) {
  if (time_point_precision_attribute(x) >= time_point_precision_attribute(y)) {
    x
  } else {
    y
  }
}

# Caller guarantees that clocks are identical
cast_time_point_to_time_point <- function(x, to, ...) {
  x_precision <- time_point_precision_attribute(x)
  to_precision <- time_point_precision_attribute(to)

  if (x_precision == to_precision) {
    return(x)
  }

  if (x_precision > to_precision) {
    stop_incompatible_cast(
      x,
      to,
      ...,
      details = "Can't cast to a less precise precision."
    )
  }

  fields <- duration_cast_cpp(x, x_precision, to_precision)

  names <- clock_rcrd_names(x)
  clock <- time_point_clock_attribute(x)

  new_time_point_from_fields(fields, to_precision, clock, names)
}

# ------------------------------------------------------------------------------

arith_time_point_and_missing <- function(op, x, y, ...) {
  switch(
    op,
    "+" = x,
    stop_incompatible_op(op, x, y, ...)
  )
}

arith_time_point_and_time_point <- function(op, x, y, ...) {
  switch(
    op,
    "-" = time_point_minus_time_point(x, y, names_common(x, y)),
    stop_incompatible_op(op, x, y, ...)
  )
}

arith_time_point_and_duration <- function(op, x, y, ...) {
  switch(
    op,
    "+" = time_point_plus_duration(
      x,
      y,
      duration_precision_attribute(y),
      names_common(x, y)
    ),
    "-" = time_point_minus_duration(
      x,
      y,
      duration_precision_attribute(y),
      names_common(x, y)
    ),
    stop_incompatible_op(op, x, y, ...)
  )
}

arith_duration_and_time_point <- function(op, x, y, ...) {
  switch(
    op,
    "+" = time_point_plus_duration(
      y,
      x,
      duration_precision_attribute(x),
      names_common(x, y)
    ),
    "-" = stop_incompatible_op(
      op,
      x,
      y,
      details = "Can't subtract a time point from a duration.",
      ...
    ),
    stop_incompatible_op(op, x, y, ...)
  )
}

arith_time_point_and_numeric <- function(op, x, y, ...) {
  precision <- time_point_precision_attribute(x)

  switch(
    op,
    "+" = time_point_plus_duration(x, y, precision, names_common(x, y)),
    "-" = time_point_minus_duration(x, y, precision, names_common(x, y)),
    stop_incompatible_op(op, x, y, ...)
  )
}

arith_numeric_and_time_point <- function(op, x, y, ...) {
  precision <- time_point_precision_attribute(y)

  switch(
    op,
    "+" = time_point_plus_duration(y, x, precision, names_common(x, y)),
    "-" = stop_incompatible_op(
      op,
      x,
      y,
      details = "Can't subtract a time point from a duration.",
      ...
    ),
    stop_incompatible_op(op, x, y, ...)
  )
}

# ------------------------------------------------------------------------------

#' Arithmetic: Time points
#'
#' @description
#' These are naive-time and sys-time methods for the
#' [arithmetic generics][clock-arithmetic].
#'
#' - `add_weeks()`
#'
#' - `add_days()`
#'
#' - `add_hours()`
#'
#' - `add_minutes()`
#'
#' - `add_seconds()`
#'
#' - `add_milliseconds()`
#'
#' - `add_microseconds()`
#'
#' - `add_nanoseconds()`
#'
#' When working with zoned times, generally you convert to either sys-time
#' or naive-time, add the duration, then convert back to zoned time. Typically,
#' _weeks and days_ are added in _naive-time_, and _hours, minutes, seconds,
#' and subseconds_ are added in _sys-time_.
#'
#' If you aren't using zoned times, arithmetic on sys-times and naive-time
#' is equivalent.
#'
#' If you need to add larger irregular units of time, such as months, quarters,
#' or years, convert to a calendar type with a converter like
#' [as_year_month_day()].
#'
#' @details
#' `x` and `n` are recycled against each other using
#' [tidyverse recycling rules][vctrs::vector_recycling_rules].
#'
#' @inheritParams clock-arithmetic
#'
#' @param x `[clock_sys_time / clock_naive_time]`
#'
#'   A time point vector.
#'
#' @return `x` after performing the arithmetic.
#'
#' @name time-point-arithmetic
#'
#' @examples
#' library(magrittr)
#'
#' # Say you started with this zoned time, and you want to add 1 day to it
#' x <- as_naive_time(year_month_day(1970, 04, 25, 02, 30, 00))
#' x <- as_zoned_time(x, "America/New_York")
#' x
#'
#' # Note that there was a daylight saving time gap on 1970-04-26 where
#' # we jumped from 01:59:59 -> 03:00:00.
#'
#' # You can choose to add 1 day in "system time", by first converting to
#' # sys-time (the equivalent UTC time), adding the day, then converting back to
#' # zoned time. If you sat still for exactly 86,400 seconds, this is the
#' # time that you would see after daylight saving time adjusted the clock
#' # (note that the hour field is shifted forward by the size of the gap)
#' as_sys_time(x)
#'
#' x %>%
#'   as_sys_time() %>%
#'   add_days(1) %>%
#'   as_zoned_time(zoned_time_zone(x))
#'
#' # Alternatively, you can add 1 day in "naive time". Naive time represents
#' # a clock time with a yet-to-be-specified time zone. It tries to maintain
#' # smaller units where possible, so adding 1 day would attempt to return
#' # "1970-04-26T02:30:00" in the America/New_York time zone, but...
#' as_naive_time(x)
#'
#' try({
#' x %>%
#'   as_naive_time() %>%
#'   add_days(1) %>%
#'   as_zoned_time(zoned_time_zone(x))
#' })
#'
#' # ...this time doesn't exist in that time zone! It is "nonexistent".
#' # You can resolve nonexistent times by setting the `nonexistent` argument
#' # when converting to zoned time. Let's roll forward to the next available
#' # moment in time.
#' x %>%
#'   as_naive_time() %>%
#'   add_days(1) %>%
#'   as_zoned_time(zoned_time_zone(x), nonexistent = "roll-forward")
NULL

#' @rdname time-point-arithmetic
#' @export
add_weeks.clock_time_point <- function(x, n, ...) {
  time_point_plus_duration(x, n, PRECISION_WEEK, names_common(x, n))
}

#' @rdname time-point-arithmetic
#' @export
add_days.clock_time_point <- function(x, n, ...) {
  time_point_plus_duration(x, n, PRECISION_DAY, names_common(x, n))
}

#' @rdname time-point-arithmetic
#' @export
add_hours.clock_time_point <- function(x, n, ...) {
  time_point_plus_duration(x, n, PRECISION_HOUR, names_common(x, n))
}

#' @rdname time-point-arithmetic
#' @export
add_minutes.clock_time_point <- function(x, n, ...) {
  time_point_plus_duration(x, n, PRECISION_MINUTE, names_common(x, n))
}

#' @rdname time-point-arithmetic
#' @export
add_seconds.clock_time_point <- function(x, n, ...) {
  time_point_plus_duration(x, n, PRECISION_SECOND, names_common(x, n))
}

#' @rdname time-point-arithmetic
#' @export
add_milliseconds.clock_time_point <- function(x, n, ...) {
  time_point_plus_duration(x, n, PRECISION_MILLISECOND, names_common(x, n))
}

#' @rdname time-point-arithmetic
#' @export
add_microseconds.clock_time_point <- function(x, n, ...) {
  time_point_plus_duration(x, n, PRECISION_MICROSECOND, names_common(x, n))
}

#' @rdname time-point-arithmetic
#' @export
add_nanoseconds.clock_time_point <- function(x, n, ...) {
  time_point_plus_duration(x, n, PRECISION_NANOSECOND, names_common(x, n))
}

time_point_plus_duration <- function(x, n, precision_n, names) {
  time_point_arith_duration(x, n, precision_n, names, duration_plus)
}
time_point_minus_duration <- function(x, n, precision_n, names) {
  time_point_arith_duration(x, n, precision_n, names, duration_minus)
}

time_point_arith_duration <- function(x, n, precision_n, names, duration_fn) {
  clock <- time_point_clock_attribute(x)
  x <- time_point_duration(x)

  n <- duration_collect_n(n, precision_n)

  # Handles recycling and casting
  duration <- duration_fn(x = x, y = n, names = names)

  names <- clock_rcrd_names(duration)
  precision <- duration_precision_attribute(duration)

  new_time_point_from_fields(duration, precision, clock, names)
}

time_point_minus_time_point <- function(x, y, names) {
  args <- vec_recycle_common(x = x, y = y, names = names)
  x <- args$x
  y <- args$y
  names <- args$names

  x_duration <- time_point_duration(x)
  y_duration <- time_point_duration(y)

  duration_minus(x = x_duration, y = y_duration, names = names)
}

# ------------------------------------------------------------------------------

#' @export
add_years.clock_time_point <- function(x, n, ...) {
  details <- c(
    i = "Do you need to convert to a calendar first?",
    i = cli::format_inline(
      "Use {.fn as_year_month_day} for a calendar that supports {.fn add_years}."
    )
  )
  stop_clock_unsupported(x, details = details)
}

#' @export
add_quarters.clock_time_point <- function(x, n, ...) {
  details <- c(
    i = "Do you need to convert to a calendar first?",
    i = cli::format_inline(
      "Use {.fn as_year_quarter_day} for a calendar that supports {.fn add_quarters}."
    )
  )
  stop_clock_unsupported(x, details = details)
}

#' @export
add_months.clock_time_point <- function(x, n, ...) {
  details <- c(
    i = "Do you need to convert to a calendar first?",
    i = cli::format_inline(
      "Use {.fn as_year_month_day} for a calendar that supports {.fn add_months}."
    )
  )
  stop_clock_unsupported(x, details = details)
}

# ------------------------------------------------------------------------------

#' @export
diff.clock_time_point <- function(x, lag = 1L, differences = 1L, ...) {
  # Special care to ensure that when `lag * differences >= n`, we still
  # return a duration type rather than `vec_slice(x, 0L)` which vctrs does by
  # default. It is always valid to diff the duration in place of the time point.
  x <- as_duration(x)
  diff(x, lag = lag, differences = differences, ...)
}

# ------------------------------------------------------------------------------

#' @export
as_duration.clock_time_point <- function(x, ...) {
  check_dots_empty0(...)
  time_point_duration(x, retain_names = TRUE)
}

#' @export
as_year_month_day.clock_time_point <- function(x, ...) {
  check_dots_empty0(...)
  precision <- time_point_precision_attribute(x)
  fields <- as_year_month_day_from_sys_time_cpp(x, precision)
  new_year_month_day_from_fields(fields, precision, names = names(x))
}

#' @export
as_year_month_weekday.clock_time_point <- function(x, ...) {
  check_dots_empty0(...)
  precision <- time_point_precision_attribute(x)
  fields <- as_year_month_weekday_from_sys_time_cpp(x, precision)
  new_year_month_weekday_from_fields(fields, precision, names = names(x))
}

#' @export
as_year_quarter_day.clock_time_point <- function(x, ..., start = NULL) {
  check_dots_empty0(...)
  precision <- time_point_precision_attribute(x)
  start <- quarterly_validate_start(start)
  fields <- as_year_quarter_day_from_sys_time_cpp(x, precision, start)
  new_year_quarter_day_from_fields(fields, precision, start, names = names(x))
}

#' @export
as_year_week_day.clock_time_point <- function(x, ..., start = NULL) {
  check_dots_empty0(...)
  precision <- time_point_precision_attribute(x)
  start <- week_validate_start(start)
  fields <- as_year_week_day_from_sys_time_cpp(x, precision, start)
  new_year_week_day_from_fields(fields, precision, start, names = names(x))
}

#' @export
as_iso_year_week_day.clock_time_point <- function(x, ...) {
  check_dots_empty0(...)
  precision <- time_point_precision_attribute(x)
  fields <- as_iso_year_week_day_from_sys_time_cpp(x, precision)
  new_iso_year_week_day_from_fields(fields, precision, names = names(x))
}

#' @export
as_year_day.clock_time_point <- function(x, ...) {
  check_dots_empty0(...)
  precision <- time_point_precision_attribute(x)
  fields <- as_year_day_from_sys_time_cpp(x, precision)
  new_year_day_from_fields(fields, precision, names = names(x))
}

#' @export
as_weekday.clock_time_point <- function(x, ...) {
  check_dots_empty0(...)
  x <- time_point_cast(x, "day")
  day <- weekday_from_time_point_cpp(x)
  names(day) <- clock_rcrd_names(x)
  new_weekday(day)
}

# ------------------------------------------------------------------------------

#' Cast a time point between precisions
#'
#' @description
#' Casting is one way to change a time point's precision.
#'
#' Casting to a less precise precision will completely drop information that
#' is more precise than the precision that you are casting to. It does so
#' in a way that makes it round towards zero. When converting time points
#' to a less precise precision, you often want [time_point_floor()] instead
#' of `time_point_cast()`, as that handles pre-1970 dates (which are
#' stored as negative durations) in a more intuitive manner.
#'
#' Casting to a more precise precision is done through a multiplication by
#' a conversion factor between the current precision and the new precision.
#'
#' @param x `[clock_sys_time / clock_naive_time]`
#'
#'   A sys-time or naive-time.
#'
#' @param precision `[character(1)]`
#'
#'   A time point precision. One of:
#'
#'   - `"day"`
#'
#'   - `"hour"`
#'
#'   - `"minute"`
#'
#'   - `"second"`
#'
#'   - `"millisecond"`
#'
#'   - `"microsecond"`
#'
#'   - `"nanosecond"`
#'
#' @return `x` cast to the new `precision`.
#'
#' @export
#' @examples
#' # Hour precision time points
#' # One is pre-1970, one is post-1970
#' x <- duration_hours(c(25, -25))
#' x <- as_naive_time(x)
#' x
#'
#' # Casting rounds the underlying duration towards 0
#' cast <- time_point_cast(x, "day")
#' cast
#'
#' # Flooring rounds the underlying duration towards negative infinity,
#' # which is often more intuitive for time points.
#' # Note that the cast ends up rounding the pre-1970 date up to the next
#' # day, while the post-1970 date is rounded down.
#' floor <- time_point_floor(x, "day")
#' floor
#'
#' # Casting to a more precise precision, hour->millisecond
#' time_point_cast(x, "millisecond")
time_point_cast <- function(x, precision) {
  check_time_point(x)

  check_time_point_precision(precision)
  precision <- precision_to_integer(precision)

  x_precision <- time_point_precision_attribute(x)

  fields <- duration_cast_cpp(x, x_precision, precision)

  names <- clock_rcrd_names(x)
  clock <- time_point_clock_attribute(x)

  new_time_point_from_fields(fields, precision, clock, names)
}

#' Time point rounding
#'
#' @description
#' - `time_point_floor()` rounds a sys-time or naive-time down to a multiple of
#'   the specified `precision`.
#'
#' - `time_point_ceiling()` rounds a sys-time or naive-time up to a multiple of
#'   the specified `precision`.
#'
#' - `time_point_round()` rounds up or down depending on what is closer,
#'   rounding up on ties.
#'
#' Rounding time points is mainly useful for rounding sub-daily time points
#' up to daily time points.
#'
#' It can also be useful for flooring by a set number of days (like 20) with
#' respect to some origin. By default, the origin is 1970-01-01 00:00:00.
#'
#' If you want to group by components, such as "day of the month", rather than
#' by "n days", see [calendar_group()].
#'
#' @section Boundary Handling:
#'
#' To understand how flooring and ceiling work, you need to know how they
#' create their intervals for rounding.
#'
#' - `time_point_floor()` constructs intervals of \code{[lower, upper)} that
#'   bound each element of `x`, then always chooses the _left-hand side_.
#'
#' - `time_point_ceiling()` constructs intervals of \code{(lower, upper]} that
#'   bound each element of `x`, then always chooses the _right-hand side_.
#'
#' As an easy example, consider 2020-01-02 00:00:05.
#'
#' To floor this to the nearest day, the following interval is constructed,
#' and the left-hand side is returned at day precision:
#'
#' \code{[2020-01-02 00:00:00, 2020-01-03 00:00:00)}
#'
#' To ceiling this to the nearest day, the following interval
#' is constructed, and the right-hand side is returned at day precision:
#'
#' \code{(2020-01-02 00:00:00, 2020-01-03 00:00:00]}
#'
#' Here is another example, this time with a time point on a boundary,
#' 2020-01-02 00:00:00.
#'
#' To floor this to the nearest day, the following interval is constructed,
#' and the left-hand side is returned at day precision:
#'
#' \code{[2020-01-02 00:00:00, 2020-01-03 00:00:00)}
#'
#' To ceiling this to the nearest day, the following interval
#' is constructed, and the right-hand side is returned at day precision:
#'
#' \code{(2020-01-01 00:00:00, 2020-01-02 00:00:00]}
#'
#' Notice that, regardless of whether you are doing a floor or ceiling, if
#' the input falls on a boundary then it will be returned as is.
#'
#' @inheritParams rlang::args_dots_empty
#' @inheritParams time_point_cast
#'
#' @param n `[positive integer(1)]`
#'
#'   A positive integer specifying the multiple of `precision` to use.
#'
#' @param origin `[clock_sys_time(1) / clock_naive_time(1) / NULL]`
#'
#'   An origin to begin counting from. Mostly useful when `n > 1` and you
#'   want to control how the rounding groups are created.
#'
#'   If `x` is a sys-time, `origin` must be a sys-time.
#'
#'   If `x` is a naive-time, `origin` must be a naive-time.
#'
#'   The precision of `origin` must be equally precise as or less
#'   precise than `precision`.
#'
#'   If `NULL`, a default origin of midnight on 1970-01-01 is used.
#'
#' @return `x` rounded to the new `precision`.
#'
#' @name time-point-rounding
#'
#' @examples
#' library(magrittr)
#'
#' x <- as_naive_time(year_month_day(2019, 01, 01))
#' x <- add_days(x, 0:40)
#' head(x)
#'
#' # Floor by sets of 20 days
#' # The implicit origin to start the 20 day counter is 1970-01-01
#' time_point_floor(x, "day", n = 20)
#'
#' # You can easily customize the origin by supplying a new one
#' # as the `origin` argument
#' origin <- year_month_day(2019, 01, 01) %>%
#'   as_naive_time()
#'
#' time_point_floor(x, "day", n = 20, origin = origin)
#'
#' # For times on the boundary, floor and ceiling both return the input
#' # at the new precision. Notice how the first element is on the boundary,
#' # and the second is 1 second after the boundary.
#' y <- as_naive_time(year_month_day(2020, 01, 02, 00, 00, c(00, 01)))
#' time_point_floor(y, "day")
#' time_point_ceiling(y, "day")
NULL

#' @rdname time-point-rounding
#' @export
time_point_floor <- function(x, precision, ..., n = 1L, origin = NULL) {
  time_point_rounder(x, precision, n, origin, duration_floor, ...)
}
#' @rdname time-point-rounding
#' @export
time_point_ceiling <- function(x, precision, ..., n = 1L, origin = NULL) {
  time_point_rounder(x, precision, n, origin, duration_ceiling, ...)
}
#' @rdname time-point-rounding
#' @export
time_point_round <- function(x, precision, ..., n = 1L, origin = NULL) {
  time_point_rounder(x, precision, n, origin, duration_round, ...)
}

time_point_rounder <- function(
  x,
  precision,
  n,
  origin,
  duration_rounder,
  ...,
  error_arg = caller_arg(x),
  error_call = caller_env()
) {
  check_dots_empty0(...)

  check_time_point(x, arg = error_arg, call = error_call)

  precision_string <- precision
  check_time_point_precision(precision, call = error_call)
  precision <- precision_to_integer(precision)

  duration <- time_point_duration(x)

  has_origin <- !is_null(origin)

  if (has_origin) {
    origin <- collect_time_point_rounder_origin(
      origin = origin,
      x = x,
      precision = precision,
      error_call = error_call
    )
    duration <- duration - origin
  }

  duration <- duration_rounder(duration, precision_string, n = n)

  if (has_origin) {
    duration <- duration + origin
  }

  names <- clock_rcrd_names(x)
  clock <- time_point_clock_attribute(x)

  new_time_point_from_fields(duration, precision, clock, names)
}

collect_time_point_rounder_origin <- function(
  origin,
  x,
  precision,
  error_call
) {
  # Cast `origin` to a time point with the same clock as `x`,
  # but with a precision of `precision`
  to_names <- NULL
  to <- duration_helper(integer(), precision)
  to <- new_time_point_from_fields(
    to,
    precision,
    time_point_clock_attribute(x),
    to_names
  )

  origin <- vec_cast(origin, to, x_arg = "origin", call = error_call)

  vec_check_size(origin, 1L, call = error_call)
  check_no_missing(origin, call = error_call)

  origin <- as_duration(origin)

  origin
}

# ------------------------------------------------------------------------------

#' Shifting: time point
#'
#' @description
#' `time_point_shift()` shifts `x` to the `target` weekday. You can
#' shift to the next or previous weekday. If `x` is currently on the `target`
#' weekday, you can choose to leave it alone or advance it to the next instance
#' of the `target`.
#'
#' Weekday shifting is one of the easiest ways to floor by week while
#' controlling what is considered the first day of the week. You can also
#' accomplish this with the `origin` argument of [time_point_floor()], but
#' this is slightly easier.
#'
#' @inheritParams rlang::args_dots_empty
#'
#' @param x `[clock_time_point]`
#'
#'   A time point.
#'
#' @param target `[weekday]`
#'
#'   A weekday created from [weekday()] to target.
#'
#'   Generally this is length 1, but can also be the same length as `x`.
#'
#' @param which `[character(1)]`
#'
#'   One of:
#'
#'   - `"next"`: Shift to the next instance of the `target` weekday.
#'
#'   - `"previous`: Shift to the previous instance of the `target` weekday.
#'
#' @param boundary `[character(1)]`
#'
#'   One of:
#'
#'   - `"keep"`: If `x` is currently on the `target` weekday, return it.
#'
#'   - `"advance"`: If `x` is currently on the `target` weekday, advance it
#'   anyways.
#'
#' @return `x` shifted to the `target` weekday.
#'
#' @export
#' @examples
#' x <- as_naive_time(year_month_day(2019, 1, 1:2))
#'
#' # A Tuesday and Wednesday
#' as_weekday(x)
#'
#' monday <- weekday(clock_weekdays$monday)
#'
#' # Shift to the next Monday
#' time_point_shift(x, monday)
#'
#' # Shift to the previous Monday
#' # This is an easy way to "floor by week" with a target weekday in mind
#' time_point_shift(x, monday, which = "previous")
#'
#' # What about Tuesday?
#' tuesday <- weekday(clock_weekdays$tuesday)
#'
#' # Notice that the day that was currently on a Tuesday was not shifted
#' time_point_shift(x, tuesday)
#'
#' # You can force it to `"advance"`
#' time_point_shift(x, tuesday, boundary = "advance")
time_point_shift <- function(
  x,
  target,
  ...,
  which = "next",
  boundary = "keep"
) {
  check_dots_empty0(...)

  check_time_point(x)
  check_weekday(target)

  target <- vec_recycle(target, vec_size(x), x_arg = "target")

  check_shift_which(which)
  check_shift_boundary(boundary)

  if (is_next(which)) {
    if (is_advance(boundary)) {
      x <- x + duration_days(1L)
    }
    x <- x + (target - as_weekday(x))
  } else {
    if (is_advance(boundary)) {
      x <- x - duration_days(1L)
    }
    x <- x - (as_weekday(x) - target)
  }

  x
}

check_shift_which <- function(which, call = caller_env()) {
  check_string(which, call = call)
  arg_match0(which, values = c("next", "previous"), error_call = call)
}
check_shift_boundary <- function(boundary, call = caller_env()) {
  check_string(boundary, call = call)
  arg_match0(boundary, values = c("keep", "advance"), error_call = call)
}

is_next <- function(x) {
  identical(x, "next")
}
is_advance <- function(x) {
  identical(x, "advance")
}

# ------------------------------------------------------------------------------

#' Counting: time point
#'
#' @description
#' `time_point_count_between()` counts the number of `precision` units
#' between `start` and `end` (i.e., the number of days or hours). This count
#' corresponds to the _whole number_ of units, and will never return a
#' fractional value.
#'
#' This is suitable for, say, computing the whole number of days between two
#' time points, accounting for the time of day.
#'
#' @details
#' Remember that `time_point_count_between()` returns an integer vector.
#' With extremely fine precisions, such as nanoseconds, the count can quickly
#' exceed the maximum value that is allowed in an integer. In this case, an
#' `NA` will be returned with a warning.
#'
#' @inheritSection calendar_count_between Comparison Direction
#'
#' @inheritParams rlang::args_dots_empty
#'
#' @param start,end `[clock_time_point]`
#'
#'   A pair of time points. These will be recycled to their common size.
#'
#' @param precision `[character(1)]`
#'
#'   One of:
#'
#'   - `"week"`
#'   - `"day"`
#'   - `"hour"`
#'   - `"minute"`
#'   - `"second"`
#'   - `"millisecond"`
#'   - `"microsecond"`
#'   - `"nanosecond"`
#'
#' @param n `[positive integer(1)]`
#'
#'   A single positive integer specifying a multiple of `precision` to use.
#'
#' @return An integer representing the number of `precision` units between
#' `start` and `end`.
#'
#' @export
#' @examples
#' x <- as_naive_time(year_month_day(2019, 2, 3))
#' y <- as_naive_time(year_month_day(2019, 2, 10))
#'
#' # Whole number of days or hours between two time points
#' time_point_count_between(x, y, "day")
#' time_point_count_between(x, y, "hour")
#'
#' # Whole number of 2-day units
#' time_point_count_between(x, y, "day", n = 2)
#'
#' # Leap years are taken into account
#' x <- as_naive_time(year_month_day(c(2020, 2021), 2, 28))
#' y <- as_naive_time(year_month_day(c(2020, 2021), 3, 01))
#' time_point_count_between(x, y, "day")
#'
#' # Time of day is taken into account.
#' # `2020-02-02T04 -> 2020-02-03T03` is not a whole day (because of the hour)
#' # `2020-02-02T04 -> 2020-02-03T05` is a whole day
#' x <- as_naive_time(year_month_day(2020, 2, 2, 4))
#' y <- as_naive_time(year_month_day(2020, 2, 3, c(3, 5)))
#' time_point_count_between(x, y, "day")
#' time_point_count_between(x, y, "hour")
#'
#' # Can compute negative counts (using the same example from above)
#' time_point_count_between(y, x, "day")
#' time_point_count_between(y, x, "hour")
#'
#' # Repeated computation at increasingly fine precisions
#' x <- as_naive_time(year_month_day(
#'   2020, 2, 2, 4, 5, 6, 200,
#'   subsecond_precision = "microsecond"
#' ))
#' y <- as_naive_time(year_month_day(
#'   2020, 3, 1, 8, 9, 10, 100,
#'   subsecond_precision = "microsecond"
#' ))
#'
#' days <- time_point_count_between(x, y, "day")
#' x <- x + duration_days(days)
#'
#' hours <- time_point_count_between(x, y, "hour")
#' x <- x + duration_hours(hours)
#'
#' minutes <- time_point_count_between(x, y, "minute")
#' x <- x + duration_minutes(minutes)
#'
#' seconds <- time_point_count_between(x, y, "second")
#' x <- x + duration_seconds(seconds)
#'
#' microseconds <- time_point_count_between(x, y, "microsecond")
#' x <- x + duration_microseconds(microseconds)
#'
#' data.frame(
#'   days = days,
#'   hours = hours,
#'   minutes = minutes,
#'   seconds = seconds,
#'   microseconds = microseconds
#' )
time_point_count_between <- function(start, end, precision, ..., n = 1L) {
  check_dots_empty0(...)

  check_time_point(start)
  check_time_point(end)

  args <- vec_cast_common(start = start, end = end)
  args <- vec_recycle_common(!!!args)
  start <- args[[1]]
  end <- args[[2]]

  check_precision(precision)
  precision_int <- precision_to_integer(precision)

  if (precision_int < PRECISION_WEEK) {
    cli::cli_abort("{.arg precision} must be at least {.str week} precision.")
  }

  check_number_whole(n, min = 0)
  n <- vec_cast(n, integer())

  out <- end - start
  out <- duration_cast(out, precision)

  if (n != 1L) {
    out <- out %/% n
  }

  as.integer(out)
}

# ------------------------------------------------------------------------------

#' Sequences: time points
#'
#' @description
#' This is a time point method for the [seq()] generic. It works for sys-time
#' and naive-time vectors.
#'
#' Sequences can be generated for all valid time point precisions (daily through
#' nanosecond).
#'
#' When calling `seq()`, exactly two of the following must be specified:
#' - `to`
#' - `by`
#' - Either `length.out` or `along.with`
#'
#' @inheritParams seq.clock_duration
#'
#' @param from `[clock_sys_time(1) / clock_naive_time(1)]`
#'
#'   A time point to start the sequence from.
#'
#'   `from` is always included in the result.
#'
#' @param to `[clock_sys_time(1) / clock_naive_time(1) / NULL]`
#'
#'   A time point to stop the sequence at.
#'
#'   `to` is cast to the type of `from`.
#'
#'   `to` is only included in the result if the resulting sequence divides
#'   the distance between `from` and `to` exactly.
#'
#' @return A sequence with the type of `from`.
#'
#' @export
#' @examples
#' # Daily sequence
#' seq(
#'   as_naive_time(year_month_day(2019, 1, 1)),
#'   as_naive_time(year_month_day(2019, 2, 4)),
#'   by = 5
#' )
#'
#' # Minutely sequence using minute precision naive-time
#' x <- as_naive_time(year_month_day(2019, 1, 2, 3, 3))
#' x
#'
#' seq(x, by = 4, length.out = 10)
#'
#' # You can use larger step sizes by using a duration-based `by`
#' seq(x, by = duration_days(1), length.out = 5)
#'
#' # Nanosecond sequence
#' from <- as_naive_time(year_month_day(2019, 1, 1))
#' from <- time_point_cast(from, "nanosecond")
#' to <- from + 100
#' seq(from, to, by = 10)
seq.clock_time_point <- function(
  from,
  to = NULL,
  by = NULL,
  length.out = NULL,
  along.with = NULL,
  ...
) {
  names <- NULL
  clock <- time_point_clock_attribute(from)
  precision <- time_point_precision_attribute(from)

  has_to <- !is_null(to)

  if (has_to) {
    to <- vec_cast(to, from, x_arg = "to", to_arg = "from")
  }

  from <- time_point_duration(from)

  if (has_to) {
    to <- time_point_duration(to)
  }

  fields <- seq(
    from = from,
    to = to,
    by = by,
    length.out = length.out,
    along.with = along.with,
    ...
  )

  new_time_point_from_fields(fields, precision, clock, names)
}

# ------------------------------------------------------------------------------

#' Spanning sequence: time points
#'
#' @description
#' `time_point_spanning_seq()` generates a regular sequence along the span of
#' `x`, i.e. along `[min(x), max(x)]`. The sequence is generated at the
#' precision of `x`.
#'
#' @details
#' Missing values are automatically removed before the sequence is generated.
#'
#' If you need more precise sequence generation, call [range()] and [seq()]
#' directly.
#'
#' @param x `[clock_sys_time / clock_naive_time]`
#'
#'   A time point vector.
#'
#' @return A sequence along `[min(x), max(x)]`.
#'
#' @export
#' @examples
#' x <- as_naive_time(year_month_day(2019, c(1, 2, 1, 2), c(15, 4, 12, 2)))
#' x
#'
#' time_point_spanning_seq(x)
#'
#' # The sequence is generated at the precision of `x`
#' x <- as_naive_time(c(
#'   year_month_day(2019, 1, 1, 5),
#'   year_month_day(2019, 1, 2, 10),
#'   year_month_day(2019, 1, 1, 3)
#' ))
#' time_point_spanning_seq(x)
time_point_spanning_seq <- function(x) {
  check_time_point(x)
  spanning_seq_impl(x)
}

# ------------------------------------------------------------------------------

#' Precision: time point
#'
#' `time_point_precision()` extracts the precision from a time point, such
#' as a sys-time or naive-time. It returns the precision as a single string.
#'
#' @param x `[clock_time_point]`
#'
#'   A time point.
#'
#' @return A single string holding the precision of the time point.
#'
#' @export
#' @examples
#' time_point_precision(sys_time_now())
#' time_point_precision(as_naive_time(duration_days(1)))
time_point_precision <- function(x) {
  check_time_point(x)
  precision <- time_point_precision_attribute(x)
  precision <- precision_to_string(precision)
  precision
}

# ------------------------------------------------------------------------------

# `clock_minimum()` and `clock_maximum()` are known to not print correctly
# for anything besides nanosecond precision time points. If you convert the
# values to durations, they will print correctly. This has to do with the
# print method going through year-month-day, which has a limit on how large the
# `year` field can be that doesn't align with the limit of time points. See #331
# for a detailed discussion. The important thing is that the limits still work
# correctly for comparison purposes!

#' @export
clock_minimum.clock_time_point <- function(x) {
  time_point_limit(x, clock_minimum)
}

#' @export
clock_maximum.clock_time_point <- function(x) {
  time_point_limit(x, clock_maximum)
}

time_point_limit <- function(x, fn) {
  names <- NULL
  clock <- time_point_clock_attribute(x)
  precision <- time_point_precision_attribute(x)
  x <- time_point_duration(x)
  x <- fn(x)
  new_time_point_from_fields(x, precision, clock, names)
}

# ------------------------------------------------------------------------------

check_time_point_precision <- function(
  x,
  ...,
  arg = caller_arg(x),
  call = caller_env()
) {
  check_precision(
    x = x,
    values = c("day", precision_time_names()),
    arg = arg,
    call = call
  )
}
