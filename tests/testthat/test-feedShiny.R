test_that("feedShiny() returns a list of data", {
  expect_equal(class(feedShiny("israel_caves-2025.nc")), "list")
  expect_equal(length(feedShiny("israel_caves-2025.nc")), 4)
})
