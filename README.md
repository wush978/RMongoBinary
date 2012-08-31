RMongoBinary
-------------------

# Introduction

According [my experiments](http://wush978.github.com/blog/2012/08/30/benchmark-of-saving-and-loading-r-objects/), handling R object in binary
should be faster than BSON format.

Therefore, I write a wrapper of package `rmongodb` to help myself to save and load R object into and from mongodb.

# Sample Code

``` r
library(RMongoBinary)
bmongo <- new("BMongo", db = "test")
a <- rnorm(10) # a simple R object
b <- rnorm(17 * 2^20) # a large R object which exceeds the size limit of BSON
bmongo$save(a, "a") # save the object with name "a" in BSON
bmongo$save(b, "b") # save the object with name "b" in GridFS, note that the filename is the md5 hash of the binary
if (sum(a != bmongo$load("a"))) { # load the object from mongodb.
	stop("inconsistent")
}

if (sum(b != bmongo$load("b"))) { # load the object from mongodb.
	stop("inconsistent")
}

tryCatch(bmongo$save(rnorm(5), "a"), error = function(e) {print(e)}) # The name should not be the same
bmongo$dropDB() # drop the database

bmongo$save(rnorm(5), "a") # The database is cleaned, so the name "a" can be used
tryCatch(bmongo$save(rnorm(5), "a"), error = function(e) {print(e)}) # The name should not be the same

bmongo$closeDB() # clean and disconnect

bmongo2 <- new("BMongo", db = "test2")
bmongo2$save(rnorm(5), "a") # The name can be re-use in different db

new("BMongo", db = "test")$dropDB() # clean db
bmongo2$dropDB() # clean and disconnect
#bmongo$closeDB() if you just want to disconnect, use this method!

```
