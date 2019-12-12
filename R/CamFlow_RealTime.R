

########################### CamFlow_RealTime.R ############################

# This file contains functions used to manage realtime disclosure to CamFlow.
# CamFlow nodes are stored in a dataframe, with the values as the CamFlow ID value.
# The columns of the data frame are:
#
# type - string value of the type of node (activity/entity)
# num - numeral designator
# name - the string label for the node (i.e. the source code)

# dyn.load("camper.so")

#' .ddg.init.camflow.nodes initializes the information needed to manage camflow nodes
#' @return nothing
#' @noRd
.ddg.init.camflow.nodes <- function () {
	.ddg.set("ddg.camflow.nodes", .ddg.create.camflow.node.rows())
}

#' .ddg.create.camflow.node.rows create a data frame of empty rows to put in
#' the camflow node table. It is faster to add a bunch of empty rows and update them
#' than to add one row at a time.
#' @param size the number of rows to add
#' @return a data frame wit size rows, with all columns being empty vectors
#' @noRd
.ddg.create.camflow.node.rows <- function (size=100) {
	return (
		data.frame(
			   cam.type = character(size),
			   cam.num = numeric(size),
			   cam.name = character(size),
			   cam.camID = numeric(size),
			   stringsAsFactors=FALSE))
}

#' .ddg.camflow.node.table returns the camflow node table
#' @return the camflow node table
#' @noRd
.ddg.camflow.node.table <- function() {
	return (.ddg.get("ddg.camflow.nodes"))
}

#' .ddg.camflow.nodes returns the filled rows of the camflow node table
#' @return the filled rows of the camflow node table
#' @noRd
.ddg.camflow.nodes <- function() {
	ddg.camflow.nodes <- .ddg.get("ddg.camflow.nodes")
  	return (ddg.camflow.nodes [ddg.camflow.nodes$cam.num > 0, ])
}

#' .ddg.camflow.entities returns the data frame with only entities
#' @return the camflow node table with type == entities
.ddg.camflow.entities <- function() {
	ddg.camflow.nodes <- .ddg.get("ddg.camflow.nodes")
	return (ddg.camflow.nodes [ddg.camflow.nodes$cam.type == "entities", ])
}

#' .ddg.camflow.activities returns the data frame with only activities
#' @return the camflow node table with type == activities
.ddg.camflow.activities <- function() {
	ddg.camflow.nodes <- .ddg.get("ddg.camflow.nodes")
	return (ddg.camflow.nodes [ddg.camflow.nodes$cam.type == "activities", ])
}


.ddg.disclose.to.camflow <- function(node_type) {
	return(.C(paste("cam_", node_type, sep=""), 
		  node = as.character(node_type),
		  id = as.integer(0))$id)
}

.ddg.record.camflow <- function(ctype, cnum, cname) {
	ddg.camflow.nodes <- .ddg.camflow.node.table()
	#if table is full, make it bigger.
	# if (nrow(ddg.camflow.nodes) < 
	  #  max(.ddg.camflow.entities$cam.num) + max(.ddg.camflow.activities$cam.num)) { 
	#	    ddg.camflow.nodes <- 
	#		    .ddg.add.rows("ddg.camflow.nodes", .ddg.create.camflow.nodes.rows())
	#	}

	#add row
	emptyIndices <- which(ddg.camflow.nodes$cam.num == 0)
	firstEmpty <- min(emptyIndices)
	ddg.camflow.nodes$cam.type[firstEmpty] <- ctype
	ddg.camflow.nodes$cam.num[firstEmpty] <- cnum
	ddg.camflow.nodes$cam.name[firstEmpty] <- cname #may not need
	ddg.camflow.nodes$cam.ID[firstEmpty] <- 
		.ddg.disclose.to.camflow(ctype)
	print(ddg.camflow.nodes[1:5,])

	.ddg.set("ddg.camflow.nodes", ddg.camflow.nodes)
}


