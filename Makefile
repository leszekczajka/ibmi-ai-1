##############################################################################
# Makefile for Financial Instruments Dictionary Application
# Target: IBM i (compile using PASE)
##############################################################################

SHELL = /QOpenSys/pkgs/bin/bash
.ONESHELL:

# Library name for compiled objects
LIB = IBMIAI1

# Source directories
QDDSSRC = qddssrc
QRPGLESRC = qrpglesrc

# Object names
TABLE = FININST
DSPF = FININSTD
PGM = FININSTR
MSGF = FININSTMF

##############################################################################
# Default target
##############################################################################
.PHONY: all
all: lib table msgf dspf pgm

##############################################################################
# Create library if it doesn't exist
##############################################################################
.PHONY: lib
lib:
	@echo "Creating library $(LIB)..."
	-system "CRTLIB LIB($(LIB)) TEXT('Financial Instruments App')" 2>/dev/null || true

##############################################################################
# Create database table
##############################################################################
.PHONY: table
table: lib
	@echo "Creating table $(TABLE)..."
	liblist -a $(LIB)
	system "RUNSQLSTM SRCSTMF('$(CURDIR)/$(QDDSSRC)/fininst.sql') COMMIT(*NONE) NAMING(*SQL) DFTRDBCOL($(LIB))"

##############################################################################
# Create message file
##############################################################################
.PHONY: msgf
msgf: lib
	@echo "Creating message file $(MSGF)..."
	liblist -a $(LIB)
	-system "DLTMSGF MSGF($(LIB)/$(MSGF))" 2>/dev/null || true
	system "CRTMSGF MSGF($(LIB)/$(MSGF)) TEXT('Financial Instruments Messages')"
	system "ADDMSGD MSGID(INF0001) MSGF($(LIB)/$(MSGF)) MSG('Instrument added successfully.')"
	system "ADDMSGD MSGID(INF0002) MSGF($(LIB)/$(MSGF)) MSG('Instrument updated successfully.')"
	system "ADDMSGD MSGID(INF0003) MSGF($(LIB)/$(MSGF)) MSG('Instrument deleted successfully.')"
	system "ADDMSGD MSGID(ERR0001) MSGF($(LIB)/$(MSGF)) MSG('Instrument not found.')"
	system "ADDMSGD MSGID(ERR0002) MSGF($(LIB)/$(MSGF)) MSG('Error adding instrument. Duplicate ISIN or database error.')"
	system "ADDMSGD MSGID(ERR0003) MSGF($(LIB)/$(MSGF)) MSG('Error updating instrument.')"
	system "ADDMSGD MSGID(ERR0004) MSGF($(LIB)/$(MSGF)) MSG('Error deleting instrument.')"

##############################################################################
# Compile display file
##############################################################################
.PHONY: dspf
dspf: lib
	@echo "Compiling display file $(DSPF)..."
	liblist -a $(LIB)
	-system "CRTSRCPF FILE($(LIB)/QDDSSRC) RCDLEN(112) TEXT('DDS Source')" 2>/dev/null || true
	system "CPYFRMSTMF FROMSTMF('$(CURDIR)/$(QDDSSRC)/fininstd.dspf') TOMBR('/QSYS.LIB/$(LIB).LIB/QDDSSRC.FILE/$(DSPF).MBR') MBROPT(*REPLACE)"
	system "CHGPFM FILE($(LIB)/QDDSSRC) MBR($(DSPF)) SRCTYPE(DSPF)"
	system "CRTDSPF FILE($(LIB)/$(DSPF)) SRCFILE($(LIB)/QDDSSRC) SRCMBR($(DSPF)) OPTION(*EVENTF)"

##############################################################################
# Compile RPG program
##############################################################################
.PHONY: pgm
pgm: lib dspf msgf table
	@echo "Compiling program $(PGM)..."
	liblist -a $(LIB)
	system "CRTSQLRPGI OBJ($(LIB)/$(PGM)) SRCSTMF('$(CURDIR)/$(QRPGLESRC)/fininstr.sqlrpgle') COMMIT(*NONE) OBJTYPE(*PGM) OPTION(*EVENTF) DBGVIEW(*SOURCE) RPGPPOPT(*LVL2) COMPILEOPT('TGTCCSID(*JOB)')"

##############################################################################
# Clean - remove compiled objects
##############################################################################
.PHONY: clean
clean:
	@echo "Cleaning compiled objects..."
	liblist -a $(LIB)
	-system "DLTPGM PGM($(LIB)/$(PGM))" 2>/dev/null || true
	-system "DLTDSPF FILE($(LIB)/$(DSPF))" 2>/dev/null || true
	-system "DLTMSGF MSGF($(LIB)/$(MSGF))" 2>/dev/null || true
	-system "RUNSQL SQL('DROP TABLE $(LIB).$(TABLE)') COMMIT(*NONE)" 2>/dev/null || true

##############################################################################
# Clean all - remove library entirely
##############################################################################
.PHONY: cleanall
cleanall:
	@echo "Removing library $(LIB)..."
	-system "DLTLIB LIB($(LIB))" 2>/dev/null || true

##############################################################################
# Rebuild - clean and build all
##############################################################################
.PHONY: rebuild
rebuild: clean all

##############################################################################
# Help
##############################################################################
.PHONY: help
help:
	@echo "Financial Instruments Dictionary - Build Targets"
	@echo ""
	@echo "  make all      - Build all objects (default)"
	@echo "  make lib      - Create library"
	@echo "  make table    - Create database table"
	@echo "  make msgf     - Create message file"
	@echo "  make dspf     - Compile display file"
	@echo "  make pgm      - Compile RPG program"
	@echo "  make clean    - Remove compiled objects"
	@echo "  make cleanall - Remove entire library"
	@echo "  make rebuild  - Clean and rebuild all"
	@echo "  make help     - Show this help"
	@echo ""
	@echo "To run the program after compilation:"
	@echo "  CALL $(LIB)/$(PGM)"
