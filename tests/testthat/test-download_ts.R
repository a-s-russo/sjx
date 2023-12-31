# WARNING - Generated by {fusen} from dev/flat_save_data.Rmd: do not edit by hand

library(testthat)

test_that("Incorrect data", {
  expect_error(check_series(mtcars))
})

test_that("Incorrect data", {
  expect_error(check_series(NULL))
})

test_that("Incorrect data", {
  expect_error(check_series(list(
    data = 1:3, meta = c('a', 'b', 'c')
  )))
})

test_that("Incorrect data", {
  expect_error(check_series(list(
    var1 = 1:3, var2 = c('a', 'b', 'c')
  )))
})

