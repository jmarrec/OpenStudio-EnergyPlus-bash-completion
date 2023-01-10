#Usage: openstudio [options] <command> [<args>]

    #-h, --help                       Print this help.
        #--verbose                    Print the full log to STDOUT
    #-I, --include DIR                Add additional directory to add to front of Ruby $LOAD_PATH (may be used more than once)
    #-e, --execute CMD                Execute one line of script (may be used more than once). Returns after executing commands.
        #--gem_path DIR               Add additional directory to add to front of GEM_PATH environment variable (may be used more than once)
        #--gem_home DIR               Set GEM_HOME environment variable

#Common commands:
     #energyplus_version    Returns the EnergyPlus version used by the CLI
     #execute_ruby_script   Executes a ruby file
     #gem_list              Lists the set gems available to openstudio
     #list_commands         Lists the entire set of available commands
     #measure               Updates measures and compute arguments
     #openstudio_version    Returns the OpenStudio version used by the CLI
     #ruby_version          Returns the Ruby version used by the CLI
     #run                   Executes an OpenStudio Workflow file
     #update                Updates OpenStudio Models to the current version

# suppress trailing whitespace
__trailing_nospace() {
    # compopt is not available in ancient bash versions (like mac)
    type compopt &>/dev/null && compopt -o nospace
}

# Returns only the commands (not the '--xxx' stuff) such as measure, run, update
# Takes the full list as argument
# Sets the global variable "os_commands" as a newline ('\n') seperated list of words
__os_commands() {
  # break $1 on space, tab, and newline characters, by defining IFS
  local s sep=$'\n' IFS=$' '$'\t'$'\n'

  for s in $1;
  do
    if [[ $s == [a-z]* ]]; then
      os_commands="$os_commands$s$sep"
    fi
  done

  IFS="$sep"
}


# Check if the $COMP_WORDS include the word in argument $1
__oscomp_words_include() {
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

__oscomp() {
  # break $1 on space, tab, and newline characters,
  # and turn it into a newline separated list of words
  local list s sep=$'\n' IFS=$' '$'\t'$'\n'
  local cur="${COMP_WORDS[COMP_CWORD]}"
  for s in $1
  do
    # Skip the words that were already passed
    __oscomp_words_include "$s" && continue
    list="$list$s$sep"
  done
  IFS="$sep"
  COMPREPLY=($(compgen -W "$list" -- "$cur"))
  COMPREPLY_FILES=($( compgen -f -X '!*.rb' -- $cur ))
  COMPREPLY+=( "${COMPREPLY_FILES[@]}" )
}

# if the last true command is "measure"
_openstudio_measure() {
  #echo "IN _openstudio_measure"
  local cur prev s_list l_list
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  # Short list
  s_list="-t -u -a -s -h"
  # Long List
  l_list="--update_all --update --compute_arguments --start_server --help"


  case "$cur" in
    --*)
      COMPREPLY=($(compgen -W "$l_list" -- "$cur"))
      ;;
    -*)
      COMPREPLY=($(compgen -W "$s_list" -- "$cur"))
      ;;
    #"")
      ##echo "EMPTY"
      #COMPREPLY=($(compgen -W "$l_list" -- "$cur"))
      #;;
    *)
      prev="${COMP_WORDS[COMP_CWORD-1]}"
      case "$prev" in
          # if prev is measure, complete with flags
          measure            )       COMPREPLY=($(compgen -W "$l_list" -- "$cur"));;
          # Complete files with .osm in there
          -a                 )       COMPREPLY=( $( compgen -f -X '!*.osm' -- $cur ) );;
          --compute_arguments)       COMPREPLY=( $( compgen -f -X '!*.osm' -- $cur ) );;
          # Otherwise, expect a directory
          *                  )       COMPREPLY=($(compgen -d -S "/" -- "$cur"));;

      esac
      ;;
  esac
}

# if the last true command is "run"
_openstudio_run() {
  # echo "IN _openstudio_run"
  local cur list
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  # Short list
  s_list="-w -m -p -s -h"
  # Long List
  l_list="--workflow --measures_only --postprocess_only --socket --debug --help"
  case "$cur" in
    --*)
      COMPREPLY=($(compgen -W "$l_list" -- "$cur"))
      ;;
    -*)
      COMPREPLY=($(compgen -W "$s_list $l_list" -- "$cur"))
      ;;
     *)
      case "$prev" in
          # if prev is run, complete with flags
          run          )          COMPREPLY=($(compgen -W "$l_list" -- "$cur"));;
          # Complete files with .json in there
          -w           )          COMPREPLY=( $( compgen -f -X '!*.json' -- $cur ) );;
          --workflow   )          COMPREPLY=( $( compgen -f -X '!*.json' -- $cur ) );;
      esac
      ;;

  esac
}

# if the last true command is "update"
_openstudio_update() {
  local cur list
  cur="${COMP_WORDS[COMP_CWORD]}"
  case "$cur" in
    --*)
      list="--keep --help"
      COMPREPLY=($(compgen -W "$list" -- "$cur"))
      ;;
    -*)
      list="-k -h"
      COMPREPLY=($(compgen -W "$list" -- "$cur"))
      ;;
     *)
        COMPREPLY=( $( compgen -f -X '!*.osm' -- $cur ) )
      ;;
  esac

}

# Complete with a directory, suffix a "/"
# Check if you can remove the trailing space (won't work on mac, but does it gracefully)
_comp_dir() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=($(compgen -d -S "/" -- "$cur"))
  __trailing_nospace
}

_openstudio()
{
    # i_cmd = index of last command (-, -- or oscomand)
    local i=1 i_cmd=1 cmd j

    #for w in "${COMP_WORDS[@]}";
    #do
        #echo "Word: $w"
    #done

    local cmds="-h
    --help
    --verbose
    --version
    -i
    --include
    -e
    --execute
    --gem_path
    --gem_home
    run
    gem_list
    measure
    update
    execute_ruby_script
    openstudio_version
    energyplus_version
    ruby_version
    list_commands
    labs"

    # Get the total openstudio command list
    # Use the built-in function to return the list of possible commands (ensures this will still work when the cli is updated)
    # Prefix newline to prevent not checking the first command.
    # TODO: Temporary fix: call my local ruby cli instead
    # Uncomment one of these two to make it dynamic
    #   local cmds=$'\n'"$(openstudio list_commands --quiet)"
    #   local cmds=$'\n'"$(ruby /Users/julien/Software/Others/OpenStudio/openstudiocore/src/cli/openstudio_cli.rb list_commands --quiet)"
    # populates a global os_commands variable which is a list of \n seperated commands (not --xxx) such as measure, run, etc
    #   __os_commands "$cmds"
        # I've decided to hardcode the list of commands instead of calling the CLI, it's making it too slow
    # os_commands=$(openstudio list_commands --quiet)
    local os_commands="run
    gem_list
    measure
    update
    execute_ruby_script
    openstudio_version
    energyplus_version
    ruby_version
    list_commands"

    # test if it's in os_commands
    is_os_command=0

    # find the subcommand
    # This skips the first (i=0) which is necessarily 'openstudio'
    # And skips the latest (current)
    # It stops whenever an command is passed
    while [[ "$i" -le "$COMP_CWORD"  && $is_os_command -eq 0 ]];
    do
        local s="${COMP_WORDS[i]}"
        # echo "i=$i, s=$s"

        # Check if it's a command line 'run', 'measure' etc
        for c in $os_commands;
        do
            # If it's a command, we set it to that, and stop processing further
            if [[ "$c" == $s ]];
            then
                is_os_command=1
                i_cmd=$i
                cmd=$s
                break
            fi
        done

        if [[ $is_os_command -eq 0 ]];
        then
            case "$s" in
                # If it's a - or -- command, take that
                -*)
                    cmd="$s"
                    i_cmd=$i
                    ;;
                *)
                    ;;
            esac
        fi
        i="$((++i))"
    done

    #echo "i=$i, i_cmd=$i_cmd, cmd=$cmd, COMP_CWORD=$COMP_CWORD"

    # If only 'openstudio' was passed (with the beggining of something or not), return all possible commands
    if [[ "$i_cmd" -eq "$COMP_CWORD" ]]
    then
        # echo "i_cmd is equal to COMP_WORD"
        # Do not complete gem_list... this is a string replacement: __brewcomp "${cmds/$'\n'gem_list$'\n'/$'\n'}"
        __oscomp "${cmds}"
        return
    fi

    # echo "i=$i, i_cmd=$i_cmd, cmd=$cmd, COMP_CWORD=$COMP_CWORD"

    # subcommands have their own completion functions create list of possible matches and store to ${COMREPLY[@}}
    case "$cmd" in
        --include   )                  _comp_dir ;;
        -i          )                  _comp_dir ;;
        --gem_path  )                  _comp_dir ;;
        --gem_home  )                  _comp_dir ;;

        measure     )                  _openstudio_measure ;;
        run         )                  _openstudio_run ;;
        update      )                  _openstudio_update ;;
        *           )                  __oscomp "${cmds}";;
    esac


    #local cur prev opts cmds
    #COMPREPLY=()  # Array variable storing the possible completions.
    ## Pointer to current completion word.
    ## By convention, it's named "cur" but this isn't strictly necessary.

    #cur="${COMP_WORDS[COMP_CWORD]}"
    #prev="${COMP_WORDS[COMP_CWORD-1]}"
    #opts="-h -i -e --help --verbose --include --execute --gem_path --gem_home"
    #cmds="energyplus_version execute_ruby_script gem_list list_commands measure openstudio_version ruby_version run update"

    #case "${prev}" in
        #"measure")                    _openstudio_measure ;;
        #"run")                        _openstudio_run ;;
        #"update")                     _openstudio_update ;;

        #*)
            ## If the current word is '-' something
            #if [[ ${cur} == -* ]] ; then
                #COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                #return 0
            #else
                #COMPREPLY=( $(compgen -W "${cmds}" -- ${cur}) )
                #return 0
            #fi
            #;;
    #esac
}
complete  -o nosort -F _openstudio openstudio
