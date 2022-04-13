# Usage: energyplus [options] [input-file]
# Options:
#   -a, --annual                 Force annual simulation
#   -c, --convert                Output IDF->epJSON or epJSON->IDF, dependent on
#                                input file type
#   -D, --design-day             Force design-day-only simulation
#   -d, --output-directory ARG   Output directory path (default: current
#                                directory)
#   -h, --help                   Display help information
#   -i, --idd ARG                Input data dictionary path (default: Energy+.idd
#                                in executable directory)
#   -j, --jobs ARG               Multi-thread with N threads; 1 thread with no
#                                arg. (Currently only for G-Function generation)
#   -m, --epmacro                Run EPMacro prior to simulation
#   -p, --output-prefix ARG      Prefix for output file names (default: eplus)
#   -r, --readvars               Run ReadVarsESO after simulation
#   -s, --output-suffix ARG      Suffix style for output file names (default: L)
#                                   L: Legacy (e.g., eplustbl.csv)
#                                   C: Capital (e.g., eplusTable.csv)
#                                   D: Dash (e.g., eplus-table.csv)
#   -v, --version                Display version information
#   -w, --weather ARG            Weather file path (default: in.epw in current
#                                directory)
#   -x, --expandobjects          Run ExpandObjects prior to simulation
# --convert-only                 Only convert IDF->epJSON or epJSON->IDF,
#                                dependent on input file type. No simulation

# suppress trailing whitespace
__trailing_nospace() {
    # compopt is not available in ancient bash versions (like mac)
    type compopt &>/dev/null && compopt -o nospace
}


# Check if the $COMP_WORDS include the word in argument $1
__epcomp_words_include() {
  local i=1
  while [[ "$i" -lt "$COMP_CWORD" ]]
  do
    if [[ "${COMP_WORDS[i]}" = "$1" ]]
    then
      return 0
    fi
    i="$((++i))"
  done
  return 1
}

__epcomp() {
  # break $1 on space, tab, and newline characters,
  # and turn it into a newline separated list of words
  local list s sep=$'\n' IFS=$' '$'\t'$'\n'
  local cur="${COMP_WORDS[COMP_CWORD]}"

  for s in $1
  do
    # Skip the words that were already passed
    __epcomp_words_include "$s" && continue
    list="$list$s$sep"
  done

  IFS="$sep"
  COMPREPLY=( $(compgen -W "$list" -- "$cur") $( compgen -f -X '!*.idf' -- $cur ) $( compgen -f -X '!*.json' -- $cur ) )
}

# Complete with a directory, suffix a "/"
# Check if you can remove the trailing space (won't work on mac, but does it gracefully)
_comp_dir() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=($(compgen -d -S "/" -- "$cur"))
  __trailing_nospace
}

_energyplus()
{
    # i_cmd = index of last command (-, -- or oscomand)
    local i=1 i_cmd=1 cmd j

    #for w in "${COMP_WORDS[@]}";
    #do
        #echo "Word: $w"
    #done


    local opts="-h
    --help
    -v
    --version
    -a
    --annual
    -D
    --design-day
    -d
    --output-directory
    -i
    --idd
    -j
    --jobs
    -m
    --epmacro
    -p
    --output-prefix
    -r
    --readvars
    -s
    --output-suffix
    -w
    --weather
    -x
    --expandobjects
    --convert-only"

    local l_opts="--help
    --version
    --annual
    --design-day
    --output-directory
    --idd
    --jobs
    --epmacro
    --output-prefix
    --readvars
    --output-suffix
    --weather
    --expandobjects
    --convert-only"

    local s_opts="-h
    -v
    -a
    -D
    -d
    -i
    -j
    -m
    -p
    -r
    -s
    -w
    -x"

    # Get the total energyplus command list
    # Use the built-in function to return the list of possible commands (ensures this will still work when the cli is updated)
    # Prefix newline to prevent not checking the first command.
    # TODO: Temporary fix: call my local ruby cli instead
    # Uncomment one of these two to make it dynamic
    #   local cmds=$'\n'"$(energyplus list_commands --quiet)"
    #   local cmds=$'\n'"$(ruby /Users/julien/Software/Others/OpenStudio/energypluscore/src/cli/energyplus_cli.rb list_commands --quiet)"
    # populates a global ep_commands variable which is a list of \n seperated commands (not --xxx) such as measure, run, etc
    #   __ep_commands "$cmds"

    # find the subcommand
    # This skips the first (i=0) which is necessarily 'energyplus'
    # And skips the latest (current)
    # It stops whenever an command is passed
    while [[ "$i" -le "$COMP_CWORD" ]];
    do
        local s="${COMP_WORDS[i]}"
        # echo "i=$i, s=$s"


        case "$s" in
            # If it's a - or -- command, take that
            -*)
                cmd="$s"
                i_cmd=$i
                ;;
            *)
                ;;
        esac
        i="$((++i))"
    done

    #echo "i=$i, i_cmd=$i_cmd, cmd=$cmd, COMP_CWORD=$COMP_CWORD"

    # If only 'energyplus' was passed (with the beggining of something or not), return all possible commands
    if [[ "$i_cmd" -eq "$COMP_CWORD" ]]
    then
        # echo "i_cmd is equal to COMP_WORD"
        __epcomp "${opts}"
        return
    fi

    local cur prev
    #COMPREPLY=()  # Array variable storing the possible completions.
    ## Pointer to current completion word.
    ## By convention, it's named "cur" but this isn't strictly necessary.
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$cur" in
      --*)
        COMPREPLY=($(compgen -W "$l_opts" -- "$cur"))
        ;;
      -*)
        COMPREPLY=($(compgen -W "$s_opts $l_opts" -- "$cur"))
        ;;
       *)
        case "$prev" in
            -d                 )    _comp_dir;;
            --output-directory )    _comp_dir;;

            -i                 )    COMPREPLY=( $( compgen -f -X '!*.idd' -- $cur ) );;
            --idd              )    COMPREPLY=( $( compgen -f -X '!*.idd' -- $cur ) );;

            -p                 )    COMPREPLY=( eplus );;
            --output-prefix    )    COMPREPLY=( eplus );;

            -s                 )    COMPREPLY=( L C D );;
            --output-suffix    )    COMPREPLY=( L C D );;

            -j                 )    COMPREPLY=( $(nproc) );;
            --jobs             )    COMPREPLY=( $(nproc) );;

            # Complete files with .json in there
            -w                 )    COMPREPLY=( $( compgen -f -X '!*.epw' -- $cur ) );;
            --weather          )    COMPREPLY=( $( compgen -f -X '!*.epw' -- $cur ) );;

            *                  )    COMPREPLY=( $( compgen -f -X '!*.idf' -- $cur ) $( compgen -f -X '!*.json' -- $cur ) );;
        esac
        ;;

    esac
}

complete -F _energyplus energyplus

