# Private functions
# 
# Author: wush
###############################################################################


checkAlive <- function(mongo) {
	if (!mongo.is.connected(mongo)) {
		stop("Mongo is disconnected")
	}	
}

getQuery <- function(name) {
	buf <- mongo.bson.buffer.create()
	mongo.bson.buffer.append(buf, "name", name)
	return(mongo.bson.from.buffer(buf))
}

save <- function(x, R_obj, obj_name, compression = "none", parameter = list()) {
	mongo <- x@mongo
	db <- x@db
	ns <- x@ns
	Robj.binary <- serialize(R_obj, NULL, FALSE)
	Robj.binary <- memCompress(Robj.binary, compression)
	buf <- mongo.bson.buffer.create()
	mongo.bson.buffer.append.string(buf, "name", obj_name[1])
	for(parameter.name in names(parameter)) {
		parameter.element <- parameter[[parameter.name]]
		mongo.bson.buffer.append(buf, parameter.name, parameter.element)
	}
	if (mongo.bson.buffer.size(buf) + length(Robj.binary) + nchar(compression[1]) + 30 < x@size_limit) {
		mongo.bson.buffer.append.string(buf, "compression", compression)
		mongo.bson.buffer.append.raw(buf, "Rdata", Robj.binary)
	}
	else {
		gridfs.name <- digest(Robj.binary, "md5", FALSE)
		mongo.bson.buffer.append.string(buf, "Rdata", gridfs.name)
		gridfs <- mongo.gridfs.create(mongo, db)
		if (!mongo.gridfs.store(gridfs, Robj.binary, gridfs.name)) {
			stop("Save GridFS Failed")
		}
		mongo.gridfs.destroy(gridfs)
	}
	b <- mongo.bson.from.buffer(buf)
	mongo.insert(mongo, ns, b)
	err <- mongo.get.last.err(mongo, db)
	if (!is.null(err)) {
		stop(mongo.get.server.err.string(mongo))
	}
}

load <- function(x, obj_name) {
	mongo <- x@mongo
	db <- x@db
	ns <- x@ns
	b <- mongo.find.one(mongo, ns, getQuery(obj_name[1]))
	if (is.null(b)) {
		stop(paste("Object (name:",obj_name[1],") not found"))
	}
	Robj.binary <- mongo.bson.value(b, "Rdata")
	if (!is.raw(Robj.binary)) {
		# GridFS object
		gridfs <- mongo.gridfs.create(mongo, db)
		gridfs.name <- Robj.binary
		gf <- mongo.gridfs.find(gridfs, gridfs.name)
		if (is.null(gf)) {
			stop("Logical Error: GridFS Not Found!!")
		}
		gf.size <- mongo.gridfile.get.length(gf)
		mongo.gridfile.seek(gf, gf.size)
		Robj.binary <- mongo.gridfile.read(gf,gf.size)
		mongo.gridfile.destroy(gf)
		mongo.gridfs.destroy(gridfs)
	}
	Robj.binary <- memDecompress(Robj.binary, mongo.bson.value(b, "compression"))
	return(unserialize(Robj.binary))
}

resetDB <- function(x) {
	checkAlive(x@mongo)
	if (!mongo.drop.database(x@mongo, x@db)) {
		stop("Drop Database Failed")
	}
	mongo.index.create(x@mongo, x@ns, "name", mongo.index.unique)
}

dropDB <- function(x) {
	checkAlive(x@mongo)
	if (!mongo.drop.database(x@mongo, x@db)) {
		stop("Drop Database Failed")
	}
	mongo.disconnect(x@mongo)
	TRUE
}

closeDB <- function(x) {
	mongo.disconnect(x@mongo)
	TRUE
}
	