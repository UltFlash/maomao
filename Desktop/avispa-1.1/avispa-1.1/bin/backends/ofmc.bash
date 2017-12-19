#!/bin/bash

# PROCESS THE INPUT ARGUMENTS
OFMC_BIN=$AVISPA_PACKAGE/bin/backends/ofmc/ofmc

# FIRST ARGUMENT

case "$1" in
    # Usage: avispa --ofmc --help
    --help | -help | -h)
        $OFMC_BIN --help
	exit 0
	;;
    # Usage: avispa --ofmc --version
    --version | -version | -v)
	$OFMC_BIN --version
	exit 0
	;;
esac

_if_file=$1
_other_options=""
shift 1

for _parm in "$@" ; do
  case $_parm in
  --typed_model=*)
    _typed_model=`echo $_parm | cut -d '=' -f 2`
    case "$_typed_model" in
      yes)
       _untyped=""
       ;;
      no)
       _untyped="-untyped"
       ;;
      strongly)
       echo "SUMMARY"
       echo "  NOT_SUPPORTED"
       echo
       echo "COMMENTS"
       echo "  OFMC cannot analyse the protocol under the strongly-typed model."
       exit 0
       ;;
      *)
       echo "Unknown typed_model value: $_typed_model"
       exit 1
       ;;
    esac
    ;;

  --output=*)
    :
    ;;
  *)
    _other_options="$_other_options $_parm"
##    echo "Unknown parameter: $_parm"
##    exit 1
    ;;

  esac
# fi
done # for parm in ...

# START TOOL ON THE INPUT PROBLEM

# (PHD) - I'm removing the pushd/popd pair so that the theory/IF
# files do not need to be given as absolute paths.  This can
# be useful if running with the --no-hlpsl2if option.

#pushd $AVISPA_PACKAGE/bin/backends >/dev/null
$OFMC_BIN $_if_file $_untyped $_other_options
#popd >/dev/null
