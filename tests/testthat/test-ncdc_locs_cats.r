context("ncdc_locs_cats")

test_that("ncdc_locs_cats returns the correct ...", {
  skip_on_cran()    

  vcr::use_cassette("ncdc_locs_cats", {
    tt <- ncdc_locs_cats()
    uu <- ncdc_locs_cats(locationcategoryid='CLIM_REG')
    vv <- ncdc_locs_cats(startdate='1970-01-01')
    
    
    # class
    expect_is(tt, "ncdc_locs_cats")
    expect_is(uu$data, "data.frame")
    expect_is(vv, "ncdc_locs_cats")
    expect_is(tt$meta, "list")
    expect_is(tt$data, "data.frame")
    expect_is(tt$meta$totalCount, "integer")
    expect_is(tt$data$id, "character")

    # dimensions
    expect_equal(length(tt$meta), 3)
    expect_equal(NCOL(tt$data), 2)
    expect_equal(dim(uu$data), c(1,2))
    expect_equal(NCOL(vv$data), 2)
    expect_equal(length(tt), 2)
    expect_equal(length(uu), 2)
    expect_equal(length(vv), 2)
  })
})
