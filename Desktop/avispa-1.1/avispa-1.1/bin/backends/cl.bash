#!/bin/bash

ATSE_BIN=$AVISPA_PACKAGE/bin/backends/cl/cl-atse

#Usage  :  cl-atse [options] [file]
#
#  [file]  Name of the IF file to process (default is stdin)
#  -nb n   Maximum number of role iterations (or loops, default is 3)
#  -light  Use light unification (no partial associativity for pair)
#  -notype Do not take term types into account
#  -short  Perform breath-first search (minimal attack)
#  -td     Perform depth-first search (default, less memory)
#  -lr     Perform breath-first search (minimal attack)
#  -out    Write the attack to file.atk
#  -dir d  Output directory to use with -out
#  -ns     Do not simplify the IF file (complete trace)
#  -noopt  Do not try to replace hashing by tokens. (slower or faster dep. on protocol)
#  -tab    Write the correspondence table (debug)
#  -par    Write the parser output (debug)
#  -v      Print more output informations
#  -vv     Print even more output and term informations (debug)
#  -noexec Do not search for attacks (debug)
#  -debug  Write debuging informations for Read.ml
#  -bench  Benchmark output format (very concise).
#  -split  Use the --split option on hlpsl2if for hlpsl input file.
#  -col n  Number of column in the output (default 80, disabled with -1).
#  -states Shows all internal system states of the analysis.
#  --version  Print the version number.
#  --licence  Print the CL-Atse's disclaimer (licence)
#  -help  Display this list of options
#  --help  Display this list of options

_script_options="
Particular options for cl-atse in the AVISPA's package that are mapped to the previous ones

--typed_model=[yes|no|strongly]
         Choose between typed or untyped models (like -notype). 
         'strongly' is not supported.
--output=dir
         Place all temporary files in directory 'dir' (like -dir ...)
         Warning: If you want the output to be written in a file instead
         of on the screen, use the '-out' option.
--max=n
         Maximum number of role iterations (or loops, default is 3)
--atk_kind=[first|shortest]
         Output either the first or the shortest attack found.
         Default is 'first' (like '-td'). Shortest is like '-short'.
--no_simpl
         Do not simplify the IF file (complete trace, like -ns)
--no_exec
         Do not search for attacks, only display the protocol and properties.
--verbose
         Print more output informations like protocol, properties, trace, etc..
--cl-atse_help
         Display the complete list of cl-atse's options.
"

# PROCESS THE INPUT ARGUMENTS
_unknown=""

for _parm in "$@" ; do
  case "$_parm" in
 
  --typed_model=*)
    # Choose if the model is typed or not. Strongly typed models are not supported.
    _typed_model=`echo $_parm | cut -d '=' -f 2`
    case "$_typed_model" in
      yes)
       _unknown="$_unknown"
       ;;
      no)
       _unknown="$_unknown -notype"
       ;;
      strongly)
       echo "SUMMARY"
       echo "  NOT_SUPPORTED"
       echo
       echo "COMMENTS"
       echo "  Cl-AtSe cannot analyse the protocol under the strongly-typed model."
       exit 0
       ;;
      *)
       echo "Unknown typed_model value: $_typed_model"
       exit 1
       ;;
    esac
    ;;

  --output=*)
    # Choose a directory to write the text output to.
    _output=`echo $_parm | cut -d '=' -f 2`
    _unknown="$_unknown -dir $_output"
    :
    ;;
    
  --max=*)
    # Number of loops to analyse. Useless if no loops in the protocol.
    _max_nb=`echo $_parm | cut -d '=' -f 2`
    _unknown="$_unknown -nb $_max_nb"
    ;;
    
  --atk_kind=*)
    # Choice of attack to display preferably.
    _atk_kind=`echo $_parm | cut -d '=' -f 2`
    case "$_atk_kind" in
      first)
        # Default : Output the first attack found.
	_unknown="$_unknown -td"
	;;
      shortest)
        # Output one of the shortest attacks found.
	_unknown="$_unknown -lr"
	;;
      *)
        echo "Unknown atk_kind value: $_atk_kind"
        exit 1
        ;;
    esac
    ;;
      
  --no_simpl)
    # Shortcut the protocol simplification in cl-atse
    _unknown="$_unknown -ns"
    ;;
    
  --no_exec)
    # Shortcut the search for attacks. Always output "SAFE".
    # Usefull with --no_simpl to see the initial prot. specif.
    _unknown="$_unknown -noexec"
    ;;
    
  --verbose)
    # Output detailed informations, like the analysed protocol
    # specification and more informations in the attack trace.
    _unknown="$_unknown -v"
    ;;

  --cl-atse_help)
    # Print command line help.
    # This script accepts all cl-atse options depicted in this help.
    _unknown="$_unknown --help"
    _help=true
    ;;
    
  *)
    _unknown="$_unknown $_parm"
    ;;

  esac
done

# START TOOL ON THE INPUT PROBLEM
#pushd $AVISPA_PACKAGE/bin/backends >/dev/null
$ATSE_BIN $_unknown 
case "$_help" in
  true) echo "$_script_options" ;;
esac
#popd >/dev/null
