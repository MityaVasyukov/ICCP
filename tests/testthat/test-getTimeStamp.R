
test_that("getTimeStamp() works with valid inputs", {
  expect_equal(length(getTimeStamp("israel_caves-2024.nc", "time", 1:10)), 10)
  expect_equal(class(getTimeStamp("israel_caves-2024.nc", "time", 1:10))[1], "POSIXct")
  expect_error(getTimeStamp("israel_caves-2024.nc", "nonexistent_var", 1:10),
               "There is no variable 'nonexistent_var' in")
  expect_error(getTimeStamp("israel_caves-2024.nc", "time", "not_a_number"),
               "The interval parameter 'not_a_number' is not numeric")
}
)
