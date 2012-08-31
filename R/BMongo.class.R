# Public functions and methods
# 
# Author: wush
###############################################################################

setClass(
	"BMongo", 
	representation(mongo = "mongo", size_limit = "integer", db = "character", ns = "character"), 
	prototype(mongo = NULL, size_limit = 16777200L, db = NULL, ns = NULL))

setMethod("initialize", "BMongo", function(.Object, host = "127.0.0.1", name = "", username = "", password = "", db = "admin", timeout = 0L) {
	.Object@mongo = mongo.create(host, name, username, password, db, timeout)
	checkAlive(.Object@mongo)
	.Object@db = db
	.Object@ns = paste(db, "RObject", sep=".")
	mongo.index.create(.Object@mongo, .Object@ns, "name", mongo.index.unique)
	return(.Object)
	})

setMethod("$", "BMongo", function(x, name) {
	switch(name, 
		save = function(R_obj, obj_name) save(x, R_obj, obj_name),
		load = function(obj_name) load(x, obj_name),
		resetDB = function() resetDB(x),
		dropDB = function() dropDB(x),
		closeDB = function() closeDB(x)
	)})

