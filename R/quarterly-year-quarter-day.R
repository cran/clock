#' Calendar: year-quarter-day
#'
#' `year_quarter_day()` constructs a calendar from the fiscal year, fiscal
#' quarter, and day of the quarter, along with a value determining which
#' month the fiscal year `start`s in.
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
#'   The fiscal year. Values `[-32767, 32767]` are generally allowed.
#'
#' @param quarter `[integer / NULL]`
#'
#'   The fiscal quarter. Values `[1, 4]` are allowed.
#'
#' @param day `[integer / "last" / NULL]`
#'
#'   The day of the quarter. Values `[1, 92]` are allowed.
#'
#'   If `"last"`, the last day of the quarter is returned.
#'
#' @param start `[integer(1) / NULL]`
#'
#'   The month to start the fiscal year in. 1 = January and 12 = December.
#'
#'   If `NULL`, a `start` of January will be used.
#'
#' @return A year-quarter-day calendar vector.
#'
#' @export
#' @examples
#' # Year-quarter type
#' x <- year_quarter_day(2019, 1:4)
#' x
#'
#' add_quarters(x, 2)
#'
#' # Set the day to the last day of the quarter
#' x <- set_day(x, "last")
#' x
#'
#' # Start the fiscal year in June
#' june <- 6L
#' y <- year_quarter_day(2019, 1:4, "last", start = june)
#'
#' # Compare the year-month-day values that result from having different
#' # fiscal year start months
#' as_year_month_day(x)
#' as_year_month_day(y)
year_quarter_day <- function(
  year,
  quarter = NULL,
  day = NULL,
  hour = NULL,
  minute = NULL,
  second = NULL,
  subsecond = NULL,
  ...,
  start = NULL,
  subsecond_precision = NULL
) {
  check_dots_empty()

  start <- quarterly_validate_start(start)

  # Stop on the first `NULL` argument
  if (is_null(quarter)) {
    precision <- PRECISION_YEAR
    fields <- list(year = year)
  } else if (is_null(day)) {
    precision <- PRECISION_QUARTER
    fields <- list(year = year, quarter = quarter)
  } else if (is_null(hour)) {
    precision <- PRECISION_DAY
    fields <- list(year = year, quarter = quarter, day = day)
  } else if (is_null(minute)) {
    precision <- PRECISION_HOUR
    fields <- list(year = year, quarter = quarter, day = day, hour = hour)
  } else if (is_null(second)) {
    precision <- PRECISION_MINUTE
    fields <- list(
      year = year,
      quarter = quarter,
      day = day,
      hour = hour,
      minute = minute
    )
  } else if (is_null(subsecond)) {
    precision <- PRECISION_SECOND
    fields <- list(
      year = year,
      quarter = quarter,
      day = day,
      hour = hour,
      minute = minute,
      second = second
    )
  } else {
    calendar_check_subsecond_precision(subsecond_precision)
    precision <- precision_to_integer(subsecond_precision)
    fields <- list(
      year = year,
      quarter = quarter,
      day = day,
      hour = hour,
      minute = minute,
      second = second,
      subsecond = subsecond
    )
  }

  if (is_last(fields$day)) {
    fields$day <- 1L
    last <- TRUE
  } else {
    last <- FALSE
  }

  fields <- vec_cast_common(!!!fields, .to = integer())

  if (precision >= PRECISION_YEAR) {
    check_between_year(fields$year, arg = "year")
  }
  if (precision >= PRECISION_QUARTER) {
    check_between_quarter(fields$quarter, arg = "quarter")
  }
  if (precision >= PRECISION_DAY) {
    check_between_day_of_quarter(fields$day, arg = "day")
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
  out <- new_year_quarter_day_from_fields(fields, precision, start, names)

  if (last) {
    out <- set_day(out, "last")
  }

  out
}

# ------------------------------------------------------------------------------

#' @export
vec_proxy.clock_year_quarter_day <- function(x, ...) {
  .Call(`_clock_clock_rcrd_proxy`, x)
}

#' @export
vec_restore.clock_year_quarter_day <- function(x, to, ...) {
  .Call(`_clock_year_quarter_day_restore`, x, to)
}

# ------------------------------------------------------------------------------

#' @export
format.clock_year_quarter_day <- function(x, ...) {
  out <- format_year_quarter_day_cpp(
    x,
    calendar_precision_attribute(x),
    quarterly_start(x)
  )
  names(out) <- names(x)
  out
}

#' @export
vec_ptype_full.clock_year_quarter_day <- function(x, ...) {
  start <- quarterly_start(x)
  start <- quarterly_start_prettify(start, abbreviate = FALSE)
  class <- paste0("year_quarter_day<", start, ">")
  calendar_ptype_full(x, class)
}

#' @export
vec_ptype_abbr.clock_year_quarter_day <- function(x, ...) {
  start <- quarterly_start(x)
  start <- quarterly_start_prettify(start, abbreviate = TRUE)
  class <- paste0("yqd<", start, ">")
  calendar_ptype_abbr(x, class)
}

# ------------------------------------------------------------------------------

#' Is `x` a year-quarter-day?
#'
#' Check if `x` is a year-quarter-day.
#'
#' @param x `[object]`
#'
#'   An object.
#'
#' @return Returns `TRUE` if `x` inherits from `"clock_year_quarter_day"`,
#'   otherwise returns `FALSE`.
#'
#' @export
#' @examples
#' is_year_quarter_day(year_quarter_day(2019))
is_year_quarter_day <- function(x) {
  inherits(x, "clock_year_quarter_day")
}

# ------------------------------------------------------------------------------

#' @export
vec_ptype.clock_year_quarter_day <- function(x, ...) {
  names <- NULL
  precision <- calendar_precision_attribute(x)
  start <- quarterly_start(x)

  f <- integer()

  fields <- switch(
    precision + 1L,
    list(year = f),
    list(year = f, quarter = f),
    abort("Internal error: Invalid precision"),
    abort("Internal error: Invalid precision"),
    list(
      year = f,
      quarter = f,
      day = f
    ),
    list(
      year = f,
      quarter = f,
      day = f,
      hour = f
    ),
    list(
      year = f,
      quarter = f,
      day = f,
      hour = f,
      minute = f
    ),
    list(
      year = f,
      quarter = f,
      day = f,
      hour = f,
      minute = f,
      second = f
    ),
    list(
      year = f,
      quarter = f,
      day = f,
      hour = f,
      minute = f,
      second = f,
      subsecond = f
    ),
    list(
      year = f,
      quarter = f,
      day = f,
      hour = f,
      minute = f,
      second = f,
      subsecond = f
    ),
    list(
      year = f,
      quarter = f,
      day = f,
      hour = f,
      minute = f,
      second = f,
      subsecond = f
    ),
    abort("Internal error: Invalid precision.")
  )

  new_year_quarter_day_from_fields(fields, precision, start, names)
}

#' @export
vec_ptype2.clock_year_quarter_day.clock_year_quarter_day <- function(
  x,
  y,
  ...
) {
  if (quarterly_start(x) != quarterly_start(y)) {
    stop_incompatible_type(
      x,
      y,
      ...,
      details = "Can't combine quarterly types with different `start`s."
    )
  }

  ptype2_calendar_and_calendar(x, y, ...)
}

#' @export
vec_cast.clock_year_quarter_day.clock_year_quarter_day <- function(x, to, ...) {
  if (quarterly_start(x) != quarterly_start(to)) {
    stop_incompatible_cast(
      x,
      to,
      ...,
      details = "Can't cast between quarterly types with different `start`s."
    )
  }

  cast_calendar_to_calendar(x, to, ...)
}

# ------------------------------------------------------------------------------

#' @export
calendar_is_precision.clock_year_quarter_day <- function(x, precision) {
  year_quarter_day_is_precision(precision)
}

year_quarter_day_is_precision <- function(precision) {
  if (precision == PRECISION_YEAR || precision == PRECISION_QUARTER) {
    TRUE
  } else if (precision >= PRECISION_DAY && precision <= PRECISION_NANOSECOND) {
    TRUE
  } else {
    FALSE
  }
}

# ------------------------------------------------------------------------------

#' @export
invalid_detect.clock_year_quarter_day <- function(x) {
  precision <- calendar_precision_attribute(x)
  start <- quarterly_start(x)

  if (precision < PRECISION_DAY) {
    rep_along(x, FALSE)
  } else {
    year <- field_year(x)
    quarter <- field_quarter(x)
    day <- field_day(x)
    invalid_detect_year_quarter_day_cpp(year, quarter, day, start)
  }
}

#' @export
invalid_any.clock_year_quarter_day <- function(x) {
  precision <- calendar_precision_attribute(x)
  start <- quarterly_start(x)

  if (precision < PRECISION_DAY) {
    FALSE
  } else {
    year <- field_year(x)
    quarter <- field_quarter(x)
    day <- field_day(x)
    invalid_any_year_quarter_day_cpp(year, quarter, day, start)
  }
}

#' @export
invalid_count.clock_year_quarter_day <- function(x) {
  precision <- calendar_precision_attribute(x)
  start <- quarterly_start(x)

  if (precision < PRECISION_DAY) {
    0L
  } else {
    year <- field_year(x)
    quarter <- field_quarter(x)
    day <- field_day(x)
    invalid_count_year_quarter_day_cpp(year, quarter, day, start)
  }
}

#' @export
invalid_resolve.clock_year_quarter_day <- function(x, ..., invalid = NULL) {
  check_dots_empty()
  precision <- calendar_precision_attribute(x)
  start <- quarterly_start(x)
  invalid <- validate_invalid(invalid)

  if (precision < PRECISION_DAY) {
    x
  } else {
    fields <- invalid_resolve_year_quarter_day_cpp(
      x,
      precision,
      start,
      invalid,
      current_env()
    )
    new_year_quarter_day_from_fields(fields, precision, start, names = names(x))
  }
}

# ------------------------------------------------------------------------------

#' Getters: year-quarter-day
#'
#' @description
#' These are year-quarter-day methods for the
#' [getter generics][clock-getters].
#'
#' - `get_year()` returns the fiscal year. Note that this can differ from the
#'   Gregorian year if `start != 1L`.
#'
#' - `get_quarter()` returns the fiscal quarter as a value between 1-4.
#'
#' - `get_day()` returns the day of the fiscal quarter as a value between 1-92.
#'
#' - There are sub-daily getters for extracting more precise components.
#'
#' @param x `[clock_year_quarter_day]`
#'
#'   A year-quarter-day to get the component from.
#'
#' @return The component.
#'
#' @name year-quarter-day-getters
#' @examples
#' x <- year_quarter_day(2020, 1:4)
#'
#' get_quarter(x)
#'
#' # Set and then get the last day of the quarter
#' x <- set_day(x, "last")
#' get_day(x)
#'
#' # Start the fiscal year in November and choose the 50th day in
#' # each quarter of 2020
#' november <- 11
#' y <- year_quarter_day(2020, 1:4, 50, start = 11)
#' y
#'
#' get_day(y)
#'
#' # What does that map to in year-month-day?
#' as_year_month_day(y)
NULL

#' @rdname year-quarter-day-getters
#' @export
get_year.clock_year_quarter_day <- function(x) {
  field_year(x)
}

#' @rdname year-quarter-day-getters
#' @export
get_quarter.clock_year_quarter_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_QUARTER)
  field_quarter(x)
}

#' @rdname year-quarter-day-getters
#' @export
get_day.clock_year_quarter_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_DAY)
  field_day(x)
}

#' @rdname year-quarter-day-getters
#' @export
get_hour.clock_year_quarter_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_HOUR)
  field_hour(x)
}

#' @rdname year-quarter-day-getters
#' @export
get_minute.clock_year_quarter_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_MINUTE)
  field_minute(x)
}

#' @rdname year-quarter-day-getters
#' @export
get_second.clock_year_quarter_day <- function(x) {
  calendar_check_minimum_precision(x, PRECISION_SECOND)
  field_second(x)
}

#' @rdname year-quarter-day-getters
#' @export
get_millisecond.clock_year_quarter_day <- function(x) {
  calendar_check_exact_precision(x, PRECISION_MILLISECOND)
  field_subsecond(x)
}

#' @rdname year-quarter-day-getters
#' @export
get_microsecond.clock_year_quarter_day <- function(x) {
  calendar_check_exact_precision(x, PRECISION_MICROSECOND)
  field_subsecond(x)
}

#' @rdname year-quarter-day-getters
#' @export
get_nanosecond.clock_year_quarter_day <- function(x) {
  calendar_check_exact_precision(x, PRECISION_NANOSECOND)
  field_subsecond(x)
}

# ------------------------------------------------------------------------------

#' Setters: year-quarter-day
#'
#' @description
#' These are year-quarter-day methods for the
#' [setter generics][clock-setters].
#'
#' - `set_year()` sets the fiscal year.
#'
#' - `set_quarter()` sets the fiscal quarter of the year.
#'   Valid values are in the range of `[1, 4]`.
#'
#' - `set_day()` sets the day of the fiscal quarter.
#'   Valid values are in the range of `[1, 92]`.
#'
#' - There are sub-daily setters for setting more precise components.
#'
#' @inheritParams rlang::args_dots_empty
#'
#' @param x `[clock_year_quarter_day]`
#'
#'   A year-quarter-day vector.
#'
#' @param value `[integer / "last"]`
#'
#'   The value to set the component to.
#'
#'   For `set_day()`, this can also be `"last"` to adjust to the last
#'   day of the current fiscal quarter.
#'
#' @return `x` with the component set.
#'
#' @name year-quarter-day-setters
#' @examples
#' library(magrittr)
#'
#' # Quarter precision vector
#' x <- year_quarter_day(2019, 1:4)
#' x
#'
#' # Promote to day precision by setting the day
#' x <- set_day(x, 1)
#' x
#'
#' # Or set to the last day of the quarter
#' x <- set_day(x, "last")
#' x
#'
#' # What year-month-day is this?
#' as_year_month_day(x)
#'
#' # Set to an invalid day of the quarter
#' # (not all quarters have 92 days)
#' invalid <- set_day(x, 92)
#' invalid
#'
#' # Here are the invalid ones
#' invalid[invalid_detect(invalid)]
#'
#' # Resolve the invalid dates by choosing the previous/next valid moment
#' invalid_resolve(invalid, invalid = "previous")
#' invalid_resolve(invalid, invalid = "next")
#'
#' # Or resolve by "overflowing" by the number of days that you have
#' # gone past the last valid day
#' invalid_resolve(invalid, invalid = "overflow")
#'
#' # This is similar to
#' days <- get_day(invalid) - 1L
#' invalid %>%
#'   set_day(1) %>%
#'   as_naive_time() %>%
#'   add_days(days) %>%
#'   as_year_quarter_day()
NULL

#' @rdname year-quarter-day-setters
#' @export
set_year.clock_year_quarter_day <- function(x, value, ...) {
  check_dots_empty()
  set_field_year_quarter_day(x, value, "year")
}

#' @rdname year-quarter-day-setters
#' @export
set_quarter.clock_year_quarter_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_YEAR)
  set_field_year_quarter_day(x, value, "quarter")
}

#' @rdname year-quarter-day-setters
#' @export
set_day.clock_year_quarter_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_QUARTER)
  set_field_year_quarter_day(x, value, "day")
}

#' @rdname year-quarter-day-setters
#' @export
set_hour.clock_year_quarter_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_DAY)
  set_field_year_quarter_day(x, value, "hour")
}

#' @rdname year-quarter-day-setters
#' @export
set_minute.clock_year_quarter_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_HOUR)
  set_field_year_quarter_day(x, value, "minute")
}

#' @rdname year-quarter-day-setters
#' @export
set_second.clock_year_quarter_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_minimum_precision(x, PRECISION_MINUTE)
  set_field_year_quarter_day(x, value, "second")
}

#' @rdname year-quarter-day-setters
#' @export
set_millisecond.clock_year_quarter_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_exact_precision(x, c(PRECISION_SECOND, PRECISION_MILLISECOND))
  set_field_year_quarter_day(x, value, "millisecond")
}

#' @rdname year-quarter-day-setters
#' @export
set_microsecond.clock_year_quarter_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_exact_precision(x, c(PRECISION_SECOND, PRECISION_MICROSECOND))
  set_field_year_quarter_day(x, value, "microsecond")
}

#' @rdname year-quarter-day-setters
#' @export
set_nanosecond.clock_year_quarter_day <- function(x, value, ...) {
  check_dots_empty()
  calendar_check_exact_precision(x, c(PRECISION_SECOND, PRECISION_NANOSECOND))
  set_field_year_quarter_day(x, value, "nanosecond")
}

set_field_year_quarter_day <- function(x, value, component) {
  if (is_last(value) && identical(component, "day")) {
    return(set_field_year_quarter_day_last(x))
  }

  precision_fields <- calendar_precision_attribute(x)
  precision_value <- year_quarter_day_component_to_precision(component)
  precision_out <- precision_common2(precision_fields, precision_value)

  start_out <- quarterly_start(x)
  names_out <- names(x)

  value <- vec_cast(value, integer())
  value <- unname(value)

  switch(
    component,
    year = check_between_year(value),
    quarter = check_between_quarter(value),
    day = check_between_day_of_quarter(value),
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

  field <- year_quarter_day_component_to_field(component)

  out <- vec_unstructure(x)
  out[[field]] <- value

  new_year_quarter_day_from_fields(
    out,
    precision_out,
    start_out,
    names = names_out
  )
}

set_field_year_quarter_day_last <- function(x) {
  precision_fields <- calendar_precision_attribute(x)
  precision_out <- precision_common2(precision_fields, PRECISION_DAY)

  start_out <- quarterly_start(x)
  names_out <- names(x)

  year <- field_year(x)
  quarter <- field_quarter(x)
  value <- get_year_quarter_day_last_cpp(year, quarter, start_out)

  out <- vec_unstructure(x)
  out[["day"]] <- value

  new_year_quarter_day_from_fields(
    out,
    precision_out,
    start_out,
    names = names_out
  )
}

# ------------------------------------------------------------------------------

#' @export
calendar_name.clock_year_quarter_day <- function(x) {
  "year_quarter_day"
}

# ------------------------------------------------------------------------------

year_quarter_day_component_to_precision <- function(component) {
  switch(
    component,
    year = PRECISION_YEAR,
    quarter = PRECISION_QUARTER,
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

year_quarter_day_component_to_field <- function(component) {
  switch(
    component,
    year = component,
    quarter = component,
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
#' @method vec_arith clock_year_quarter_day
#' @export
vec_arith.clock_year_quarter_day <- function(op, x, y, ...) {
  UseMethod("vec_arith.clock_year_quarter_day", y)
}

#' @method vec_arith.clock_year_quarter_day MISSING
#' @export
vec_arith.clock_year_quarter_day.MISSING <- function(op, x, y, ...) {
  arith_calendar_and_missing(op, x, y, ...)
}

#' @method vec_arith.clock_year_quarter_day clock_year_quarter_day
#' @export
vec_arith.clock_year_quarter_day.clock_year_quarter_day <- function(
  op,
  x,
  y,
  ...
) {
  arith_calendar_and_calendar(
    op,
    x,
    y,
    ...,
    calendar_minus_calendar_fn = year_quarter_day_minus_year_quarter_day
  )
}

#' @method vec_arith.clock_year_quarter_day clock_duration
#' @export
vec_arith.clock_year_quarter_day.clock_duration <- function(op, x, y, ...) {
  arith_calendar_and_duration(op, x, y, ...)
}

#' @method vec_arith.clock_duration clock_year_quarter_day
#' @export
vec_arith.clock_duration.clock_year_quarter_day <- function(op, x, y, ...) {
  arith_duration_and_calendar(op, x, y, ...)
}

#' @method vec_arith.clock_year_quarter_day numeric
#' @export
vec_arith.clock_year_quarter_day.numeric <- function(op, x, y, ...) {
  arith_calendar_and_numeric(op, x, y, ...)
}

#' @method vec_arith.numeric clock_year_quarter_day
#' @export
vec_arith.numeric.clock_year_quarter_day <- function(op, x, y, ...) {
  arith_numeric_and_calendar(op, x, y, ...)
}

year_quarter_day_minus_year_quarter_day <- function(op, x, y, ...) {
  args <- vec_recycle_common(x = x, y = y)
  args <- vec_cast_common(!!!args)
  x <- args$x
  y <- args$y

  names <- names_common(x, y)

  start <- quarterly_start(x)
  precision <- calendar_precision_attribute(x)

  if (precision > PRECISION_QUARTER) {
    stop_incompatible_op(op, x, y, ...)
  }

  fields <- year_quarter_day_minus_year_quarter_day_cpp(x, y, precision, start)

  new_duration_from_fields(fields, precision, names = names)
}

# ------------------------------------------------------------------------------

#' Arithmetic: year-quarter-day
#'
#' @description
#' These are year-quarter-day methods for the
#' [arithmetic generics][clock-arithmetic].
#'
#' - `add_years()`
#'
#' - `add_quarters()`
#'
#' Notably, _you cannot add days to a year-quarter-day_. For day-based
#' arithmetic, first convert to a time point with [as_naive_time()] or
#' [as_sys_time()].
#'
#' @details
#' `x` and `n` are recycled against each other using
#' [tidyverse recycling rules][vctrs::vector_recycling_rules].
#'
#' @inheritParams clock-arithmetic
#'
#' @param x `[clock_year_quarter_day]`
#'
#'   A year-quarter-day vector.
#'
#' @return `x` after performing the arithmetic.
#'
#' @name year-quarter-day-arithmetic
#'
#' @examples
#' x <- year_quarter_day(2019, 1:3)
#' x
#'
#' add_quarters(x, 2)
#'
#' # Make the fiscal year start in March
#' y <- year_quarter_day(2019, 1:2, 1, start = 3)
#' y
#'
#' add_quarters(y, 1)
#'
#' # What year-month-day does this correspond to?
#' # Note that the fiscal year doesn't necessarily align with the Gregorian
#' # year!
#' as_year_month_day(add_quarters(y, 1))
NULL

#' @rdname year-quarter-day-arithmetic
#' @export
add_years.clock_year_quarter_day <- function(x, n, ...) {
  year_quarter_day_plus_duration(x, n, PRECISION_YEAR)
}

#' @rdname year-quarter-day-arithmetic
#' @export
add_quarters.clock_year_quarter_day <- function(x, n, ...) {
  calendar_check_minimum_precision(x, PRECISION_QUARTER)
  year_quarter_day_plus_duration(x, n, PRECISION_QUARTER)
}

year_quarter_day_plus_duration <- function(
  x,
  n,
  n_precision,
  ...,
  error_call = caller_env()
) {
  check_dots_empty0(...)

  start <- quarterly_start(x)
  x_precision <- calendar_precision_attribute(x)

  n <- duration_collect_n(n, n_precision, error_call = error_call)

  size <- vec_size_common(x = x, n = n, .call = error_call)
  args <- vec_recycle_common(x = x, n = n, .size = size)
  x <- args$x
  n <- args$n

  names <- names_common(x, n)

  x <- vec_unstructure(x)

  if (n_precision == PRECISION_YEAR) {
    fields <- year_quarter_day_plus_years_cpp(x$year, start, n)
    x$year <- fields$year
  } else if (n_precision == PRECISION_QUARTER) {
    fields <- year_quarter_day_plus_quarters_cpp(x$year, x$quarter, start, n)
    x$year <- fields$year
    x$quarter <- fields$quarter
  } else {
    abort("Unknown precision.", .internal = TRUE)
  }

  if (x_precision != n_precision) {
    x <- df_list_propagate_missing(x, size = size)
  }

  new_year_quarter_day_from_fields(x, x_precision, start, names = names)
}

# ------------------------------------------------------------------------------

#' @export
diff.clock_year_quarter_day <- function(x, lag = 1L, differences = 1L, ...) {
  calendar_check_maximum_precision(x, PRECISION_QUARTER)
  if (calendar_diff_is_empty(x, lag, differences)) {
    duration_helper(integer(), calendar_precision_attribute(x))
  } else {
    NextMethod()
  }
}

# ------------------------------------------------------------------------------

#' Convert to year-quarter-day
#'
#' @description
#' `as_year_quarter_day()` converts a vector to the year-quarter-day
#' calendar. Time points, Dates, POSIXct, and other calendars can all be
#' converted to year-quarter-day.
#'
#' @inheritParams rlang::args_dots_empty
#'
#' @param x `[vector]`
#'
#'   A vector to convert to year-quarter-day.
#'
#' @param start `[integer(1) / NULL]`
#'
#'   The month to start the fiscal year in. 1 = January and 12 = December.
#'
#'   If `NULL`:
#'
#'   - If `x` is a year-quarter-day, it will be returned as is.
#'
#'   - Otherwise, a `start` of January will be used.
#'
#' @return A year-quarter-day vector.
#' @export
#' @examples
#' # From Date
#' as_year_quarter_day(as.Date("2019-01-01"))
#' as_year_quarter_day(as.Date("2019-01-01"), start = 3)
#'
#' # From POSIXct, which assumes that the naive time is what should be converted
#' as_year_quarter_day(as.POSIXct("2019-01-01 02:30:30", "America/New_York"))
#'
#' # From other calendars
#' tuesday <- 3
#' as_year_quarter_day(year_month_weekday(2019, 2, tuesday, 2))
#'
#' # Converting between `start`s
#' x <- year_quarter_day(2019, 01, 01, start = 2)
#' x
#'
#' # Default keeps the same start
#' as_year_quarter_day(x)
#'
#' # But you can change it
#' as_year_quarter_day(x, start = 1)
as_year_quarter_day <- function(x, ..., start = NULL) {
  UseMethod("as_year_quarter_day")
}

#' @export
as_year_quarter_day.default <- function(x, ..., start = NULL) {
  stop_clock_unsupported_conversion(x, "clock_year_quarter_day")
}

#' @export
as_year_quarter_day.clock_year_quarter_day <- function(x, ..., start = NULL) {
  check_dots_empty0(...)

  if (is_null(start)) {
    return(x)
  }

  start <- quarterly_validate_start(start)
  x_start <- quarterly_start(x)

  if (x_start == start) {
    return(x)
  }

  as_year_quarter_day(as_sys_time(x), start = start)
}

# ------------------------------------------------------------------------------

#' @export
as_sys_time.clock_year_quarter_day <- function(x, ...) {
  check_dots_empty0(...)
  calendar_check_no_invalid(x)
  start <- quarterly_start(x)
  precision <- calendar_precision_attribute(x)
  fields <- as_sys_time_year_quarter_day_cpp(x, precision, start)
  new_sys_time_from_fields(fields, precision, clock_rcrd_names(x))
}

#' @export
as_naive_time.clock_year_quarter_day <- function(x, ...) {
  check_dots_empty0(...)
  as_naive_time(as_sys_time(x))
}

#' @export
as.character.clock_year_quarter_day <- function(x, ...) {
  format(x)
}

# ------------------------------------------------------------------------------

#' @export
calendar_leap_year.clock_year_quarter_day <- function(x) {
  year <- get_year(x)
  start <- quarterly_start(x)
  year_quarter_day_leap_year_cpp(year, start)
}

# ------------------------------------------------------------------------------

#' Grouping: year-quarter-day
#'
#' @description
#' This is a year-quarter-day method for the [calendar_group()] generic.
#'
#' Grouping for a year-quarter-day object can be done at any precision, as
#' long as `x` is at least as precise as `precision`.
#'
#' @inheritParams calendar_group
#'
#' @param x `[clock_year_quarter_day]`
#'
#'   A year-quarter-day vector.
#'
#' @param precision `[character(1)]`
#'
#'   One of:
#'
#'   - `"year"`
#'   - `"quarter"`
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
#' @name year-quarter-day-group
#'
#' @export
#' @examples
#' x <- year_quarter_day(2019, 1:4)
#' x <- c(x, set_year(x, 2020))
#'
#' # Group by 3 quarters
#' # Note that this is a grouping of 3 quarters of the current year
#' # (i.e. the count resets at the beginning of the next year)
#' calendar_group(x, "quarter", n = 3)
#'
#' # Group by 5 days of the current quarter
#' y <- year_quarter_day(2019, 1, 1:90)
#' calendar_group(y, "day", n = 5)
calendar_group.clock_year_quarter_day <- function(x, precision, ..., n = 1L) {
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
  if (precision == PRECISION_QUARTER) {
    value <- get_quarter(x)
    value <- group_component1(value, n)
    x <- set_quarter(x, value)
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

#' Narrow: year-quarter-day
#'
#' This is a year-quarter-day method for the [calendar_narrow()] generic. It
#' narrows a year-quarter-day vector to the specified `precision`.
#'
#' @inheritParams year-quarter-day-group
#'
#' @return `x` narrowed to the supplied `precision`.
#'
#' @name year-quarter-day-narrow
#'
#' @export
#' @examples
#' # Day precision
#' x <- year_quarter_day(2019, 1, 5)
#' x
#'
#' # Narrow to quarter precision
#' calendar_narrow(x, "quarter")
calendar_narrow.clock_year_quarter_day <- function(x, precision) {
  check_precision(precision)
  precision <- precision_to_integer(precision)

  start <- quarterly_start(x)

  out_fields <- list()
  x_fields <- unclass(x)

  if (precision >= PRECISION_YEAR) {
    out_fields[["year"]] <- x_fields[["year"]]
  }
  if (precision >= PRECISION_QUARTER) {
    out_fields[["quarter"]] <- x_fields[["quarter"]]
  }
  if (precision >= PRECISION_DAY) {
    out_fields[["day"]] <- x_fields[["day"]]
  }

  out_fields <- calendar_narrow_time(out_fields, precision, x_fields)

  new_year_quarter_day_from_fields(
    out_fields,
    precision,
    start,
    names = names(x)
  )
}

# ------------------------------------------------------------------------------

#' Widen: year-quarter-day
#'
#' This is a year-quarter-day method for the [calendar_widen()] generic. It
#' widens a year-quarter-day vector to the specified `precision`.
#'
#' @inheritParams year-quarter-day-group
#'
#' @return `x` widened to the supplied `precision`.
#'
#' @name year-quarter-day-widen
#'
#' @export
#' @examples
#' # Quarter precision
#' x <- year_quarter_day(2019, 1)
#' x
#'
#' # Widen to day precision
#' calendar_widen(x, "day")
#'
#' # Or second precision
#' sec <- calendar_widen(x, "second")
#' sec
calendar_widen.clock_year_quarter_day <- function(x, precision) {
  x_precision <- calendar_precision_attribute(x)

  check_precision(precision)
  precision <- precision_to_integer(precision)

  if (precision >= PRECISION_QUARTER && x_precision < PRECISION_QUARTER) {
    x <- set_quarter(x, 1L)
  }
  if (precision >= PRECISION_DAY && x_precision < PRECISION_DAY) {
    x <- set_day(x, 1L)
  }

  x <- calendar_widen_time(x, x_precision, precision)

  x
}

# ------------------------------------------------------------------------------

#' Boundaries: year-quarter-day
#'
#' This is a year-quarter-day method for the [calendar_start()] and
#' [calendar_end()] generics. They adjust components of a calendar to the
#' start or end of a specified `precision`.
#'
#' @inheritParams year-quarter-day-group
#'
#' @return `x` at the same precision, but with some components altered to be
#'   at the boundary value.
#'
#' @name year-quarter-day-boundary
#'
#' @examples
#' x <- year_quarter_day(2019:2020, 2:3, 5, 6, 7, 8, start = clock_months$march)
#' x
#'
#' # Compute the last moment of the fiscal quarter
#' calendar_end(x, "quarter")
#'
#' # Compare that to just setting the day to `"last"`,
#' # which doesn't affect the other components
#' set_day(x, "last")
#'
#' # Compute the start of the fiscal year
#' calendar_start(x, "year")
#'
#' as_date(calendar_start(x, "year"))
NULL

#' @rdname year-quarter-day-boundary
#' @export
calendar_start.clock_year_quarter_day <- function(x, precision) {
  x_precision <- calendar_precision_attribute(x)

  check_precision(precision)
  precision <- precision_to_integer(precision)

  calendar_start_end_checks(x, x_precision, precision, "start")

  if (precision <= PRECISION_YEAR && x_precision > PRECISION_YEAR) {
    x <- set_quarter(x, 1L)
  }
  if (precision <= PRECISION_QUARTER && x_precision > PRECISION_QUARTER) {
    x <- set_day(x, 1L)
  }

  x <- calendar_start_time(x, x_precision, precision)

  x
}

#' @rdname year-quarter-day-boundary
#' @export
calendar_end.clock_year_quarter_day <- function(x, precision) {
  x_precision <- calendar_precision_attribute(x)

  check_precision(precision)
  precision <- precision_to_integer(precision)

  calendar_start_end_checks(x, x_precision, precision, "end")

  if (precision <= PRECISION_YEAR && x_precision > PRECISION_YEAR) {
    x <- set_quarter(x, 4L)
  }
  if (precision <= PRECISION_QUARTER && x_precision > PRECISION_QUARTER) {
    x <- set_day(x, "last")
  }

  x <- calendar_end_time(x, x_precision, precision)

  x
}

# ------------------------------------------------------------------------------

#' Counting: year-quarter-day
#'
#' This is a year-quarter-day method for the [calendar_count_between()] generic.
#' It counts the number of `precision` units between `start` and `end` (i.e.,
#' the number of years or quarters).
#'
#' @inheritParams calendar-count-between
#'
#' @param start,end `[clock_year_quarter_day]`
#'
#'   A pair of year-quarter-day vectors. These will be recycled to their
#'   common size.
#'
#' @param precision `[character(1)]`
#'
#'   One of:
#'
#'   - `"year"`
#'   - `"quarter"`
#'
#' @inherit calendar-count-between return
#'
#' @name year-quarter-day-count-between
#'
#' @export
#' @examples
#' # Compute the number of whole quarters between two dates
#' x <- year_quarter_day(2020, 3, 91)
#' y <- year_quarter_day(2025, 4, c(90, 92))
#' calendar_count_between(x, y, "quarter")
#'
#' # Note that this is not always the same as the number of whole 3 month
#' # periods between two dates
#' x <- as_year_month_day(x)
#' y <- as_year_month_day(y)
#' calendar_count_between(x, y, "month", n = 3)
calendar_count_between.clock_year_quarter_day <- function(
  start,
  end,
  precision,
  ...,
  n = 1L
) {
  NextMethod()
}

#' @export
calendar_count_between_standardize_precision_n.clock_year_quarter_day <- function(
  x,
  precision,
  n
) {
  check_precision(precision)
  precision_int <- precision_to_integer(precision)

  allowed_precisions <- c(PRECISION_YEAR, PRECISION_QUARTER)

  if (!(precision_int %in% allowed_precisions)) {
    abort("`precision` must be one of: 'year', 'quarter'.")
  }

  list(precision = precision, n = n)
}

#' @export
calendar_count_between_compute.clock_year_quarter_day <- function(
  start,
  end,
  precision
) {
  check_precision(precision)
  precision <- precision_to_integer(precision)

  if (precision == PRECISION_YEAR) {
    out <- get_year(end) - get_year(start)
    return(out)
  }

  if (precision == PRECISION_QUARTER) {
    out <- (get_year(end) - get_year(start)) * 4L
    out <- out + (get_quarter(end) - get_quarter(start))
    return(out)
  }

  abort(
    "Internal error: `precision` should be 'year' or 'quarter' at this point."
  )
}

#' @export
calendar_count_between_proxy_compare.clock_year_quarter_day <- function(
  start,
  end,
  precision
) {
  check_precision(precision)
  precision <- precision_to_integer(precision)

  start <- vec_proxy_compare(start)
  end <- vec_proxy_compare(end)

  if (precision >= PRECISION_YEAR) {
    start$year <- NULL
    end$year <- NULL
  }
  if (precision >= PRECISION_QUARTER) {
    start$quarter <- NULL
    end$quarter <- NULL
  }

  list(start = start, end = end)
}

# ------------------------------------------------------------------------------

#' Sequences: year-quarter-day
#'
#' @description
#' This is a year-quarter-day method for the [seq()] generic.
#'
#' Sequences can only be generated for `"year"` and `"quarter"` precision
#' year-quarter-day vectors.
#'
#' When calling `seq()`, exactly two of the following must be specified:
#' - `to`
#' - `by`
#' - Either `length.out` or `along.with`
#'
#' @inheritParams seq.clock_duration
#'
#' @param from `[clock_year_quarter_day(1)]`
#'
#'   A `"year"` or `"quarter"` precision year-quarter-day to start the sequence
#'   from.
#'
#'   `from` is always included in the result.
#'
#' @param to `[clock_year_quarter_day(1) / NULL]`
#'
#'   A `"year"` or `"quarter"` precision year-quarter-day to stop the sequence
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
#' # Quarterly sequence
#' x <- seq(year_quarter_day(2020, 1), year_quarter_day(2026, 3), by = 2)
#' x
#'
#' # Which we can then set the day of the quarter of
#' set_day(x, "last")
seq.clock_year_quarter_day <- function(
  from,
  to = NULL,
  by = NULL,
  length.out = NULL,
  along.with = NULL,
  ...
) {
  precision <- calendar_precision_attribute(from)

  if (precision > PRECISION_QUARTER) {
    abort("`from` must be 'year' or 'quarter' precision.")
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
clock_minimum.clock_year_quarter_day <- function(x) {
  names <- NULL
  start <- quarterly_start(x)
  fields <- list(year = clock_calendar_year_minimum)
  year <- new_year_quarter_day_from_fields(fields, PRECISION_YEAR, start, names)

  precision <- calendar_precision_attribute(x)
  precision <- precision_to_string(precision)

  calendar_minimum(precision, year)
}

#' @export
clock_maximum.clock_year_quarter_day <- function(x) {
  names <- NULL
  start <- quarterly_start(x)
  fields <- list(year = clock_calendar_year_maximum)
  year <- new_year_quarter_day_from_fields(fields, PRECISION_YEAR, start, names)

  precision <- calendar_precision_attribute(x)
  precision <- precision_to_string(precision)

  calendar_maximum(precision, year)
}

# ------------------------------------------------------------------------------

quarterly_start <- function(x) {
  attr(x, "start", exact = TRUE)
}

quarterly_start_prettify <- function(start, ..., abbreviate = FALSE) {
  check_dots_empty()
  if (abbreviate) {
    month.abb[start]
  } else {
    month.name[start]
  }
}

quarterly_validate_start <- function(start, ..., error_call = caller_env()) {
  if (is_null(start)) {
    return(1L)
  }

  check_number_whole(start, min = 1, max = 12, call = error_call)
  start <- vec_cast(start, integer(), call = error_call)

  start
}
