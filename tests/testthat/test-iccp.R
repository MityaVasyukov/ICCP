test_that("check_nc() returns TRUE when netcdf is ok", {
  expect_true(check_nc("israel_caves-2024.nc"))
})
