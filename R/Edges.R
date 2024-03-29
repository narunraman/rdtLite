# Copyright (C) President and Fellows of Harvard College and 
# Trustees of Mount Holyoke College, 2014, 2015, 2016, 2017, 2018.

# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program.  If not, see
#   <http://www.gnu.org/licenses/>.

########################### Edges.R ###########################

# This file contains functions used to manage the edge table and
# create edges.


#' .ddg.init.edges initializes the information needed to manage edges
#' @return nothing
#' @noRd

.ddg.init.edges <- function () {
  #.ddg.set("ddg.data.nodes", .ddg.create.data.node.rows())
  .ddg.set("ddg.edges", .ddg.create.edge.rows())
  
  .ddg.set("ddg.enum", 0)
}

#' .ddg.is.edge.type returns TRUE for any type of edge
#' This is used for type-checking.
#' @param type edge type.
#' @return true for any type of edge
#' @noRd

.ddg.is.edge.type <- function(type) {
  return(type %in% c("cf", "df.in", "df.out"))
}

#' .ddg.enum returns the counter used to assign edge ids
#' @return the edge id of the last edge created
#' @noRd

.ddg.enum <- function() {
  return (.ddg.get("ddg.enum"))
}

#' .ddg.create.edge.rows creates a data frame of empty rows to put in the 
#' edge table. It is faster to add a bunch of empty rows and update them 
#' than to add one row at a time
#' @param size the number of rows to add
#' @return a data frame with size rows, with all columns being empty vectors
#' @noRd

.ddg.create.edge.rows <- function (size=100) {
  return (      
      data.frame(
          ddg.num = numeric(size),
          ddg.type = character(size),
          ddg.from = character(size),
          ddg.to = character(size), 
          stringsAsFactors=FALSE))
}

#' .ddg.edge.table returns the edge table
#' @return the edge table
#' @noRd

.ddg.edge.table <- function() {
  return (.ddg.get("ddg.edges"))
}

#' .ddg.edges returns the filled rows of the edge table
#' @return the filled rows of the edge table
#' @noRd

.ddg.edges <- function() {
  ddg.edges <- .ddg.get("ddg.edges")
  return (ddg.edges [ddg.edges$ddg.num > 0, ])
}

#' .ddg.save.debug.edges writes the edges to a csv table.  Useful for debugging.
#' The file will be in the debug directory in a file called edges.csv
#' @return nothing
#' @noRd

.ddg.save.debug.edges <- function () {
  # Save edges table to file.
  fileout <- paste(.ddg.path.debug(), "/edges.csv", sep="")
  utils::write.csv(.ddg.edges(), fileout, row.names=FALSE)
}

#' .ddg.record.edge records a control flow edge or a data flow edge
#' in the edges table.
#' @param etype type of edge
#' @param node1 name of first node
#' @param node2 name of second node
#' @return nothing
#' @noRd

.ddg.record.edge <- function(etype, node1, node2) {
  if (!.ddg.is.edge.type (etype)) {
    print (paste (".ddg.record.edge: bad value for etype - ", etype))
  }
	
  # print(.ddg.edge.table()[1:15,])

  # if(disclose_rt) {

	  # df.in == data2proc
	  # df.out == proc2data
	  # cf == proc2proc
	  
  # }
  
  # print(paste("edge type: " , etype))
  # print(paste("node 1: ", node1))

  ddg.edges <- .ddg.edge.table()
  
  # Don't add the edge if it already exists.
  if (nrow (ddg.edges[ddg.edges$ddg.type == etype & ddg.edges$ddg.from == node1 & ddg.edges$ddg.to == node2, ]) > 0) {
    #print (paste ("Found existing edge ", etype, node1, node2))
    return()
  }
  
  # Increment edge counter.
  .ddg.inc("ddg.enum")
  ddg.enum <- .ddg.enum()
  
  # If the table is full, make it bigger.
  if (nrow(ddg.edges) < ddg.enum) {
    ddg.edges <- .ddg.add.rows("ddg.edges", .ddg.create.edge.rows())
  }
  
  ddg.edges$ddg.num[ddg.enum] <- ddg.enum
  ddg.edges$ddg.type[ddg.enum] <- etype
  ddg.edges$ddg.from[ddg.enum] <- node1
  ddg.edges$ddg.to[ddg.enum] <- node2
  .ddg.set("ddg.edges", ddg.edges)
  
  if (.ddg.debug.lib()) {
    if (etype == "cf") etype.long <- "control flow"
    else if (etype == "df.in") etype.long <-"data flow in"
    else etype.long <- "data flow out"
    print (paste("Adding", etype.long, "edge", ddg.enum, "for", node1, "to", node2))
  }
}

#' .ddg.proc2proc creates a control flow edge from the preceding
#' procedure node to the current procedure node.
#' @return nothing
#' @noRd

.ddg.proc2proc <- function() {
  ddg.pnum <- .ddg.pnum()
  
  if (ddg.pnum > 1) {
    # Record in edges table
    etype <- "cf"
    node1 <- paste("p", ddg.pnum-1, sep="")
    node2 <- paste("p", ddg.pnum, sep="")
    .ddg.record.edge(etype, node1, node2)
    
    if (.ddg.debug.lib()) {
      pname1 <- .ddg.proc.name(ddg.pnum-1)
      pname2 <- .ddg.proc.name(ddg.pnum)
      print(paste("proc2proc: ", pname1, " ", pname2))
      print(paste("CF ", node1, " ", node2, sep=""))
    }
  }
  
  invisible()
}

#' .ddg.data2proc creates a data flow edge from a data node to a
#' procedure node.
#' @param dname data node name.
#' @param dscope data node scope.
#' @param pname procedure node name.  If it is NULL or a ddg function, 
#'   the last procedure node is used.
#' @return nothing
#' @noRd

.ddg.data2proc <- function(dname, dscope, pname = NULL) {
  # Get data & procedure numbers.
  dn <- .ddg.data.number(dname, dscope)
  
  if(is.null(pname) || startsWith(pname, ".ddg.") || startsWith(pname, "ddg"))
    pn <- .ddg.pnum()
  else
    pn <- .ddg.proc.number(pname)
  
  # Record in edges table
  etype <- "df.in"
  node1 <- paste("d", dn, sep="")
  node2 <- paste("p", pn, sep="")
  .ddg.record.edge(etype, node1, node2)
  
  if (.ddg.debug.lib()) {
    print(paste("data2proc: ", dname, " ", pname, sep=""))
    print(paste("DF ", node1, " ", node2, sep=""))
  }
  
  invisible()
}

#' .ddg.datanum2lastproc creates an edge from a data node to the 
#' last procedure node created.
#' @param data.num the id of the data node
#' @return nothing
#' @noRd

.ddg.datanum2lastproc <- function(data.num) {
  proc.num <- .ddg.pnum()
  
  # Record in edges table
  etype <- "df.in"
  node1 <- paste("d", data.num, sep="")
  node2 <- paste("p", proc.num, sep="")
  .ddg.record.edge(etype, node1, node2)
  
  if (.ddg.debug.lib()) {
    print(".ddg.func.to.return.value:")
    print(paste("DF ", node1, " ", node2, sep=""))
  }
}

#' .ddg.proc2data creates a data flow edge from a procedure node to
#' a data node.
#' @param pname procedure node name.  If NULL or a ddg fucnction, the last
#'   procedure node is used.
#' @param dname data node name.
#' @param dscope (optional) data node scope.
#' @param return.value (optional) if true it means we are linking to a return
#'   value. In this case, we need to be sure that there is not already a
#'   return value linked.  This is necessary to manage recursive functions
#'   correctly.
#' @return nothing
#' @noRd

.ddg.proc2data <- function(pname, dname, dscope=NULL, return.value=FALSE) {
  # Get data & procedure numbers.
  dn <- .ddg.data.number(dname, dscope)
  
  # attach data node to the last procedure node if pname is NULL.
  if(is.null(pname) || startsWith(pname, ".ddg.") || startsWith(pname, "ddg"))
    pn <- .ddg.pnum()
  else
    pn <- .ddg.proc.number(pname, return.value)
  
  # Create data flow edge from procedure node to data node.
  if (dn != 0 && pn != 0) {
    
    # Record in edges table
    etype <- "df.out"
    node1 <- paste("p", pn, sep="")
    node2 <- paste("d", dn, sep="")
    .ddg.record.edge(etype, node1, node2)
    
    # Record that the function is linked to a return value.  This
    # is necessary for recursive functions to get linked to their
    # return values correctly.
    if (return.value) {
      .ddg.proc.node.returned(pn)
    }
    
    if (.ddg.debug.lib()) {
      print(paste("proc2data: ", pname, " ", dname, sep=""))
      print(paste("DF ", node1, " ", node2, sep=""))
    }
  }
  
  invisible()
}

#' .ddg.lastproc2data creates a data flow edge from the last
#' procedure node to a data node.
#' @param dname data node name.
#' @param dscope (optional) the scope in which dname should be looked up
#' @return nothing
#' @noRd

.ddg.lastproc2data <- function(dname, dscope=NULL) {
  .ddg.proc2data (NULL, dname, dscope)
}
