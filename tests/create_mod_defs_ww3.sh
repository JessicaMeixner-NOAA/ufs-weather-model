#!/bin/bash
set -eux

#This program compiles ww3_grid and then makes the mod_def files 
#This is called when a new basline is being created 

function trim {
    local var="$1"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

SECONDS=0

readonly MYDIR=$( dirname $(readlink -f $0) )

# ----------------------------------------------------------------------
# Parse arguments.

readonly ARGC=$#

if [[ $ARGC -lt 2 ]]; then
  echo "Usage: $0 PATHTR MACHINE_ID [ MAKE_OPT [ BUILD_NR ] [ clean_before ] [ clean_after ] ]"
  echo Valid MACHINE_IDs:
  echo $( ls -1 ../conf/configure.fv3.* | sed s,.*fv3\.,,g ) | fold -sw72
  exit 1
else
  PATHTR=$1
  MACHINE_ID=$2
  MAKE_OPT=${3:-}
  BUILD_NAME=fv3${4:+_$4}
  clean_before=${5:-YES}
  clean_after=${6:-YES}
fi



set +x
source $PATHTR/NEMS/src/conf/module-setup.sh.inc
if [[ $MACHINE_ID == macosx.* ]] || [[ $MACHINE_ID == linux.* ]]; then
  source $PATHTR/modulefiles/${MACHINE_ID}/fv3
else
  module use $PATHTR/modulefiles/${MACHINE_ID}
  module load fv3
  module list
fi
set -x


cd fv3_coupled.fd/WW3
export WW3_DIR=$( pwd -P )/model
export WW3_BINDIR="${WW3_DIR}/bin"
export WW3_TMPDIR=${WW3_DIR}/tmp
export WW3_EXEDIR=${WW3_DIR}/exe
export WW3_COMP=$target
export WW3_CC=gcc
export WW3_F90=gfortran
export SWITCHFILE="${WW3_DIR}/esmf/switch"

export WWATCH3_ENV=${WW3_BINDIR}/wwatch3.env
export PNG_LIB=$PNG_ROOT/lib64/libpng.a
export Z_LIB=$ZLIB_ROOT/lib/libz.a
export JASPER_LIB=$JASPER_ROOT/lib64/libjasper.a
export WWATCH3_NETCDF=NC4
export NETCDF_CONFIG=$NETCDF_ROOT/bin/nc-config

rm  $WWATCH3_ENV
echo '#'                                              > $WWATCH3_ENV
echo '# ---------------------------------------'      >> $WWATCH3_ENV
echo '# Environment variables for wavewatch III'      >> $WWATCH3_ENV
echo '# ---------------------------------------'      >> $WWATCH3_ENV
echo '#'                                              >> $WWATCH3_ENV
echo "WWATCH3_LPR      $PRINTER"                      >> $WWATCH3_ENV
echo "WWATCH3_F90      $WW3_F90"                      >> $WWATCH3_ENV
echo "WWATCH3_CC       $WW3_CC"                       >> $WWATCH3_ENV
echo "WWATCH3_DIR      $WW3_DIR"                      >> $WWATCH3_ENV
echo "WWATCH3_TMP      $WW3_TMPDIR"                   >> $WWATCH3_ENV
echo 'WWATCH3_SOURCE   yes'                           >> $WWATCH3_ENV
echo 'WWATCH3_LIST     yes'                           >> $WWATCH3_ENV
echo ''                                               >> $WWATCH3_ENV

${WW3_BINDIR}/w3_clean -m
${WW3_BINDIR}/w3_setup -q -c $WW3_COMP $WW3_DIR

echo $(cat ${SWITCHFILE}) > ${WW3_BINDIR}/tempswitch

sed -e "s/DIST/SHRD/g"\
    -e "s/OMPG/ /g"\
    -e "s/OMPH/ /g"\
    -e "s/MPIT/ /g"\
    -e "s/MPI/ /g"\
    -e "s/PDLIB/ /g"\
       ${WW3_BINDIR}/tempswitch > ${WW3_BINDIR}/switch

#Build exes for prep jobs: 
${WW3_BINDIR}/w3_make ww3_grid








