#!/bin/bash

# SATMC SETTING
export SP_PATH=$AVISPA_PACKAGE/bin/backends/satmc_2.0/lib/sicstus-3.12.3
export LD_LIBRARY_PATH=$AVISPA_PACKAGE/bin/backends/satmc_2.0/lib

# READ THE SATMC CONFIGURATION FILE: satmc.config
_max=`grep -e '^max=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
_prelude_abs=`grep -e '^prelude=/' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
if test "$_prelude_abs" = "" ; then 
  _prelude_rel=`grep -e '^prelude=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
  _prelude_abs=$AVISPA_PACKAGE/$_prelude_rel
fi
_avispa=`grep -e '^avispa=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
_oi=`grep -e '^oi=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
_sc=`grep -e '^sc=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
##_ct=`grep -e '^ct=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
_solver=`grep -e '^solver=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
##_enc=`grep -e '^enc=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
_enc=gp-efa
_mutex=`grep -e '^mutex=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
##_absRef=`grep -e '^absRef=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`
_coe=`grep -e '^check_only_executability=' $AVISPA_PACKAGE/bin/backends/satmc.config | cut -d '=' -f 2`

for parm in "$@" ; do
  # OPTION help
  if test "$parm" = "--help" || test "$parm" = "-h" ; then
    pushd $AVISPA_PACKAGE/bin/backends/satmc_2.0 >/dev/null
    ./satmc --help
    popd >/dev/null
    exit 0
  fi
  # OPTION version
  if test "$parm" = "--version" || test "$parm" = "-v" ; then
    pushd $AVISPA_PACKAGE/bin/backends/satmc_2.0 >/dev/null
    ./satmc --version
    popd >/dev/null
    exit 0
  fi
done # for parm in ...

# PROCESS THE INPUT ARGUMENTS
_if_file=$1

for _parm in "$@" ; do
 if test "$_parm" = "$_if_file" ; then
   :
 else
  case "$_parm" in
 
  --typed_model=*)
    _typed_model=`echo $_parm | cut -d '=' -f 2`
    case "$_typed_model" in
      yes)
       _ct=false
       ;;
      no)
       echo "SUMMARY"
       echo "  NOT_SUPPORTED"
       echo
       echo "COMMENTS"
       echo "  SATMC cannot analyse the protocol under the untyped model."
       exit 0
       ;;
      strongly)
       _ct=true
       ;;
      *)
       echo "Unknown typed_model value: $_typed_model"
       exit 1
       ;;
    esac
    ;;
  --output=*)
    _outdir=`echo $_parm | cut -d '=' -f 2`
    ;;
  --prelude=*)
    _prelude_rel=`echo $_parm | cut -d '=' -f 2`
    _prelude_abs=$AVISPA_PACKAGE/$_prelude_rel
    if [ -e "$_prelude_abs" ] ; then 
	:
    else 
	if [ -e "$_prelude_rel" ] ; then 
	    _prelude_abs=$_prelude_rel
	else 
	    echo "$_prelude_rel: No such file or directory"
	    exit 0
	fi
    fi  
    ;;
  --max=*)
    _max=`echo $_parm | cut -d '=' -f 2`
    ;;
  --solver=*)
    _solver=`echo $_parm | cut -d '=' -f 2`
    ;;
  --enc=*)
    _enc=`echo $_parm | cut -d '=' -f 2`
    ;;
  --mutex=*)
    _mutex=`echo $_parm | cut -d '=' -f 2`
    ;;
  --oi=*)
    _oi=`echo $_parm | cut -d '=' -f 2`
    ;;
  --sc=*)
    _sc=`echo $_parm | cut -d '=' -f 2`
    ;;
  --check_only_executability=*)
    _coe=`echo $_parm | cut -d '=' -f 2`
    ;;
  --avispa=*)
    _avispa=`echo $_parm | cut -d '=' -f 2`
    ;;
  *)
    echo "Unknown parameter: $_parm"
    exit 1
    ;;

  esac
 fi
done # for parm in ...

# For avoiding problems with relative paths:
pushd `dirname $_if_file` >/dev/null
_full_if_file=`pwd`/`basename $_if_file`
popd >/dev/null
pushd $_outdir >/dev/null
_full_outdir=`pwd`
popd >/dev/null

# START TOOL ON THE INPUT PROBLEM
pushd $AVISPA_PACKAGE/bin/backends/satmc_2.0 >/dev/null
#./satmc $_if_file --ct=$_ct --max=$_max --avispa=$_avispa --oi=$_oi --sc=$_sc --enc=$_enc --mutex=$_mutex --prelude=$_prelude_abs --output_dir=$_outdir --solver=$_solver --check_only_executability=$_coe
./satmc $_full_if_file --ct=$_ct --max=$_max --avispa=$_avispa --oi=$_oi --sc=$_sc --enc=$_enc --mutex=$_mutex --prelude=$_prelude_abs --output_dir=$_full_outdir --solver=$_solver --check_only_executability=$_coe
popd >/dev/null
