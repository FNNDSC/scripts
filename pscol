#!/usr/bin/perl

#=======================================================================
# pscol: changes RGB color to GRAY or CMYK
#-----------------------------------------------------------------------
# Programmer: Patrick Joeckel (joeckel@mpch-mainz.mpg.de)
#             Max Planck Institute for Chemistry
# Version: 0.1b
# Date: 03 Apr 2002
#
# The program works with AFPL Ghostscript output (e.g., ps2ps, eps2eps)
#
#    This program is a heavily modified and simplified version
#    of 'psmod' (Niklas Nordin, Chalmers University of Technology,
#                09 Sep 2000, v1.0.2,
#                http://www.tfd.chalmers.se/~nordin/psmod/ )
#
# ...You may distribute this program freely...
#=======================================================================

use strict;
use English;
use FileHandle;

#=======================================================================
# global variables
#=======================================================================
my $version = "0.1b";
my $numargs = scalar @ARGV;
my $infilename,my $outfilename;
my $red, my $green, my $blue;
my $K, my $C, my $M, my $Y;
my $gray ;
my $colorline = 0;
my $epsHeader      = "%!PS-Adobe-3.0 EPSF-3.0\n";

my $low = 0.001;
my $high = 0.999;
my $delta = ($high - $low)/4.0;
#=======================================================================
# flags
#=======================================================================
# -h
my $help = 0;

# -gray
my $toGray = 0;

# -0gray
my $to0Gray = 0;

# -cmyk
# using the formula below
# K = min( 1 - $red, 1 - $green, 1 - $blue )
# C = ( 1 - $red - K ) / ( 1 - K )
# M = ( 1 - $green - K ) / ( 1 - K )
# Y = ( 1 - $blue - K ) / ( 1 - K )
my $toCMYK = 0;
#=======================================================================

#=======================================================================
# MAIN
#=======================================================================
if ($numargs eq 0 ) {
   &printHelp ;
   exit(0);
} 

# Check flags and get filename
foreach $a (@ARGV) {
  if (substr($a, 0, 1) eq "-") {
	if ( ( $a eq "-h" )|| ( $a eq "-help" ) || ( $a eq "--help" ) ) {
	    &printHelp;
	    exit(0);
	}
	elsif ( $a eq "-gray" ) {
	  $toGray = 1;
	}
	elsif ( $a eq "-0gray" ) {
	  $to0Gray = 1;
	}
	elsif ( $a eq "-cmyk" ) {
	  $toCMYK = 1;
	}
	else {
	  &unknownFlag;
	  exit(0);
	}
  }
}

if ($numargs eq 3 ) {
    $infilename = $ARGV[1];
    $outfilename = $ARGV[2];
} else {
    &printHelp;
    exit(1);
}


if (! -e $infilename) {
    print "File $infilename does not exist. Exit !\n";
    exit(0);
}

if (-e $outfilename) {
    print "File $outfilename exists. Exit !\n";
    exit(1);
}

print "\nParsing '$infilename' ... ";

open(READ, $infilename) or die "Can't open `$infilename': $!\n";
open (DATA, ">" . $outfilename);

while(<READ>) {
    my $tmpLine = $_;
    ### RESET
    $colorline = 0;

    ### SOME HEADER INFORMATION
    if (/%%EndComments/) {
	print DATA "%%Modified by pscol v$version (";
	print DATA localtime() . ")\n";
	if ($toCMYK) {
	    print DATA "/Ck{setcmykcolor} def %%pscol v$version\n";
	}
    }

    ### GET COLOR
    # rG 
    if (/\d* \d* \d* rG/) {
	$colorline = 1;
	split;
	$red = $_[0]/255;
	$green = $_[1]/255;
	$blue = $_[2]/255;
    }
    # r3
    if (/\d* \d* r3/) {
	$colorline = 2;
	split;
	$red = $_[0]/255;
	$green = $_[1]/255;
	$blue = $_[1]/255;
    }
    # r5
    if (/\d* \d* r5/) {
	$colorline = 3;
	split;
	$red = $_[1]/255;
	$green = $_[0]/255;
	$blue = $_[1]/255;
    }
    # r6
    if (/\d* \d* r6/) {
	$colorline = 4;
	split;
	$red = $_[1]/255;
	$green = $_[1]/255;
	$blue = $_[0]/255;
    }

    if ( $colorline gt 0) {
	### CONVERT COLOR ...
	### ... to GRAY
	if ( $toGray ) {
	    &calculateGray;
	    $gray = $gray*255;
	    print DATA "$gray G\n";
	}
	if ( $to0Gray ) {
	    &calculate0Gray;
	    $gray = $gray*255;
	    print DATA "$gray G\n";
	}
	### ... to CMYK
	if ( $toCMYK ) {
	    &calculateCMYK;	    
	    $C = $C;
	    $M = $M;
	    $Y = $Y;
	    $K = $K;
	    print DATA sprintf("%6.4f %6.4f %6.4f %6.4f Ck\n",,$C,$M,$Y,$K);
	}
    } else {
	### KEEP LINE AS IS
	print DATA $tmpLine;
    }
}

close (DATA);
close (READ);
print "\nCreated '$outfilename'.\n";
print "Done !\n\n";
#
#=======================================================================

#=======================================================================
#  subroutine calculateCMYK
#=======================================================================
sub calculateCMYK {

  $C = 0.0;
  $M = 0.0;
  $Y = 0.0;
  
  if ( 1.0 - $red < 1.0 - $green ) { $K = 1.0 - $red }
  else { $K = 1.0 - $green }
  if ( 1.0 - $blue < $K ) { $K = 1.0 -$blue }
  if ( $K != 1.0 ) {
	$C = ( 1.0 - $red - $K ) / ( 1.0 - $K );
	$M = ( 1.0 - $green - $K ) / ( 1.0 - $K );
	$Y = ( 1.0 - $blue - $K ) / ( 1.0 - $K );
  } 

}
#=======================================================================

#=======================================================================
#  subroutine calculate0Gray
#=======================================================================
sub calculate0Gray {

  my $sum = $red + $green + $blue;
  $gray = $sum/3.0;
}
#=======================================================================

#=======================================================================
#  subroutine calculateGray
#=======================================================================
sub calculateGray {

  my $sum = $red + $green + $blue;

  if ( ($sum != 0.0) && ($sum != 3.0)) {
	if ( $red == 0.000 ) {
	  if ( $blue > $green ) {
		# blue - cyan
		$gray = $blue * ($low + $green * $delta / $blue);
	  }
	  else {
		# cyan - green
		$gray = $green * ($low + $delta + ($green - $blue)*$delta / $green);
	  }
	}
	else {
	  if ( $red > $green ) {
		# yellow - red
		$gray = $red * ( $high - $green * $delta / $red)
	  }
	  else {
		# green - yellow
		$gray = $green * ($high - $delta - ($green - $red)*$delta / $green); 
	  }
	}
  }
  else {
	$gray = $sum/3.0;
  }
}
#=======================================================================

#=======================================================================
#  subroutine unknown flag
#=======================================================================
sub unknownFlag {
  print "\n\t". $a . " is an unknown flag.\n";
  &printHelp;
}
#=======================================================================

#=======================================================================
#  subroutine print help message
#=======================================================================
sub printHelp {
  print "\npscol v$version: Patrick Joeckel (joeckel\@mpch-mainz.mpg.de)\n";
  print "Usage:\n";
  print "\t" . $0 . " [flags] <infilename> <outfilename>\n";
  print "\tAllowed flags are:\n";
  print "\t\t-h    \tprint this message and exit.\n";
  print "\t\t-gray \tconvert RGB colorscale to grayscale.\n";
  print "\t\t-0gray\tconvert RGB colorscale to grayscale (simple).\n";
  print "\t\t-cmyk \tconvert RGB to CMYK.\n";
  print "\tNote: Only for AFPL Ghostscript output (eps2eps, ps2ps) !!!\n\n";
}
#=======================================================================
