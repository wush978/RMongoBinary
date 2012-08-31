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

save <- function(x, R_obj, obj_name) {
	mongo <- x@mongo
	checkAlive(mongo)
	db <- x@db
	ns <- x@ns
	Robj.binary <- serialize(R_obj, NULL, FALSE)
	if (nchar(obj_name[1]) + length(Robj.binary) < x@size_limit) {
		buf <- mongo.bson.buffer.create()
		mongo.bson.buffer.append.string(buf, "name", obj_name[1])
		mongo.bson.buffer.append.raw(buf, "Rdata", Robj.binary)
		b <- mongo.bson.from.buffer(buf)
		mongo.insert(mongo, ns, b)
		err <- mongo.get.last.err(mongo, db)
		if (!is.null(err)) {
			stop(mongo.getdrop.server.err.string(mongo))
		}
	}
	else {
		gridfs.name <- digest(Robj.binary, "md5", FALSE)
		buf <- mongo.bson.buffer.create()
		mongo.bson.buffer.append.string(buf, "name", obj_name[1])
		mongo.bson.buffer.append.string(buf, "Rdata", gridfs.name)
		b <- mongo.bson.from.buffer(buf)
		mongo.insert(mongo, ns, b)
		err <- mongo.get.last.err(mongo, db)
		if (!is.null(err)) {
			stop(mongo.get.server.err.string(mongo))
		}
		gridfs <- mongo.gridfs.create(mongo, db)
		if (!mongo.gridfs.store(gridfs, Robj.binary, gridfs.name)) {
			stop("Save GridFS Failed")
		}
		mongo.gridfs.destroy(gridfs)
	}
}

load <- function(x, obj_name) {
	mongo <- x@mongo
	checkAlive(mongo)
	db <- x@db
	ns <- x@ns
	b <- mongo.find.one(mongo, ns, getQuery(obj_name[1]))
	if (is.null(b)) {
		stop(paste("Object (name:",obj_name[1],") not found"))
	}
	Robj.binary <- mongo.bson.value(b, "Rdata")
	if (is.raw(Robj.binary)) {
		return(unserialize(Robj.binary))
	}
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
	return(unserialize(Robj.binary))
}

dropDB <- function(x) {
	checkAlive(x@mongo)
	if (!mongo.drop.database(x@mongo, x@db)) {
		stop("Drop Database Failed")
	}
}
	