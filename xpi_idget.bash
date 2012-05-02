#!/bin/bash

G_SYNOPSIS="

NAME

	xpi_idget.bash

SYNOPSIS

	xpi_idget.bash <file>.xpi

DESC

	Retrieves the extension ID from Mozilla xpi extension files.

DEPENDS

	o xmlstarlet:
		- Mac: sudo port install xmlstarlet
		- Ubuntu: sudo apt-get install xmlstarlet

"


# Retrieve the extension id for an addon from its install.rdf
  unzip -qc $1 install.rdf | xmlstarlet sel \
    -N rdf=http://www.w3.org/1999/02/22-rdf-syntax-ns# \
    -N em=http://www.mozilla.org/2004/em-rdf# \
    -t -v \
    "//rdf:Description[@about='urn:mozilla:install-manifest']/em:id"
