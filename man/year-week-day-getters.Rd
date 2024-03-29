% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/week-year-week-day.R
\name{year-week-day-getters}
\alias{year-week-day-getters}
\alias{get_year.clock_year_week_day}
\alias{get_week.clock_year_week_day}
\alias{get_day.clock_year_week_day}
\alias{get_hour.clock_year_week_day}
\alias{get_minute.clock_year_week_day}
\alias{get_second.clock_year_week_day}
\alias{get_millisecond.clock_year_week_day}
\alias{get_microsecond.clock_year_week_day}
\alias{get_nanosecond.clock_year_week_day}
\title{Getters: year-week-day}
\usage{
\method{get_year}{clock_year_week_day}(x)

\method{get_week}{clock_year_week_day}(x)

\method{get_day}{clock_year_week_day}(x)

\method{get_hour}{clock_year_week_day}(x)

\method{get_minute}{clock_year_week_day}(x)

\method{get_second}{clock_year_week_day}(x)

\method{get_millisecond}{clock_year_week_day}(x)

\method{get_microsecond}{clock_year_week_day}(x)

\method{get_nanosecond}{clock_year_week_day}(x)
}
\arguments{
\item{x}{\verb{[clock_year_week_day]}

A year-week-day to get the component from.}
}
\value{
The component.
}
\description{
These are year-week-day methods for the
\link[=clock-getters]{getter generics}.
\itemize{
\item \code{get_year()} returns the year. Note that this can differ from the
Gregorian year.
\item \code{get_week()} returns the week of the current year.
\item \code{get_day()} returns a value between 1-7 indicating the weekday of the
current week, where \verb{1 = start of week} and \verb{7 = end of week}, in line with
the chosen \code{start}.
\item There are sub-daily getters for extracting more precise components.
}
}
\examples{
x <- year_week_day(2019, 50:52, 1:3)
x

# Get the week
get_week(x)

# Gets the weekday
get_day(x)

# Note that the year can differ from the Gregorian year
iso <- year_week_day(2019, 1, 1, start = clock_weekdays$monday)
ymd <- as_year_month_day(iso)

get_year(iso)
get_year(ymd)
}
