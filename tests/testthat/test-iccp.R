test_that("check_netcdf_file() returns TRUE when netcdf is ok", {
  expect_true(check_netcdf_file("israel_caves-2024.nc"))
})
