#!/bin/sh

## This script relies on the following external tools:
## - pdfinfo (part of poppler)
## - GhostScript
## - ImageMagick (convert and identify)
## - awk
## - bc
## - pdfLaTeX

## for each command line parameter
for inputfile in "$@" ; do
	## check if file exists and is not empty
	if [[ ! -s "${inputfile}" ]] ; then
		echo "Parameter \"${inputfile}\" is not an existing file." >&2
		continue
	fi

	## check if file as actually a .pdf ending
	if [[ "${inputfile/.pdf/-cropped.pdf}" = "${inputfile}" ]] ; then
		echo "File \"${inputfile}\" doesn't seem to be valid input file." >&2
		continue
	fi

	## determine number of pages using the external tool "pdfinfo"
	numpages=$(pdfinfo "${inputfile}" | awk '/^Pages: / {print $2}')
	## if number of pages is below 1 (i.e. zero), the input file cannot be a valid PDF file
	if [[ ${numpages} < 1 ]] ; then
		echo "Could not determine number of pages for file \"${inputfile}\"." >&2
		continue
	fi

	## create temporary directory with random name
	TMPDIR="/tmp/autocroppdf_$$_$RANDOM"
	mkdir -p "${TMPDIR}"

	## use GhostScript to generate thumbnail images of each page in the PDF file
	echo "Generating image previews"
	gs -dNOPAUSE -sDEVICE=pngmono -q -r64 -dBATCH  -sOutputFile="${TMPDIR}/testA%06d.png" "$inputfile" >"${TMPDIR}/gs-stdout.txt" 2>"${TMPDIR}/gs-stderr.txt"
	## check GhostScript's exit code to see if something went wrong
	if [[ $? -ne 0 ]] ; then
		echo "Ghostscript failed to interpret \"${inputfile}\"." >&2
		rm -rf "${TMPDIR}"
		continue
	fi
	## check GhostScript's output (both stdout and stderr) for warning or error messages
	if [[ $(cat "${TMPDIR}/gs-stdout.txt" "${TMPDIR}/gs-stderr.txt" | wc -l) -ge 1 ]] ; then
		echo "  There were warnings or errors from Ghostscript, continuing anyways."
	fi

	## initialize some variables for the following steps
	biginit=100000
	minx=${biginit}
	miny=${biginit}
	maxx=0
	maxy=0
	outerwidth=0
	outerheight=0
	originalwidth=0
	originalheight=0

	echo "Determining crop margin..."
	## go through each thumbnail created by GhostScript ...
	for pngfile in ${TMPDIR}/testA*.png ; do
		## trim (i.e. remove uni-color margins) from picture and save result
		convert "${pngfile}" -trim "${pngfile/testA/testB}" >"${TMPDIR}/convert-stdout.txt" 2>"${TMPDIR}/convert-stderr.txt"
		## catch potential problems, e.g. if trim failed on an empty page
		if [[ $? -ne 0 || $(cat "${TMPDIR}/convert-stdout.txt" "${TMPDIR}/convert-stderr.txt" | wc -l) -ge 1 ]] ; then
			continue
		fi
		## the trim/clip/crop operation's information (margins) are still available in the cropped file -> retrieve them
		eval $(identify "${pngfile/testA/testB}" | awk -F '[- x+]+' '{print "innerwidth="$3" innerheight="$4" outerwidth="$5" outerheight="$6" xoffset="$7" yoffset="$8}')

		## do some math to determine boundaries
		right=$(($xoffset + $innerwidth))
		bottom=$(($yoffset + $innerheight))
		if [[ $minx -gt $xoffset ]] ; then minx=$xoffset ; fi
		if [[ $miny -gt $yoffset ]] ; then miny=$yoffset ; fi
		if [[ $right -gt $maxx ]] ; then maxx=$right ; fi
		if [[ $bottom -gt $maxy ]] ; then maxy=$bottom ; fi
	done

	## check determined boundaries for soundness
	if [[ ${outerheight} -le 0 || ${outerwidth} -le 0 || ${maxx} -le 0 || ${maxy} -le 0 || ${minx} -ge ${biginit} || ${miny} -ge ${biginit} ]] ; then
		echo "Could not identify crop margins for file \"${inputfile}\"." >&2
		rm -rf "${TMPDIR}"
		continue
	fi

	## use pdfinfo again to determine original file's page size (in mm)
	eval $(pdfinfo "$inputfile" | awk '/^Page size: / {print "originalwidth="($3 / 2.83)"  originalheight="($5 / 2.83)}')
	if [[ "${originalwidth}" = "0" || "${originalheight}" = "0" ]] ; then
		echo "Could not identify page size for file \"${inputfile}\"." >&2
		rm -rf "${TMPDIR}"
		continue
	fi

	## some more math to determine trim values for all four sides
	trimleft=$(echo "scale=4 ; $minx / $outerwidth * $originalwidth" | bc)
	trimbottom=$(echo "scale=4 ; ( $outerheight - $maxy ) / $outerheight * $originalheight" | bc)
	trimright=$(echo "scale=4 ; ( $outerwidth - $maxx ) / $outerwidth * $originalwidth" | bc)
	trimtop=$(echo "scale=4 ; $miny / $outerheight * $originalheight" | bc)

	## write header of LaTeX source file
	cat <<EOF >"${TMPDIR}/output.tex"
\documentclass{article}
\usepackage[pdftex]{graphicx}
\usepackage[margin=1cm,a4paper]{geometry}

\pagestyle{empty}
\setlength{\parindent}{0pt}
\setlength{\parskip}{0pt}

\begin{document}
\centering
EOF

	## insert each input page individually into output file and apply crop/trim/clip operation
	for n in $(seq 1 ${numpages}) ; do
		echo '\includegraphics[width=185mm,height=272mm,keepaspectratio=true,page='${n}',clip,trim='${trimleft}'mm '${trimbottom}'mm '${trimright}'mm '${trimtop}'mm]{'"${inputfile}"'}\par\clearpage'
	done >>"${TMPDIR}/output.tex"

	## write footer of LaTeX source file
	cat <<EOF >>"${TMPDIR}/output.tex"
\end{document}
EOF

	## use pdfLaTeX to compile LaTeX source file into a PDF file
	pdflatex -halt-on-error -output-directory="${TMPDIR}" "${TMPDIR}/output.tex" >"${TMPDIR}/pdflatex-stdout.txt" 2>"${TMPDIR}/pdflatex-stderr.txt"
	if [[ $? -ne 0 ]] ; then
		echo "pdfLaTeX failed to compile cropped PDF document." >&2
		rm -rf "${TMPDIR}"
		continue
	fi

	## copy resulting PDF file to original input file with modified filename
	cp -p "${TMPDIR}/output.pdf" "${inputfile/.pdf/-cropped.pdf}" && echo "Generated cropped file ${inputfile/.pdf/-cropped.pdf}."

	## clean-up mess
	rm -rf "${TMPDIR}"
done
