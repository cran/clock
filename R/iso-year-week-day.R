#' Calendar: iso-year-week-day
#'
#' `iso_year_week_day()` constructs a calendar from the ISO year, week number,
#' and week day.
#'
#' @details
#' Fields are recycled against each other using
#' [tidyverse recycling rules][vctrs::vector_recycling_rules].
#'
#' Fields are collected in order until the first `NULL` field is located. No
#' fields after the first `NULL` field are used.
#'
#' @inheritParams rlang::args_dots_empty
#' @inheritParams year_month_day
#'
#' @param year `[integer]`
#'
#'   The ISO year. Values `[-32767, 32767]` are generally allowed.
#'
#' @param week `[integer / "last" / NULL]`
#'
#'   The ISO week. Values `[1, 53]` are allowed.
#'
#'   If `"last"`, then the last week of the ISO year is returned.
#'
#' @param day `[integer / NULL]`
#'
#'   The day of the week. Values `[1, 7]` are allowed, with 1 = Monday
#'   and 7 = Sunday, in accordance with the ISO specifications.
#'
#' @return A iso-year-week-day calendar vector.
#'
#' @export
#' @examples
#' # Year-week
#' x <- iso_year_week_day(2019:2025, 1)
#' x
#'
#' # 2nd day of the first ISO week in multiple years
#' iso_days <- set_day(x, clock_iso_weekdays$tuesday)
#' iso_days
#'
#' # What year-month-day is this?
#' as_year_month_day(iso_days)
iso_year_week_day <- function(year,
                              week = NULL,
                              day = NULL,
                              hour = NULL,
                              minute = NULL,
                              second = NULL,
                              subsecond = NULL,
                              ...,
                              subsecond_precision = NULL) {
  check_dots_empty()

  # Stop on the first `NULL` argument
  if (is_null(week)) {
    precision <- PRECISION_YEAR
    fields <- list(year = year)
  } else if (is_null(day)) {
    precision <- PRECISION_WEEK
    fields <- list(year = year, week = week)
  } else if (is_null(hour)) {
    precision <- PRECISION_DAY
    fields <- list(year = year, week = week, day = day)
  } else if (is_null(minute)) {
    precision <- PRECISION_HOUR
    fields <- list(year = year, week = week, day = day, hour = hour)
  } else if (is_null(second)) {
    precision <- PRECISION_MINUTE
    fields <- list(year = year, week = week, day = day, hour = hour, minute = minute)
  } else if (is_null(subsecond)) {
    precision <- PRECISION_SECOND
    fields <- list(year = year, week = week, day = day, hour = hour, minute = minute, second = second)
  } else {
    calendar_check_subsecond_precision(subsecond_precision)
    precision <- precision_to_integer(subsecond_precision)
    fields <- list(year = year, week = week, day = day, hour = hour, minute = minute, second = second, subsecond = subsecond)
  }

  if (is_last(fields$week)) {
    fields$week <- 1L
    last <- TRUE
  } else {
    last <- FALSE
  }

  fields <- vec_cast_common(!!!fields, .to = integer())

  if (precision >= PRECISION_YEAR) {
    check_between_year(fields$year, arg = "year")
  }
  if (precision >= PRECISION_WEEK) {
    check_between_week(fields$week, arg = "week")
  }
  if (precision >= PRECISION_DAY) {
    check_between_day_of_week(fields$day, arg = "day")
  }
  if (precision >= PRECISION_HOUR) {
    check_between_hour(fields$hour, arg = "hour")
  }
  if (precision >= PRECISION_MINUTE) {
    check_between_minute(fields$minute, arg = "minute")
  }
  if (precision >= PRECISION_SECOND) {
    check_between_second(fields$second, arg = "second")
  }
  if (precision > PRECISION_SECOND) {
    check_between_subsecond(fields$subsecond, precision, arg = "subsecond")
  }

  fields <- vec_recycle_common(!!!fields)
  fields <- df_list_propagate_missing(fields)

  names <- NULL
  out <- new_iso_year_week_day_from_fields(fields, precision, names)

  if (last) {
    out <- set_week(out, "last")
  }

  out
}

# ------------------------------------------------------------------------------

#' @export
vec_proxy.clock_iso_year_week_day <- function(x, ...) {
  .Call(`_clock_clock_rcrd_proxy`, x)
}

#' @export
vec_restore.clock_iso_year_week_day <- function(x, to, ...) {
  .Call(`_clock_iso_year_week_day_restore`, x, to)
}

# ------------------------------------------------------------------------------

#' @export
format.clock_iso_year_week_day <- function(x, ...) {
  out <- format_iso_year_week_day_cpp(x, calendar_precision_attribute(x))
  names(out) <- names(x)
  out
}

#' @export
vec_ptype_full.clock_iso_year_week_day <- function(x, ...) {
  calendar_ptype_full(x, "iso_year_week_day")
}

#' @export
vec_ptype_abbr.clock_iso_year_week_day <- function(x, ...) {
  calendar_ptype_abbr(x, "iso_ywd")
}

# ------------------------------------------------------------------------------

#' Is `x` a iso-year-week-day?
#'
#' Check if `x` is a iso-year-week-day.
#'
#' @param x `[object]`
#'
#'   An object.
#'
#' @return Returns `TRUE` if `x` inherits from `"clock_iso_year_week_day"`,
#'   otherwise returns `FALSE`.
#'
#' @export
#' @examples
#' is_iso_year_week_day(iso_year_week_day(2019))
is_iso_year_week_day <- function(x) {
  inherits(x, "clock_iso_year_week_day")
}

# ------------------------------------------------------------------------------

#' @export
vec_ptype.clock_iso_year_week_day <- function(x, ...) {
  switch(
    calendar_precision_attribute(x) + 1L,
    clock_empty_iso_year_week_day_year,
    abort("Internal error: Invalid precision"),
    abort("Internal error: Invalid precision"),
    clock_empty_iso_year_week_day_week,
    clock_empty_iso_year_week_day_day,
    clock_empty_iso_year_week_day_hour,
    clock_empty_iso_year_week_day_minute,
    clock_empty_iso_year_week_day_second,
    clock_empty_iso_year_week_day_millisecond,
    clock_empty_iso_year_week_day_microsecond,
    clock_empty_iso_year_week_day_nanosecond,
    abort("Internal error: Invalid precision.")
  )
}

#' @export
vec_ptype2.clock_iso_year_week_day.clock_iso_year_week_day <- function(x, y, ...) {
  ptype2_calendar_and_calendar(x, y, ...)
}

#' @export
vec_cast.clock_iso_year_week_day.clock_iso_year_week_day <- function(x, to, ...) {
  cast_calendar_to_calendar(x, to, ...)
}

# ------------------------------------------------------------------------------

#' @export
calendar_is_precision.clock_iso_year_week_day <- function(x, precision) {
  iso_year_week_day_is_precision(precision)
}

iso_year_week_day_is_precision <- function(precision) {
  if (precision == PRECISION_YEAR || precision == PRECISION_WEEK) {
    TRUE
  } else if (precision >= PRECISION_DAY && precision <= PRECISION_NANOSECOND) {
    TRUE
  } else {
    FALSE
  }
}

# ------------------------------------------------------------------------------

#' @export
invalid_detect.clock_iso_year_week_day <- function(x) {
  precision <- calendar_precision_attribute(x)

  if (precision < PRECISION_WEEK) {
    rep_along(x, FALSE)
  } else {
    year <- field_year(x)
    week <- field_week(x)
    invalid_detect_iso_year_week_day_cpp(year, week)
  }
}

#' @export
invalid_any.clock_iso_year_week_day <- function(x) {
  precision <- calendar_precision_attribute(x)

  if (precision < PRECISION_WEEK) {
    FALSE
  } else {
    year <- field_year(x)
    week <- field_week(x)
    invalid_any_iso_year_week_day_cpp(year, week)
  }
}

#' @export
invalid_count.clock_iso_year_week_day <- function(x) {
  precision <- calendar_precision_attribute(x)

  if (precision < PRECISION_WEEK) {
    0L
  } else {
    year <- field_year(x)
    week <- field_week(x)
    invalid_count_iso_year_week_day_cpp(year, week)
  }
}

#' @export
invalid_resolve.clock_iso_year_week_day <- function(x, ..., invalid = NULL) {
  check_dots_empty()
  precision <- calendar_precision_attribute(x)
  invalid <- validate_invalid(invalid)

  if (precision < PRECISION_WEEK) {
    x
  } else {
    fields <- invalid_resolve_iso_year_week_day_cpp(x, precision, invalid, current_env())
    new_iso_year_week_day_from_fields(fields, precision, names(x))
  }
}

# ------------------------------------------------------------------------------

#' Getters: iso-year-week-day
#'
#' @description
#' These are iso-year-week-day methods for the
#' [getter generics][clock-getters].
#'
#' - `get_year()` returns the ISO year. Note that this can differ from the
#'   Gregorian year.
#'
#' - `get_week()` returns the ISO week of the current ISO year.
#'
#' - `get_day()` returns a value between 1-7 indicating the weekday of the
#'   current ISO week, where 1 = Monday and 7 = Sunday, in line with the
#'   ISO standard.
#'
#' - There are sub-daily getters for extracting more precise components.
#'
#' @param x `[clock_iso_year_week_day]`
#'
#'   A iso-year-week-day to get the component from.
#'
#' @return The component.
#'
#' @name iso-year-week-day-getters
#' @examples
#' x <- iso_year_week_day(2019, 50:52, 1:3)
#' x
#'
#' # Get the ISO week
#' get_week(x)
#'
#' # Gets the weekday, 1 = Monday, 7 = Sunday
#' get_day(x)
#'
#' # Note that the ISO year can differ from the Gregorian year
#' iso <- iso_year_week_day(2019, 1, 1)
#' ymd <- as_year_month_day(iso)
#'
#' get_year(iso)
#' get_year(ymd)
NULL

#' @rdname iso-year-week-day-getters
#' @export
get_year.clock_iso_year_week_day <- function(x) {
  field_year(x)
}

#' @rdname iso-year-week-day-getters
#' @export
get_week.clock_iso_year_week_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_WEEK)
  field_week(x)
}

#' @rdname iso-year-week-day-getters
#' @export
get_day.clock_iso_year_week_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_DAY)
  field_day(x)
}

#' @rdname iso-year-week-day-getters
#' @export
get_hour.clock_iso_year_week_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_HOUR)
  field_hour(x)
}

#' @rdname iso-year-week-day-getters
#' @export
get_minute.clock_iso_year_week_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_MINUTE)
  field_minute(x)
}

#' @rdname iso-year-week-day-getters
#' @export
get_second.clock_iso_year_week_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_SECOND)
  field_second(x)
}

#' @rdname iso-year-week-day-getters
#' @export
get_millisecond.clock_iso_year_week_day <- function(x) {
  calendar_check_exact_precision(x, PRECISION_MILLISECOND)
  field_subsecond(x)
}

#' @rdname iso-year-week-day-getters
#' @export
get_microsecond.clock_iso_year_week_day <- function(x) {
  calendar_check_exact_precision(x, PRECISION_MICROSECOND)
  field_subsecond(x)
}

#' @rdname iso-year-week-day-getters
#' @export
get_nanosecond.clock_iso_year_week_day <- function(x) {
  calendar_check_exact_precision(x, PRECISION_NANOSECOND)
  field_subsecond(x)
}

# ------------------------------------------------------------------------------

#' Setters: iso-year-week-day
#'
#' @description
#' These are iso-year-week-day methods for the
#' [setter generics][clock-setters].
#'
#' - `set_year()` sets the ISO year.
#'
#' - `set_week()` sets the ISO week of the year. Valid values are in the range
#'   of `[1, 53]`.
#'
#' - `set_day()` sets the day of the week. Valid values are in the range of
#'   `[1, 7]`, with 1 = Monday, and 7 = Sunday.
#'
#' - There are sub-daily setters for setting more precise components.
#'
#' @inheritParams rlang::args_dots_empty
#'
#' @param x `[clock_iso_year_week_day]`
#'
#'   A iso-year-week-day vector.
#'
#' @param value `[integer / "last"]`
#'
#'   The value to set the component to.
#'
#'   For `set_week()`, this can also be `"last"` to adjust to the last
#'   week of the current ISO year.
#'
#' @return `x` with the component set.
#'
#' @name iso-year-week-day-setters
#' @examples
#' # Year precision vector
#' x <- iso_year_week_day(2019:2023)
#'
#' # Promote to week precision by setting the week
#' # (Note that some ISO weeks have 52 weeks, and others have 53)
#' x <- set_week(x, "last")
#' x
#'
#' # Set to an invalid week
#' invalid <- set_week(x, 53)
#' invalid
#'
#' # Here are the invalid ones (they only have 52 weeks)
#' invalid[invalid_detect(invalid)]
#'
#' # Resolve the invalid dates by choosing the previous/next valid moment
#' invalid_resolve(invalid, invalid = "previous")
#' invalid_resolve(invalid, invalid = "next")
NULL

#' @rdname iso-year-week-day-setters
#' @export
set_year.clock_iso_year_week_day <- function(x, value, ...) {
  check_dots_empty()
  set_field_iso_year_week_day(x, value, "year")
}

#' @rdname iso-year-week-day-setters
#' @export
set_week.clock_iso_year_week_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_YEAR)
  set_field_iso_year_week_day(x, value, "week")
}

#' @rdname iso-year-week-day-setters
#' @export
set_day.clock_iso_year_week_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_WEEK)
  set_field_iso_year_week_day(x, value, "day")
}

#' @rdname iso-year-week-day-setters
#' @export
set_hour.clock_iso_year_week_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_DAY)
  set_field_iso_year_week_day(x, value, "hour")
}

#' @rdname iso-year-week-day-setters
#' @export
set_minute.clock_iso_year_week_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_HOUR)
  set_field_iso_year_week_day(x, value, "minute")
}

#' @rdname iso-year-week-day-setters
#' @export
set_second.clock_iso_year_week_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_MINUTE)
  set_field_iso_year_week_day(x, value, "second")
}

#' @rdname iso-year-week-day-setters
#' @export
set_millisecond.clock_iso_year_week_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_exact_precision(x, c(PRECISION_SECOND, PRECISION_MILLISECOND))
  set_field_iso_year_week_day(x, value, "millisecond")
}

#' @rdname iso-year-week-day-setters
#' @export
set_microsecond.clock_iso_year_week_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_exact_precision(x, c(PRECISION_SECOND, PRECISION_MICROSECOND))
  set_field_iso_year_week_day(x, value, "microsecond")
}

#' @rdname iso-year-week-day-setters
#' @export
set_nanosecond.clock_iso_year_week_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_exact_precision(x, c(PRECISION_SECOND, PRECISION_NANOSECOND))
  set_field_iso_year_week_day(x, value, "nanosecond")
}

set_field_iso_year_week_day <- function(x, value, component) {
  if (is_last(value) && identical(component, "week")) {
    return(set_field_iso_year_week_day_last(x))
  }

  precision_fields <- calendar_precision_attribute(x)
  precision_value <- iso_year_week_day_component_to_precision(component)
  precision_out <- precision_common2(precision_fields, precision_value)

  names_out <- names(x)

  value <- vec_cast(value, integer())
  value <- unname(value)

  switch(
    component,
    year = check_between_year(value),
    week = check_between_week(value),
    day = check_between_day_of_week(value),
    hour = check_between_hour(value),
    minute = check_between_minute(value),
    second = check_between_second(value),
    millisecond = check_between_subsecond(value, PRECISION_MILLISECOND),
    microsecond = check_between_subsecond(value, PRECISION_MICROSECOND),
    nanosecond = check_between_subsecond(value, PRECISION_NANOSECOND),
    abort("Unknown `component`", .internal = TRUE)
  )

  args <- vec_recycle_common(x = x, value = value)
  args <- df_list_propagate_missing(args)
  x <- args$x
  value <- args$value

  field <- iso_year_week_day_component_to_field(component)

  out <- vec_unstructure(x)
  out[[field]] <- value

  new_iso_year_week_day_from_fields(out, precision_out, names = names_out)
}

set_field_iso_year_week_day_last <- function(x) {
  precision_fields <- calendar_precision_attribute(x)
  precision_out <- precision_common2(precision_fields, PRECISION_WEEK)

  names_out <- names(x)

  year <- field_year(x)
  value <- get_iso_year_week_day_last_cpp(year)

  out <- vec_unstructure(x)
  out[["week"]] <- value

  new_iso_year_week_day_from_fields(out, precision_out, names = names_out)
}

# ------------------------------------------------------------------------------

#' @export
calendar_name.clock_iso_year_week_day <- function(x) {
  "iso_year_week_day"
}

# ------------------------------------------------------------------------------

iso_year_week_day_component_to_precision <- function(component) {
  switch(
    component,
    year = PRECISION_YEAR,
    week = PRECISION_WEEK,
    day = PRECISION_DAY,
    hour = PRECISION_HOUR,
    minute = PRECISION_MINUTE,
    second = PRECISION_SECOND,
    millisecond = PRECISION_MILLISECOND,
    microsecond = PRECISION_MICROSECOND,
    nanosecond = PRECISION_NANOSECOND,
    abort("Internal error: Unknown component name.")
  )
}

iso_year_week_day_component_to_field <- function(component) {
  switch (
    component,
    year = component,
    week = component,
    day = component,
    hour = component,
    minute = component,
    second = component,
    millisecond = "subsecond",
    microsecond = "subsecond",
    nanosecond = "subsecond",
    abort("Internal error: Unknown component name.")
  )
}

# ------------------------------------------------------------------------------

#' @rdname clock-arith
#' @method vec_arith clock_iso_year_week_day
#' @export
vec_arith.clock_iso_year_week_day <- function(op, x, y, ...) {
  UseMethod("vec_arith.clock_iso_year_week_day", y)
}

#' @method vec_arith.clock_iso_year_week_day MISSING
#' @export
vec_arith.clock_iso_year_week_day.MISSING <- function(op, x, y, ...) {
  arith_calendar_and_missing(op, x, y, ...)
}

#' @method vec_arith.clock_iso_year_week_day clock_iso_year_week_day
#' @export
vec_arith.clock_iso_year_week_day.clock_iso_year_week_day <- function(op, x, y, ...) {
  arith_calendar_and_calendar(op, x, y, ..., calendar_minus_calendar_fn = iso_year_week_day_minus_iso_year_week_day)
}

#' @method vec_arith.clock_iso_year_week_day clock_duration
#' @export
vec_arith.clock_iso_year_week_day.clock_duration <- function(op, x, y, ...) {
  arith_calendar_and_duration(op, x, y, ...)
}

#' @method vec_arith.clock_duration clock_iso_year_week_day
#' @export
vec_arith.clock_duration.clock_iso_year_week_day <- function(op, x, y, ...) {
  arith_duration_and_calendar(op, x, y, ...)
}

#' @method vec_arith.clock_iso_year_week_day numeric
#' @export
vec_arith.clock_iso_year_week_day.numeric <- function(op, x, y, ...) {
  arith_calendar_and_numeric(op, x, y, ...)
}

#' @method vec_arith.numeric clock_iso_year_week_day
#' @export
vec_arith.numeric.clock_iso_year_week_day <- function(op, x, y, ...) {
  arith_numeric_and_calendar(op, x, y, ...)
}

iso_year_week_day_minus_iso_year_week_day <- function(op, x, y, ...) {
  args <- vec_recycle_common(x = x, y = y)
  args <- vec_cast_common(!!!args)
  x <- args$x
  y <- args$y

  names <- names_common(x, y)

  precision <- calendar_precision_attribute(x)

  if (precision > PRECISION_YEAR) {
    stop_incompatible_op(op, x, y, ...)
  }

  fields <- iso_year_week_day_minus_iso_year_week_day_cpp(x, y, precision)

  new_duration_from_fields(fields, precision, names = names)
}

# ------------------------------------------------------------------------------

#' Arithmetic: iso-year-week-day
#'
#' @description
#' These are iso-year-week-day methods for the
#' [arithmetic generics][clock-arithmetic].
#'
#' - `add_years()`
#'
#' You cannot add weeks or days to an iso-year-week-day calendar. Adding
#' days is much more efficiently done by converting to a time point first
#' by using [as_naive_time()] or [as_sys_time()]. Adding weeks is equally
#' as efficient as adding 7 days. Additionally, adding weeks to an invalid
#' iso-year-week object containing `iso_year_week_day(2019, 53)` would be
#' undefined, as the 53rd ISO week of 2019 doesn't exist to begin with.
#'
#' @details
#' `x` and `n` are recycled against each other using
#' [tidyverse recycling rules][vctrs::vector_recycling_rules].
#'
#' @inheritParams clock-arithmetic
#'
#' @param x `[clock_iso_year_week_day]`
#'
#'   A iso-year-week-day vector.
#'
#' @return `x` after performing the arithmetic.
#'
#' @name iso-year-week-day-arithmetic
#'
#' @examples
#' x <- iso_year_week_day(2019, 1, 1)
#' add_years(x, 1:2)
NULL

#' @rdname iso-year-week-day-arithmetic
#' @export
add_years.clock_iso_year_week_day <- function(x, n, ...) {
  iso_year_week_day_plus_duration(x, n, PRECISION_YEAR)
}

iso_year_week_day_plus_duration <- function(x,
                                            n,
                                            n_precision,
                                            ...,
                                            error_call = caller_env()) {
  check_dots_empty0(...)

  x_precision <- calendar_precision_attribute(x)

  n <- duration_collect_n(n, n_precision, error_call = error_call)

  size <- vec_size_common(x = x, n = n, .call = error_call)
  args <- vec_recycle_common(x = x, n = n, .size = size)
  x <- args$x
  n <- args$n

  names <- names_common(x, n)

  x <- vec_unstructure(x)

  if (n_precision == PRECISION_YEAR) {
    fields <- iso_year_week_day_plus_years_cpp(x$year, n)
    x$year <- fields$year
  } else {
    abort("Unknown precision.", .internal = TRUE)
  }

  if (x_precision != n_precision) {
    x <- df_list_propagate_missing(x, size = size)
  }

  new_iso_year_week_day_from_fields(x, x_precision, names = names)
}

# ------------------------------------------------------------------------------

#' Convert to iso-year-week-day
#'
#' `as_iso_year_week_day()` converts a vector to the iso-year-week-day
#' calendar. Time points, Dates, POSIXct, and other calendars can all be
#' converted to iso-year-week-day.
#'
#' @inheritParams rlang::args_dots_empty
#'
#' @param x `[vector]`
#'
#'   A vector to convert to iso-year-week-day.
#'
#' @return A iso-year-week-day vector.
#' @export
#' @examples
#' # From Date
#' as_iso_year_week_day(as.Date("2019-01-01"))
#'
#' # From POSIXct, which assumes that the naive time is what should be converted
#' as_iso_year_week_day(as.POSIXct("2019-01-01 02:30:30", "America/New_York"))
#'
#' # From other calendars
#' as_iso_year_week_day(year_quarter_day(2019, quarter = 2, day = 50))
as_iso_year_week_day <- function(x, ...)  {
  UseMethod("as_iso_year_week_day")
}

#' @export
as_iso_year_week_day.default <- function(x, ...) {
  stop_clock_unsupported_conversion(x, "clock_iso_year_week_day")
}

#' @export
as_iso_year_week_day.clock_iso_year_week_day <- function(x, ...) {
  check_dots_empty0(...)
  x
}

# ------------------------------------------------------------------------------

#' @export
as_sys_time.clock_iso_year_week_day <- function(x, ...) {
  check_dots_empty0(...)
  calendar_check_no_invalid(x)
  precision <- calendar_precision_attribute(x)
  fields <- as_sys_time_iso_year_week_day_cpp(x, precision)
  new_sys_time_from_fields(fields, precision, clock_rcrd_names(x))
}

#' @export
as_naive_time.clock_iso_year_week_day <- function(x, ...) {
  check_dots_empty0(...)
  as_naive_time(as_sys_time(x))
}

#' @export
as.character.clock_iso_year_week_day <- function(x, ...) {
  format(x)
}

# ------------------------------------------------------------------------------

#' @export
calendar_leap_year.clock_iso_year_week_day <- function(x) {
  year <- get_year(x)
  iso_year_week_day_leap_year_cpp(year)
}

# ------------------------------------------------------------------------------

#' Grouping: iso-year-week-day
#'
#' @description
#' This is a iso-year-week-day method for the [calendar_group()] generic.
#'
#' Grouping for a iso-year-week-day object can be done at any precision, as
#' long as `x` is at least as precise as `precision`.
#'
#' @inheritParams calendar_group
#'
#' @param x `[clock_iso_year_week_day]`
#'
#'   A iso-year-week-day vector.
#'
#' @param precision `[character(1)]`
#'
#'   One of:
#'
#'   - `"year"`
#'   - `"week"`
#'   - `"day"`
#'   - `"hour"`
#'   - `"minute"`
#'   - `"second"`
#'   - `"millisecond"`
#'   - `"microsecond"`
#'   - `"nanosecond"`
#'
#' @return `x` grouped at the specified `precision`.
#'
#' @name iso-year-week-day-group
#'
#' @export
#' @examples
#' x <- iso_year_week_day(2019, 1:52)
#'
#' # Group by 3 ISO weeks
#' calendar_group(x, "week", n = 3)
#'
#' y <- iso_year_week_day(2000:2020, 1, 1)
#'
#' # Group by 2 ISO years
#' calendar_group(y, "year", n = 2)
calendar_group.clock_iso_year_week_day <- function(x, precision, ..., n = 1L) {
  n <- validate_calendar_group_n(n)
  x <- calendar_narrow(x, precision)

  check_precision(precision)
  precision <- precision_to_integer(precision)

  if (precision == PRECISION_YEAR) {
    value <- get_year(x)
    value <- group_component0(value, n)
    x <- set_year(x, value)
    return(x)
  }
  if (precision == PRECISION_WEEK) {
    value <- get_week(x)
    value <- group_component1(value, n)
    x <- set_week(x, value)
    return(x)
  }
  if (precision == PRECISION_DAY) {
    value <- get_day(x)
    value <- group_component1(value, n)
    x <- set_day(x, value)
    return(x)
  }

  x <- calendar_group_time(x, n, precision)
  x
}

# ------------------------------------------------------------------------------

#' Narrow: iso-year-week-day
#'
#' This is a iso-year-week-day method for the [calendar_narrow()] generic. It
#' narrows a iso-year-week-day vector to the specified `precision`.
#'
#' @inheritParams iso-year-week-day-group
#'
#' @return `x` narrowed to the supplied `precision`.
#'
#' @name iso-year-week-day-narrow
#'
#' @export
#' @examples
#' # Day precision
#' x <- iso_year_week_day(2019, 1, 5)
#' x
#'
#' # Narrowed to week precision
#' calendar_narrow(x, "week")
calendar_narrow.clock_iso_year_week_day <- function(x, precision) {
  check_precision(precision)
  precision <- precision_to_integer(precision)

  out_fields <- list()
  x_fields <- unclass(x)

  if (precision >= PRECISION_YEAR) {
    out_fields[["year"]] <- x_fields[["year"]]
  }
  if (precision >= PRECISION_WEEK) {
    out_fields[["week"]] <- x_fields[["week"]]
  }
  if (precision >= PRECISION_DAY) {
    out_fields[["day"]] <- x_fields[["day"]]
  }

  out_fields <- calendar_narrow_time(out_fields, precision, x_fields)

  new_iso_year_week_day_from_fields(out_fields, precision, names = names(x))
}

# ------------------------------------------------------------------------------

#' Widen: iso-year-week-day
#'
#' This is a iso-year-week-day method for the [calendar_widen()] generic. It
#' widens a iso-year-week-day vector to the specified `precision`.
#'
#' @inheritParams iso-year-week-day-group
#'
#' @return `x` widened to the supplied `precision`.
#'
#' @name iso-year-week-day-widen
#'
#' @export
#' @examples
#' # Week precision
#' x <- iso_year_week_day(2019, 1)
#' x
#'
#' # Widen to day precision
#' # In the ISO calendar, the first day of the week is a Monday
#' calendar_widen(x, "day")
#'
#' # Or second precision
#' sec <- calendar_widen(x, "second")
#' sec
calendar_widen.clock_iso_year_week_day <- function(x, precision) {
  x_precision <- calendar_precision_attribute(x)

  check_precision(precision)
  precision <- precision_to_integer(precision)

  if (precision >= PRECISION_WEEK && x_precision < PRECISION_WEEK) {
    x <- set_week(x, 1L)
  }
  if (precision >= PRECISION_DAY && x_precision < PRECISION_DAY) {
    x <- set_day(x, 1L)
  }

  x <- calendar_widen_time(x, x_precision, precision)

  x
}

# ------------------------------------------------------------------------------

#' Boundaries: iso-year-week-day
#'
#' This is an iso-year-week-day method for the [calendar_start()] and
#' [calendar_end()] generics. They adjust components of a calendar to the
#' start or end of a specified `precision`.
#'
#' @inheritParams iso-year-week-day-group
#'
#' @return `x` at the same precision, but with some components altered to be
#'   at the boundary value.
#'
#' @name iso-year-week-day-boundary
#'
#' @examples
#' x <- iso_year_week_day(2019:2020, 5, 6, 10)
#' x
#'
#' # Compute the last moment of the last iso week of the year
#' calendar_end(x, "year")
#'
#' # Compare that to just setting the week to `"last"`,
#' # which doesn't affect the other components
#' set_week(x, "last")
NULL

#' @rdname iso-year-week-day-boundary
#' @export
calendar_start.clock_iso_year_week_day <- function(x, precision) {
  x_precision <- calendar_precision_attribute(x)

  check_precision(precision)
  precision <- precision_to_integer(precision)

  calendar_start_end_checks(x, x_precision, precision, "start")

  if (precision <= PRECISION_YEAR && x_precision > PRECISION_YEAR) {
    x <- set_week(x, 1L)
  }
  if (precision <= PRECISION_WEEK && x_precision > PRECISION_WEEK) {
    x <- set_day(x, 1L)
  }

  x <- calendar_start_time(x, x_precision, precision)

  x
}

#' @rdname iso-year-week-day-boundary
#' @export
calendar_end.clock_iso_year_week_day <- function(x, precision) {
  x_precision <- calendar_precision_attribute(x)

  check_precision(precision)
  precision <- precision_to_integer(precision)

  calendar_start_end_checks(x, x_precision, precision, "end")

  if (precision <= PRECISION_YEAR && x_precision > PRECISION_YEAR) {
    x <- set_week(x, "last")
  }
  if (precision <= PRECISION_WEEK && x_precision > PRECISION_WEEK) {
    x <- set_day(x, 7L)
  }

  x <- calendar_end_time(x, x_precision, precision)

  x
}

# ------------------------------------------------------------------------------

#' Counting: iso-year-week-day
#'
#' This is an iso-year-week-day method for the [calendar_count_between()]
#' generic. It counts the number of `precision` units between `start` and `end`
#' (i.e., the number of ISO years).
#'
#' @inheritParams calendar-count-between
#'
#' @param start,end `[clock_iso_year_week_day]`
#'
#'   A pair of iso-year-week-day vectors. These will be recycled to their
#'   common size.
#'
#' @param precision `[character(1)]`
#'
#'   One of:
#'
#'   - `"year"`
#'
#' @inherit calendar-count-between return
#'
#' @name iso-year-week-day-count-between
#'
#' @export
#' @examples
#' # Compute the number of whole ISO years between two dates
#' x <- iso_year_week_day(2001, 1, 2)
#' y <- iso_year_week_day(2021, 1, c(1, 3))
#' calendar_count_between(x, y, "year")
calendar_count_between.clock_iso_year_week_day <- function(start,
                                                           end,
                                                           precision,
                                                           ...,
                                                           n = 1L) {
  NextMethod()
}

#' @export
calendar_count_between_standardize_precision_n.clock_iso_year_week_day <- function(x,
                                                                                   precision,
                                                                                   n) {
  check_precision(precision)
  precision_int <- precision_to_integer(precision)

  allowed_precisions <- c(PRECISION_YEAR)

  if (!(precision_int %in% allowed_precisions)) {
    abort("`precision` must be one of: 'year'.")
  }

  list(precision = precision, n = n)
}

#' @export
calendar_count_between_compute.clock_iso_year_week_day <- function(start,
                                                                   end,
                                                                   precision) {
  check_precision(precision)
  precision <- precision_to_integer(precision)

  if (precision == PRECISION_YEAR) {
    out <- get_year(end) - get_year(start)
    return(out)
  }

  abort("Internal error: `precision` should be 'year' at this point.")
}

#' @export
calendar_count_between_proxy_compare.clock_iso_year_week_day <- function(start,
                                                                         end,
                                                                         precision) {
  check_precision(precision)
  precision <- precision_to_integer(precision)

  start <- vec_proxy_compare(start)
  end <- vec_proxy_compare(end)

  if (precision >= PRECISION_YEAR) {
    start$year <- NULL
    end$year <- NULL
  }

  list(start = start, end = end)
}

# ------------------------------------------------------------------------------

#' Sequences: iso-year-week-day
#'
#' @description
#' This is a iso-year-week-day method for the [seq()] generic.
#'
#' Sequences can only be generated for `"year"` precision
#' iso-year-week-day vectors. If you need to generate week-based sequences,
#' you'll have to convert to a time point first.
#'
#' When calling `seq()`, exactly two of the following must be specified:
#' - `to`
#' - `by`
#' - Either `length.out` or `along.with`
#'
#' @inheritParams seq.clock_duration
#'
#' @param from `[clock_iso_year_week_day(1)]`
#'
#'   A `"year"` precision iso-year-week-day to start the sequence
#'   from.
#'
#'   `from` is always included in the result.
#'
#' @param to `[clock_iso_year_week_day(1) / NULL]`
#'
#'   A `"year"` precision iso-year-week-day to stop the sequence
#'   at.
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
#' # Yearly sequence
#' x <- seq(iso_year_week_day(2020), iso_year_week_day(2026), by = 2)
#' x
#'
#' # Which we can then set the week of.
#' # Some years have 53 ISO weeks, some have 52.
#' set_week(x, "last")
seq.clock_iso_year_week_day <- function(from,
                                        to = NULL,
                                        by = NULL,
                                        length.out = NULL,
                                        along.with = NULL,
                                        ...) {
  precision <- calendar_precision_attribute(from)

  if (precision > PRECISION_YEAR) {
    abort("`from` must be 'year' precision.")
  }

  seq_impl(
    from = from,
    to = to,
    by = by,
    length.out = length.out,
    along.with = along.with,
    precision = precision,
    ...
  )
}

# ------------------------------------------------------------------------------

#' @export
clock_minimum.clock_iso_year_week_day <- function(x) {
  switch(
    calendar_precision_attribute(x) + 1L,
    clock_minimum_iso_year_week_day_year,
    abort("Invalid precision", .internal = TRUE),
    abort("Invalid precision", .internal = TRUE),
    clock_minimum_iso_year_week_day_week,
    clock_minimum_iso_year_week_day_day,
    clock_minimum_iso_year_week_day_hour,
    clock_minimum_iso_year_week_day_minute,
    clock_minimum_iso_year_week_day_second,
    clock_minimum_iso_year_week_day_millisecond,
    clock_minimum_iso_year_week_day_microsecond,
    clock_minimum_iso_year_week_day_nanosecond,
    abort("Invalid precision", .internal = TRUE)
  )
}

#' @export
clock_maximum.clock_iso_year_week_day <- function(x) {
  switch(
    calendar_precision_attribute(x) + 1L,
    clock_maximum_iso_year_week_day_year,
    abort("Invalid precision", .internal = TRUE),
    abort("Invalid precision", .internal = TRUE),
    clock_maximum_iso_year_week_day_week,
    clock_maximum_iso_year_week_day_day,
    clock_maximum_iso_year_week_day_hour,
    clock_maximum_iso_year_week_day_minute,
    clock_maximum_iso_year_week_day_second,
    clock_maximum_iso_year_week_day_millisecond,
    clock_maximum_iso_year_week_day_microsecond,
    clock_maximum_iso_year_week_day_nanosecond,
    abort("Invalid precision", .internal = TRUE)
  )
}

iso_year_week_day_minimum <- function(precision) {
  calendar_minimum(precision, iso_year_week_day(clock_calendar_year_minimum))
}
iso_year_week_day_maximum <- function(precision) {
  calendar_maximum(precision, iso_year_week_day(clock_calendar_year_maximum))
}

# ------------------------------------------------------------------------------

clock_init_iso_year_week_day_utils <- function(env) {
  year <- iso_year_week_day(integer())

  assign("clock_empty_iso_year_week_day_year", year, envir = env)
  assign("clock_empty_iso_year_week_day_week", calendar_widen(year, "week"), envir = env)
  assign("clock_empty_iso_year_week_day_day", calendar_widen(year, "day"), envir = env)
  assign("clock_empty_iso_year_week_day_hour", calendar_widen(year, "hour"), envir = env)
  assign("clock_empty_iso_year_week_day_minute", calendar_widen(year, "minute"), envir = env)
  assign("clock_empty_iso_year_week_day_second", calendar_widen(year, "second"), envir = env)
  assign("clock_empty_iso_year_week_day_millisecond", calendar_widen(year, "millisecond"), envir = env)
  assign("clock_empty_iso_year_week_day_microsecond", calendar_widen(year, "microsecond"), envir = env)
  assign("clock_empty_iso_year_week_day_nanosecond", calendar_widen(year, "nanosecond"), envir = env)

  assign("clock_minimum_iso_year_week_day_year", iso_year_week_day_minimum("year"), envir = env)
  assign("clock_minimum_iso_year_week_day_week", iso_year_week_day_minimum("week"), envir = env)
  assign("clock_minimum_iso_year_week_day_day", iso_year_week_day_minimum("day"), envir = env)
  assign("clock_minimum_iso_year_week_day_hour", iso_year_week_day_minimum("hour"), envir = env)
  assign("clock_minimum_iso_year_week_day_minute", iso_year_week_day_minimum("minute"), envir = env)
  assign("clock_minimum_iso_year_week_day_second", iso_year_week_day_minimum("second"), envir = env)
  assign("clock_minimum_iso_year_week_day_millisecond", iso_year_week_day_minimum("millisecond"), envir = env)
  assign("clock_minimum_iso_year_week_day_microsecond", iso_year_week_day_minimum("microsecond"), envir = env)
  assign("clock_minimum_iso_year_week_day_nanosecond", iso_year_week_day_minimum("nanosecond"), envir = env)

  assign("clock_maximum_iso_year_week_day_year", iso_year_week_day_maximum("year"), envir = env)
  assign("clock_maximum_iso_year_week_day_week", iso_year_week_day_maximum("week"), envir = env)
  assign("clock_maximum_iso_year_week_day_day", iso_year_week_day_maximum("day"), envir = env)
  assign("clock_maximum_iso_year_week_day_hour", iso_year_week_day_maximum("hour"), envir = env)
  assign("clock_maximum_iso_year_week_day_minute", iso_year_week_day_maximum("minute"), envir = env)
  assign("clock_maximum_iso_year_week_day_second", iso_year_week_day_maximum("second"), envir = env)
  assign("clock_maximum_iso_year_week_day_millisecond", iso_year_week_day_maximum("millisecond"), envir = env)
  assign("clock_maximum_iso_year_week_day_microsecond", iso_year_week_day_maximum("microsecond"), envir = env)
  assign("clock_maximum_iso_year_week_day_nanosecond", iso_year_week_day_maximum("nanosecond"), envir = env)

  invisible(NULL)
}
