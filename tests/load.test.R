# TODO: Add comment
# 
# Author: wush
###############################################################################


source("save.test.R", chdir = TRUE)

if (sum(a != bmongo$load("a"))) {
	stop("inconsistent")
}

if (sum(b != bmongo$save(b, "b"))) {
	stop("inconsistent")
}
