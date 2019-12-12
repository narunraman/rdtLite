.onLoad <- function(libname, pkgname) {
	dyn.load("camper.so")
	# library.dynam("camper", pkgname, libname)
	invisible()
}

