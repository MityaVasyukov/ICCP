test_that("formatSystime() works", {
  result <- formatSystime()
  expect_type(result, "character")
  expect_match(result, "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$")
})
