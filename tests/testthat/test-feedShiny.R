test_that("feedShiny() returns a list of data", {
  expect_equal(class(feedShiny("israel_caves-2024.nc")), "list")
  expect_equal(length(feedShiny("israel_caves-2024.nc")), 3)
})
