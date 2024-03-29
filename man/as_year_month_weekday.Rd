% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gregorian-year-month-weekday.R
\name{as_year_month_weekday}
\alias{as_year_month_weekday}
\title{Convert to year-month-weekday}
\usage{
as_year_month_weekday(x, ...)
}
\arguments{
\item{x}{\verb{[vector]}

A vector to convert to year-month-weekday.}

\item{...}{These dots are for future extensions and must be empty.}
}
\value{
A year-month-weekday vector.
}
\description{
\code{as_year_month_weekday()} converts a vector to the year-month-weekday
calendar. Time points, Dates, POSIXct, and other calendars can all be
converted to year-month-weekday.
}
\examples{
# From Date
as_year_month_weekday(as.Date("2019-01-01"))

# From POSIXct, which assumes that the naive time is what should be converted
as_year_month_weekday(as.POSIXct("2019-01-01 02:30:30", "America/New_York"))

# From other calendars
as_year_month_weekday(year_quarter_day(2019, quarter = 2, day = 50))
}
