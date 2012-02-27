#
# Makefile 
#
# AUTHOR
#
#	Rudolph Pienaar
#
# TYPE 
#
#	c, c++ programming (with qt aware moc calling)
#
# DESCRIPTION
#
#	This Makefile strives to automatically find and define a programming
#	project. Given that the directory structure conforms to a loose 
#	standard (see later), this Makefile will pick up source code files
#	without needing to be explicitly told that they relate to the 
#	project at hand.
#
#	In other words, in most instances it should be sufficient to merely
#	copy this Makefile to root directory of a project tree, create the
#	directories as indicated below, and start coding - adding source
#	files to their respective directories. A simple "gmake" will then
#	create the project *without* any need to edit this file.
#
#	The directory structure inwhich this Makefile is used should conform
#	to the following:-
#
#		$(basedir):		Root directory of project tree
#		$(basedir)/binsrc:	Contains the "main" program
#					target sources
#		$(basedir)/includelib: 	Contains generic library include 
#					files src tree;
#					i.e. generic `#includes'
#		$(basedir)/includebin:	Contains app specific include src 
# 					tree - i.e. the `#includes' 
#					specific to the project at hand
#
#	The above is just a suggested guide. The only *required* directory
#	is `binsrc'. The include directories are searched in ls order with 
#	an `include*' wildcard, so any matching directory pattern will be
#	searched (i.e. you can place includes in `include_myproject' and 
#	they will be found).
#
#	All c files that are found in these directories will be assumed part
#	of the final project and linked into the created binary.
#
# ENVIRONMENT VARIABLES
#
#	The following variables may be set in the environment and input
#	to the make process by invocation with a `-e':-
#
#	o 	CC		C compiler
#	o	C++		C++ compiler
#	o	CFLAGS		Compiler flags
#	o	LIBS		Linked libraries and/or library paths
#	o	prefix		'base' directory of installation,
#				i.e. '/usr/local'
#	
#	Consult this file for other variables and values
# 
# COMMAND LINE ARGUMENTS
#
#	Certain internal variables lend themselves to command line
#	specification:-
#
#	o	SHOW		Controls whether or not *compile* and 
#				*linking* shell commands are echoed.
#				The default behaviour does *not* echo
#				these shell commands. To explicitly
#				enable them, invoke with:
#
#				> gmake SHOW=" "
#
#       o       SHOWC           Show only compilation shell commands
#
#                               > gmake SHOWC="YES"
#
#       o       SHOWL           Show only linking shell commands
#
#                               > gmake SHOWL="YES"
#
#
#	o	VERBOSE		Controls whether or not detailed project
#				information is shown - specifically 
#				a list of all project files and required
#				libraries. Default behaviour does *not*
#				show this. Enable with:
#
#				> gmake VERBOSE=1
#
#				Note that the value is unimportant, the
#				Makefile merely checks whether or not
#				this variable is defined.
#
#	o 	CAN_TALK	If the system has audio capability, this
#				variable allows user-specified sounds to
#				be generated on certain `make' events.
#				These events include:-
#
#					o Compilation
#					o Linking
#					o Cleaning
#					o Constructing distribution
#								
#				The default behaviour has audio capability
#				disabled. Enable with:-
#
#				> gmake CAN_TALK="YES"
#
#				or by setting the appropriate macro within
#				this file.
#
#				See the `CAN_TALK' section for more
#				information.
#
# NOTE
#
# 	o 	Please note that this Makefile follows GNU conventions
#		(see the file make.info for more information). On a FreeBSD
#		system use `gmake' instead of `make'
#
#	o	Any and all of the Makefile variables can be overridden by 
#		defining them as environment variables and running make 
#		with a `-e'
#
#	o	This file follows the conventions described in make.info
#		as far as possible
#
#	o	Header files that are suffixed by `moc.h' are assumed to contain
#		Q_OBJECT declarations and as such are churned through moc and
#		linked to the final executable.
#
# FINALLY
#
#	I know that this Makefile's panaceatic ambition of 
#	"one-Makefile-fits-all" might be something of a progamming Holy 
#	Grail, so emptor caveat!
#
# HISTORY
# -------
#
# Pre 1999
# o Development and construction
#
# 02-01-1999
# o After losing a version of this file in an accidental directory
#   returning to the drawing board with maintenance.
# o Some thoughts on higher level directory trees
# o Added LDFLAGS
# o Linker flags need to be properly accommodated... if defined one
#   needs a different linker command sequence. Makefiles are not exactly
#   great at programming tasks...
#
# 02-02-1999
# o Compiler and linking echoing sorted out.
# o LDFLAGS resolved.
#
# 03-12-1999
# o Removed hardwired `/home' and replaced with env(HOME)
#
# 06-04-1999
# o Cleanup of some comment formatting
#
# 07-22-1999
# o Added `tidy' target and enhanced `dist'
#
# 02-09-2000
# o Removed embedded tk components
# o Removed bash specific components
# o Changed c++ file suffix from *.C to *.cpp
#
# 03-10-2000
# o Added `moc' awareness
#
# 1 Novemeber 2000
# o Added `HAVE_QT' awareness
#
# 15 January 2001
# o Fixed up HAVE_QT issues (needed to pass through to CFLAGS)
#
# 26 June 2001
# o Expanded `clean' to remove SD/FAST generated *_dyn.c and *_sar.c
#   files. Since a particular problem set needs its own SD/FAST files,
#   problem-specific *_dyn.c and *_sar.c files are copied from the
#   SDFAST_swap dir to target directories in the "active" build area.
#
# o Added new make args, SDFAST=xxxx
#
# 23 July 2001
# o Added new make args, FUNCTIONTRACE=1
#
# 21 August 2001
# o Expanded CFLAGS to include more target specific information
#


# /\/\/\/\/\/\/\/\/\/\/\/\/\/\ #
# Variable declaration section #
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/ #

# *-*-*-*-*-*-*-*-*-*-*-* #
# Miscellaneous variables #
# *-*-*-*-*-*-*-*-*-*-*-* #

# Set the shell
SHELL = /bin/sh

# Determine the hosttype and username
HOSTTYPE	:= $(shell uname -a | awk '{print $$14}')-$(shell uname)
SELF		:= $(shell whoami)

# Output compiling and linking commands
#
# This section controls whether compiling and linking commands
# are echoed to stdout.
#
SHOW		= NO
SC		=
SL		=
ifneq ($(SHOW), NO)
	SC		:= -v
	SL		:= -v
endif
ifeq ($(SHOWC), YES)
	SC		:= -v
endif
ifeq ($(SHOWL), YES)
	SL		:= -v
endif


# *-*-*-*-*-*-*-*-*-* #
# Compiler variables  #
# *-*-*-*-*-*-*-*-*-* #

# The compiler variables: 
# `CC' for the C compiler, `C++' for the C++ compiler
# 	o Embedded c files are compiled with CC
# 	o Other files (c/c++) are compiled according to filename suffix:
#		o c++ files: g++
#		o c files:   gcc
CC 		= gcc
C++		= g++

# Compiler flags local to this installation can be set here
CFLAGS 		= -g

SUFFIX		= ""

ifeq ($(SDFAST), DL)
	SWAPDIR		= includepend2_SDFAST
	CFLAGS		+= -DDL
	SUFFIX		= _DL
endif

ifeq ($(SDFAST), MTL)
	SWAPDIR		= includepend3_SDFAST
	CFLAGS		+= -DMTL
	SUFFIX		= _MTL
endif

ifdef HAVE_QT
CFLAGS		+=-DHAVE_QT
endif

ifdef HAVE_SDFAST
CFLAGS		+=-DHAVE_SDFAST
endif

ifdef FUNCTIONTRACE
CFLAGS		+= -DFUNCTIONTRACE
endif

# ALL_CFLAGS is for vital cflags that the user shouldn't change
ALL_CFLAGS 	=

# Linker flags can be added here
#LDFLAGS		= "-n32"
LDFLAGS		= ""

# *-*-*-*-*-*-*-*-*-* #
# Directory variables #
# *-*-*-*-*-*-*-*-*-* #

# *Target* directory variables
# i.e. where executables will be installed
prefix 		= $(HOME)
exec_prefix 	= $(prefix)/arch/$(HOSTTYPE)
bindir		= $(exec_prefix)/bin
libdir		= $(exec_prefix)/lib

# *Source* directory variables (usually in a user's space)
binsrc		= binsrc
locallib        = lib/$(HOSTTYPE)
incdirs 	= $(wildcard ./include*)
srcdirs		= $(binsrc) $(incdirs)
# System-wide directory variables (usually in root's space)
SYS_INCLUDES    =
VPATH		= $(subst " ",:,$(srcdirs))

# *-*-*-*-*-*-*-*-* #
# Command variables #
# *-*-*-*-*-*-*-*-* #

# Install variables
INSTALL 	= cp
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA 	= $(INSTALL)

# The `CAN_TALK' variable controls whether or not audio capability
# is linked to makefile processes.
# 
# SAY:				is the audio program used.
# SAY_LINKING... SAY_CLEANING:	are variables for event-specific arguments
# 				to SAY
#
# Set to "YES" to allow "talking"
CAN_TALK	= "NO"

# Audio program
ifeq ($(CAN_TALK), YES)
	SAY = say
else
	SAY = echo
endif

# Event arguments
SAY_LINKING       = "linking"
SAY_COMPILING     = "com pieling"
SAY_CLEANING      = "cleaning"
SAY_ALL_DONE      = "all done"
SAY_ET		  = "making ee tee object"
SAY_ET2C	  = "making ee tee to see"
SAY_NO_INSTALL    = "in val id destinnaytion. cannot install"
SAY_YES_INSTALL   = "instellation successful"
SAY_PREPROCESSING = "pre processing"
SAY_UNINSTALL     = "un instellation successful"


# *-*-*-*-*-*-*-*-*-*-*-*-*-* #
# Libraries needed by progam. #
# *-*-*-*-*-*-*-*-*-*-*-*-*-* #
#
# The `LIBS' variable defaults to `-L/usr/local/lib'.
# Furthermore, if a $(locallib) directory exists in the current
# root directory, it *and* its contents are also appended to `LIBS'

LIBS            = -lm

#ifdef HAVE_QT
#LIBS 		+= -L/home/pienaar/arch/${HOSTTYPE}/qt/lib -lqt
#endif

LOCALLIBPATH	= $(wildcard $(locallib)/*)
ifdef LOCALLIBPATH
LOCALLIBS_EX	= $(sort $(wildcard $(locallib)/lib*.so $(locallib)/lib*.a))
LOCALLIBS	= $(basename $(LOCALLIBS_EX))
LOCALLIBS_NAMES	= $(patsubst $(locallib)/lib%, -l%, $(LOCALLIBS))		
LLIBS		= -L./$(locallib) $(LOCALLIBS_NAMES)
LIBS		+= $(LLIBS)
endif

# *-*-*-*-*-*-*-*-*-*-*-*-* #
# moc programming variables #
# *-*-*-*-*-*-*-*-*-*-*-*-* #

find_moc_files		= $(wildcard $(cdir)/*.moc.h)
ALL_MOC_INCLUDES	= $(foreach cdir, $(incdirs), $(find_moc_files))
MOC_BASENAMES		:= $(basename $(ALL_MOC_INCLUDES))
MOC_CPP_TARGETS		:= $(addsuffix .cpp, $(MOC_BASENAMES))
MOC_O_TARGETS		:= $(addsuffix .o, $(MOC_BASENAMES))
ALL_MOC_TARGETS		:= $(MOC_CPP_TARGETS) $(MOC_O_TARGETS)

# *-*-*-*-*-*-*-*-*-*-*-* #
# C programming variables # 
# *-*-*-*-*-*-*-*-*-*-*-* #

find_c_files	 = $(wildcard $(cdir)/*.c)
find_cpp_files	 = $(wildcard $(cdir)/*.cpp)
ALL_C_INCLUDES 	:= $(foreach cdir, $(incdirs), $(find_c_files))
ALL_CPP_INCLUDES:= $(foreach cdir, $(incdirs), $(find_cpp_files))
ALL_SDFAST_INCLUDES	:= $(wildcard ./SDFAST_swap/$(SWAPDIR)/*.c)
CPP_NO_MOC	:= $(filter-out $(MOC_CPP_TARGETS), $(ALL_CPP_INCLUDES))
ALL_INCLUDES	:= $(shell echo $(ALL_C_INCLUDES) $(CPP_NO_MOC) $(ALL_SDFAST_INCLUDES))
C_BASENAMES	:= $(basename $(ALL_INCLUDES))
ALLCINCLUDES	:= $(addsuffix .o, $(C_BASENAMES))
INCLUDES         = $(patsubst %, -I%, $(SYS_INCLUDES))
INCLUDES 	+= $(patsubst %, -I%, $(incdirs)) 

CCC 		:= $(shell if [ `find . -name "*.cpp" | wc -l` = "0" ] ; then echo $(CC) ; else echo $(C++) ; fi)


# /\/\/\/\/\/\/\/\/\/\/\ #
# Project Specification  #
# \/\/\/\/\/\/\/\/\/\/\/ #

# | | | | | | | | | | | | #
# v v v v v v v v v v v v #

# 'main' defines the final executable(s) residing under $(binsrc)
mainSrc         = $(wildcard $(binsrc)/*.c*)
main            = $(basename $(notdir $(mainSrc)))
Target          = $(addprefix ./$(binsrc)/, $(main))
ifndef HAVE_QT
PROJECT		= $(addsuffix .o, $(Target)) $(ALLCINCLUDES)
else
PROJECT		= $(ALL_MOC_TARGETS) $(addsuffix .o, $(Target)) $(ALLCINCLUDES)
endif
PROJINCLUDES	:= $(PROJECT)
PROJ_NO_MOC	:= $(filter-out $(MOC_CPP_TARGETS), $(PROJECT))
PROJ_NO_TARGETS := $(filter-out $(addsuffix .o, $(Target)), $(PROJ_NO_MOC))
PROJECTLIST	:= $(subst o .,o\\n., $(strip $(PROJECT)))
DISTRIBUTION    = $(notdir $(shell pwd))


# ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ #
# | | | | | | | | | | | | #

# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ #
# Project target files and dependencies  #
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/ #

# *-*-*-*-*-*- #
# Main project #
# *-*-*-*-*-*- #

all	 : 	SHOWINFO $(Target) $(PROJECT) install

$(Target):	$(PROJECT)
		-@$(SAY) $(SAY_LINKING) > /dev/null
		@echo ""
		@for BODY in $(Target) ; \
		do \
			echo "Linking $${BODY}..." ; \
			if [ "$(LDFLAGS)" != "" ] ; then \
				echo $(CCC) $(CFLAGS) -o $${BODY}$(SUFFIX) $${BODY}.o \
				-Wl,$(LDFLAGS) \
				$(PROJ_NO_TARGETS) $(LIBS) \
				| sh $(SL); \
			else \
				echo $(CCC) $(CFLAGS) -o $${BODY}$(SUFFIX) $${BODY}.o \
				$(PROJ_NO_TARGETS) $(LIBS) \
				| sh $(SL); \
			fi ; \
			if [ "$$?" != "0" ] ; then \
			        exit 1 ; \
			fi ; \
		done ;
		@ln -sf $(Target)$(SUFFIX) .
		-@$(SAY) $(SAY_ALL_DONE) > /dev/null


# *-*-*-*-*-* #
# Maintenance #
# *-*-*-*-*-* #

install:
ifeq ($(wildcard $(bindir)), $(bindir))
	@$(INSTALL_PROGRAM) $(Target)$(SUFFIX) $(bindir)
	-@$(SAY) $(SAY_YES_INSTALL) > /dev/null
	@echo "Installed Successfully!"
else
	-@$(SAY) $(SAY_NO_INSTALL) >/dev/null &
	@echo "Installation Failed!"
endif


# /\/\/\/\/\/\/\/\/\ #
# PHONY dependencies #
# \/\/\/\/\/\/\/\/\/ #

.PHONY:	uninstall clean SHOWINFO dist

SDFASTSPECIFIC:
	@cp SDFAST_swap/$(SWAPDIR)/*.c $(SWAPDIR)

uninstall:
	@-rm -f $(bindir)/$(main) > /dev/null
	@$(SAY) $(SAY_UNINSTALL) > /dev/null &
	@echo "'$(main)' uninstalled from system $(HOST)"

SHOWINFO:	
	@echo "Program Name: .......... $(Target)"
	@echo "Host Machine Type: ..... $(HOSTTYPE)"
	@echo "Host Machine Name: ..... $(HOST)"
	@echo "C Compiler: ............ $(CC)"
	@echo "C++ Compiler: .......... $(C++)"
	@echo "Compiler Flags: ........ $(CFLAGS)"
	@echo "Linker Flags: .......... $(LDFLAGS)"
	@echo "Include Directories .... $(INCLUDES)"
	@echo "Binary Install Dir: .... $(bindir)"
	@echo ""
ifdef VERBOSE
	@echo "Project '$(Target)' consists of the following:-"
	@echo ""
	@echo "Dependent files:-"
	@echo "-----------------"
	@echo "$(PROJECTLIST)"
	@echo ""
	@echo "Dependent libraries:-"
	@echo "---------------------"
	@echo "$(LIBS)"
	@echo ""
endif

clean:
	@$(SAY) $(SAY_CLEANING) >/dev/null &
	@echo "Cleaning all object files..."
	@echo "----------------------------"
	@echo "Cleaning root directory"
	@echo $(main)
	@echo ""
	@rm -f $(main) >/dev/null
	@for dir in $(srcdirs); 					\
	do 								\
		echo "Cleaning out $${dir}:" ;				\
		cd $${dir} ;						\
		echo *.o *.moc.cpp;					\
		rm -f *.o *.moc.cpp >/dev/null ;			\
		if [ "$${dir}" = "$(binsrc)" ]; 			\
		then                            			\
		   echo "$(main)" ;             			\
		   rm -f $(main) >/dev/null ;   			\
		fi ;                            			\
		echo "" ;						\
		cd .. ;							\
	done								
	@$(SAY) $(SAY_ALL_DONE) >/dev/null

tidy:
	@$(SAY) $(SAY_TIDYING) >/dev/null &
	@echo "Tidying directory structure..."
	@echo "----------------------------"
	@echo "Tidying root directory"
	@echo *~
	@rm -f *.o >/dev/null
	@for dir in $(srcdirs) ; \
	do \
		echo "Tidying $${dir}:" ;	\
		cd $${dir} ;			\
		echo *.o *~;			\
		rm -f *.o *~>/dev/null ;	\
		echo "" ;			\
		cd .. ;				\
	done 
	@$(SAY) $(SAY_ALL_DONE) >/dev/null 

dist:	tidy
	@echo "Creating distribution tar file... \`$(DISTRIBUTION).tgz'"
	@(cd .. ; tar cvhfz $(DISTRIBUTION).tgz $(DISTRIBUTION) ) 
	@echo "Distribution \`$(DISTRIBUTION).tgz' created."

# /\/\/\/\/\/\/\ #
# Implicit rules #
# \/\/\/\/\/\/\/ #

# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*- #
# Conventional c programming rules #
# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*- #

%.o : %.c ;	-@$(SAY) $(SAY_COMPILING) > /dev/null &
		@echo "Compiling $*.c ..."
		@echo $(CC) $(CFLAGS) $(ALL_CFLAGS) $(INCLUDES)\
			-o ./$*.o -c ./$*.c | sh $(SC)

%.o : %.C ;	-@$(SAY) $(SAY_COMPILING) > /dev/null &
		@echo "Compiling $*.C ..."
		@echo $(C++) $(CFLAGS) $(ALL_CFLAGS) $(INCLUDES)\
			-o ./$*.o -c ./$*.C | sh $(SC)

%.o : %.cpp ;	-@$(SAY) $(SAY_COMPILING) > /dev/null &
		@echo "Compiling $*.cpp ..."
		@echo $(C++) $(CFLAGS) $(ALL_CFLAGS) $(INCLUDES)\
			-o ./$*.o -c ./$*.cpp | sh $(SC)

ifdef HAVE_QT
%.moc.cpp : %.moc.h ;	-@$(SAY) $(SAY_COMPILING) > /dev/null &
			@echo "Compiling [moc] $*.moc.h ..."
			@echo moc \
				-o ./$*.moc.cpp ./$*.moc.h | sh $(SC)
endif

