# TODO: Add comment
# 
# Author: wush
###############################################################################

source("initialize.test.R", chdir = TRUE)

bmongo$dropDB()

a <- rnorm(10)

b <- rnorm(17 * 2^20)

bmongo$save(a, "a")
bmongo$save(b, "b")

