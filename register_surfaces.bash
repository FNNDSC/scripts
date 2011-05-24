#!/bin/bash
#!/bin/bash
#
# Copyright 2010 Rudolph Pienaar, Dan Ginsburg, FNNDSC
# Childrens Hospital Boston
#
# GPL v2
#
# register_surfaces.bash -- Register a set of subject surfaces to 
#                           a reference subject
#
#
# "include" the set of common script functions
source common.bash
declare -i Gi_verbose=1


G_HEMI="lh"
G_SURFACE="sphere"
G_SUBJECTBASEDIR=/chb/users/rudolphpienaar/projects/curvatureAnalysis/recon-PMG
G_REFSUBJECTDIR=/chb/users/rudolphpienaar/projects/curvatureAnalysis/recon-PMG/PMG01
G_CLUSTERCMD="mosrun -e -b -q"
G_OUTDIR=$(pwd)

G_SYNOPSIS="

  NAME

        register_surfaces.bash

  SYNOPSIS
  
        register_surfaces.bash  [-D <subjectBaseDir>]                   \\
                        [-R <refSubjectDir>]                            \\
                        [-C <clusterCmd>]                               \\
                        [-H <hemi>]                                     \\
                        [-S <surface>]                                  \\                        
                        [-v <verbosityLevel>]

  DESC

        'register_surfaces.bash' used 'mris_register' from freesurfer to
        register a set of surfaces to a reference subject.  
        
        The <subjectBaseDir> should contain symbolic links
        to all of the subjects that you want to register to the
        reference (along with the reference itself).

  ARGS        
        -D <subjectBaseDir> (Optional ${G_SUBJECTBASEDIR})
        Base directory where subjects are stored.

        -R <refSubjectDir> (Optional ${G_REFSUBJECTDIR})
        Full path to reference subject's freesurfer directory.
        
        -H <hemi> (Optional ${G_HEMI})
        Hemisphere, 'rh' or 'lh'.
        
        -S <surface> (Optional ${G_SURFACE})
        Surface (e.g., 'pial', 'smoothwm', etc.)
        
        -C <clusterCmd> (Optional: ${G_CLUSERCMD})
        Command to preface running registration with, specify
        an empty string (\"\") if you do not want to have a cluster
        command.
        
        -O <outDir> (Optional: ${G_OUTDIR})
        Directory in which to create output
        
	-v <verbosityLevel> (Optional)
        This script defaults to a verbosityLevel of '1'. To be most
        verbose, use a level of '10'.

  DEPENDS
  o Freesurfer 'mri_register'
        
  HISTORY
    
  24 May 2011
  o Initial design and coding.
"

while getopts v:D:R:H:S:C:O: option ; do
        case "$option"
        in
            v)      Gi_verbose=$OPTARG              ;;
            D)      G_SUBJECTBASEDIR=$OPTARG        ;;
            R)      G_REFSUBJECTDIR=$OPTARG         ;;                                               
            C)      G_CLUSTERCMD=$OPTARG            ;;
            S)      G_SURFACE=$OPTARG               ;;
            H)      G_HEMI=$OPTARG                  ;;
            O)      G_OUTDIR=$OPTARG                ;;
            \?)     synopsis_show 
                    exit 0;;
        esac
done


SUBJECTDIRS=$(find ${G_SUBJECTBASEDIR} -type l)

for SUBJECTDIR in ${SUBJECTDIRS} ; do
    if [[ "${SUBJECTDIR}" != "${G_REFSUBJECTDIR}" ]] ; then
	echo "Registering '${SUBJECTDIR}' to '${G_REFSUBJECTDIR}'..."
	OUTDIR="${G_OUTDIR}/$(basename ${G_SUBJECTBASEDIR})/registered-to-$(basename ${G_REFSUBJECTDIR})"
	SUBJECT=$(basename $SUBJECTDIR)
	mkdir -p ${OUTDIR}/${SUBJECT}/surf

	CMD="mris_register -1 ${SUBJECTDIR}/surf/${G_HEMI}.${G_SURFACE}       \
                              ${G_REFSUBJECTDIR}/surf/${G_HEMI}.${G_SURFACE}  \
                              ${OUTDIR}/${SUBJECT}/surf/${G_HEMI}.${G_SURFACE}.reg"

	CLUSTERCMD="${G_CLUSTERCMD} ${CMD} &"
	eval ${CLUSTERCMD}
    fi
done

