# READ THE TA4SP CONFIGURATION FILE: ta4sp.config
_level_conf=`grep -e '^level=' $AVISPA_PACKAGE/bin/backends/ta4sp.config | cut -d '=' -f 2`
_abstcts=`grep -e '^abstractions=' $AVISPA_PACKAGE/bin/backends/ta4sp.config | cut -d '=' -f 2`
_abstcts2=`grep -e '^coarserabstractions=' $AVISPA_PACKAGE/bin/backends/ta4sp.config | cut -d '=' -f 2`


_dossier=$AVISPA_PACKAGE/bin/backends/TA4SP
export PATH=$PATH:$_dossier

# PROCESS THE INPUT ARGUMENTS
_if_file=$1

for parm in "$@" ; do
  # OPTION help
  if test "$parm" = "--help" || test "$parm" = "-h" ; then
    ta4spv2	
    exit 0
  fi
  # OPTION version
  if test "$parm" = "--version" || test "$parm" = "-v" ; then
	ta4spv2 --version $_if_file
    exit 0
  fi
done # for parm in ..












# START TOOL ON THE INPUT PROBLEM

 _vari=`echo $_if_file | cut -d '/' -f 1`
 if test "$_abstcts" = "false"; then 
     : 
 else  
     _abstractions="--2AgentsOnly"
 fi

 if test "$_abstcts2" = "false"; then 
     : 
 else  
     _coarserabstractions="--CoarserAbstractions"
 fi


 if test "$_level" = ""; then 
      _level="--level"
     _compteur="$_level_conf"
 else  
:

 fi

#_file=`echo $_if_file | cut -d '/' -f 1`
#if test "$_file" = ""; then
#    :
#else#

#    _if_file="../$_if_file"
#fi
#echo `pwd`










for _parm in "$@" ; do
 if test "$_parm" = "$_if_file" ; then
   :
 else
  case "$_parm" in
 
  --typed_model=*)
    _typed_model=`echo $_parm | cut -d '=' -f 2`
    case "$_typed_model" in
      yes)
       _untyped=""
       ;;
      no)
       echo "SUMMARY"
       echo "  NOT_SUPPORTED"
       echo
       echo "COMMENTS"
       echo "  TA4SP cannot analyse the protocol under the untyped model."
       exit 0
       ;;
      strongly)
       echo "SUMMARY"
       echo "  NOT_SUPPORTED"
       echo
       echo "COMMENTS"
       echo "  TA4SP cannot analyse the protocol under the strongly-typed model."
       exit 0
       ;;
      *)
       echo "Unknown typed_model value: $_typed_model"
       exit 1
       ;;
    esac
    ;;

  --2AgentsOnly*)
	  _abstractions="--2AgentsOnly"
	  ;;
  --CoarserAbstractions*)
	  _coarserabstractions=" --CoarserAbstractions "
	  ;;
  --secrecy-abstraction*)
	  _abstractions="--2AgentsOnly"
	  ;;
  --level=*)
     _level="--level"
     _compteur=`echo $_parm | cut -d '=' -f 2`
     ;;

  --output=*)
      _ouput="--output "
      _outdir=`echo $_parm | cut -d '=' -f 2`
    ;;

  *)
    echo "The option $_parm is not known by TA4SP."
    echo "TA4SP options are:"
    echo "    --2AgentsOnly  Use the abstraction according to the result of"
    echo "                   Common and Cortier"
    echo "    --level=i      if i = 0 then an over-approximation is computed."
    echo "                   if i > 0 then an under-approximation is computed."
    exit 1
    ;;

  esac
 fi
done # for parm in ...


 ta4spv2 $_abstractions $_coarserabstractions $_level $_compteur  $_ouput $_outdir $_if_file 

