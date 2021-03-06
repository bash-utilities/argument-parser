#!/usr/bin/env bash


# argument-parser.sh, source it in other Bash scripts for argument parsing
# Copyright (C) 2020  S0AndS0
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation; version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


# shellcheck disable=SC2034
{
    _TRUE='1'
    _DEFAULT_ACCEPTABLE_ARG_LIST=('--help|-h:bool' '--foo|-f:print' '--path:path-nil')
}


##
# Removes characters that are not letters or numbers
# @example
#   argument_parser__scrub__alpha_numeric '0.1 foo^' "bar's"
#   #> 01foobars
argument_parser__scrub__alpha_numeric(){
    printf '%s' "${@//[^a-z0-9A-Z]/}"
}


##
# Allows single dots, or dashes, and some punctuation
# @example
#   argument_parser__scrub__list "spam, 'flavored'" ham
#   #> spam, 'flavored' ham
argument_parser__scrub__list(){
    printf '%s' "$(sed '{
        s@\.\.*@.@g;
        s@--*@-@g;
    }' <<<"${@//[^a-z0-9A-Z,+_./@:-]/}")"
}


##
# Allows integer, or floating point, numbers ether signed or unsigned
# @example
#   argument_parser__scrub__number -99.88.33-77
#   #> -99.88
argument_parser__scrub__number(){
    local _value
    _value="$(sed '{
        s@\.\.*@.@g;
        s@--*@-@g;
    }' <<<"${@//[^0-9.-]/}")"

    local _value_only_periods="${_value//[^.]/}"
    [[ "${#_value_only_periods}" -gt 1 ]] && {
        _value="${_value%.*}"
    }

    local _value_only_dashes="${_value//[^-]/}"
    [[ "${#_value_only_dashes}" -gt 1 ]] && {
        _value="${_value%-*}"
    }

    printf '%s' "${_value}"
}


##
# Allows path like strings
# @example
#   argument_parser__scrub__path '~/dir/file' 'name.ext'
#   #> ~/dir/file name.ext
argument_parser__scrub__path(){
    printf '%s' "$(sed '{
        s@\.\.*@.@g;
        s@--*@-@g;
    }' <<<"${@//[^a-z0-9A-Z ~+_./@:-]/}")"
}


##
# Removes most characters that are not posix compatible
# @example
#   argument_parser__scrub__posix '_$spam" "flavored_spam'
#   #> spamflavored_spam
argument_parser__scrub__posix(){
    local _value
    _value="$(sed '{
        s@^[-_.]@@g;
        s@[-_.]$@@g;
        s@\.\.*@.@g;
        s@--*@-@g;
    }' <<<"${@//[^a-z0-9A-Z_.-]/}")"
    printf '%s' "${_value::32}"
}


##
# Allows most RegExp related characters
# @example
#   name regexp="$(argument_parser__scrub__regex '^([A-Z|0-9])[a-z]+$')"
#   [[ 'Name' =~ ${name_regexp} ]] && {
#       echo 'Totally proper'
#   }
#   #> Totally proper
#
#   [[ 'thing' =~ ${name_regexp} ]] || {
#       echo 'Not a name'
#   }
#   #> Not a name
argument_parser__scrub__regex(){
    printf '%s' "${@//[^[:print:]$'\t'$'\n']/}"
}


##
# Parses value as type with scrubbers
# @parameter {number | string} $1 _raw_value -
# @parameter {string}          $2 _opt_type  -
# @throws
#   - STATUS -> 1
#   - STDERR -> ## Error - argument_parser__scrub_by_type detected differences in values
# @example
#   argument_parser__scrub_by_type 'spam "flavored" ham' 'print'
#   #> spam "flavored" ham
argument_parser__scrub_by_type(){
    local _raw_value="${1}"
    local _opt_type="${2:?## Error - no option type provided to argument_parser__scrub_by_type}"
    local _value
    case "${_opt_type}" in
        'alpha_numeric'*) _value="$(argument_parser__scrub__alpha_numeric "${_raw_value}")" ;;
        'bool'*)          _value="${_TRUE}"                                                 ;;
        'list'*)          _value="$(argument_parser__scrub__list "${_raw_value}")"          ;;
        'number'*)        _value="$(argument_parser__scrub__number "${_raw_value}")"        ;;
        'path'*)          _value="$(argument_parser__scrub__path "${_raw_value}")"          ;;
        'posix'*)         _value="$(argument_parser__scrub__posix "${_raw_value}")"         ;;
        'print'*)         _value="${_raw_value//[^[:print:]]/}"                             ;;
        'raw'*)           _value="${_raw_value}"                                            ;;
        'regex'*)         _value="$(argument_parser__scrub__regex "${_raw_value}")"         ;;
    esac

    if [[ "${_opt_type}" =~ ^'bool'* ]] || [[ "${_raw_value}" == "${_value}" ]]; then
        printf '%s' "${_value}"
    else
        printf >&2 '## %s error -> detected differences in values\n' "${FUNCNAME[0]}"
        return 1
    fi
}


##
# Parses argument array references and assigns variables with scrubbed values
# @parameter {ArrayRef} $1 _arg_user_ref   -
# @parameter {ArrayRef} $2 _arg_accept_ref -
# @example - script-name.sh
#   #!/usr/bin/env bash
#
#   _passed_args=("${@:?No arguments provided}")
#
#   _acceptable_args=(
#       '--help|-h:bool'
#       '--directory:path'
#       '--file:print-nil'
#   )
#
#   argument_parser _passed_args _acceptable_args
#
#   printf '_help      -> %i\n' "${_help:-0}"
#   printf '_directory -> %s\n' "${_directory}"
#   printf '_file      -> %s\n' "${_file}"
#
# @example
#   script-name.sh --directory some/where 'file-name.ext'
#   #> _help      -> 0
#   #> _directory -> some/where
#   #> _file      -> file-name.ext
argument_parser(){
    local -n _arg_user_ref="${1:?# No reference to an argument list/array provided}"
    local -n _arg_accept_ref="${2:-_DEFAULT_ACCEPTABLE_ARG_LIST}"
    local -a _args_user_list=( "${_arg_user_ref[@]}" )

    local _acceptable_arg
    local _opt_name
    local _var_name
    local _opt_type
    local _args_user_list_index
    local _user_opt
    local _var_value
    local _exit_status

    local _arg_accept_ref_index
    for _arg_accept_ref_index in "${!_arg_accept_ref[@]}"; do
        _acceptable_arg="${_arg_accept_ref[${_arg_accept_ref_index}]}"
        ## Take a break when user supplied argument list becomes empty
        (( ${#_args_user_list[@]} )) || { break; }
        ## First in listed acceptable arg is used as variable name to save value to
        ##  example, '--foo-bar fizz' would transmute into '_foo_bar=fizz'
        _opt_name="${_acceptable_arg%%[:|]*}"
        _var_name="${_opt_name#*[-]}"
        _var_name="${_var_name#*[-]}"
        _var_name="_${_var_name//-/_}"
        ## Divine the type of argument allowed for this iteration of acceptable args
        _opt_type="${_acceptable_arg##*[:]}"
        _opt_type="${_opt_type:-bool}"

        ## Set case expressions to match user arguments against and for non-bool type
        ##  what alternative case expression to match on.
        ##  example '--foo|-f' will also check for '--foo=*|-f=*'
        _acceptable_pattern="${_acceptable_arg%%:*}"
        if ! (( ${#_acceptable_pattern} )); then
            printf >&2 '%s error -> cannot parse acceptable pattern from %s\n' "${FUNCNAME[0]}" "${_acceptable_arg}"
            return 1
        fi

        ## Attempt to match up user supplied arguments with those that are valid
        for _args_user_list_index in "${!_args_user_list[@]}"; do
            _user_opt="${_args_user_list[${_args_user_list_index}]}"
            if [[ "${_user_opt}" =~ ^(${_acceptable_pattern})$ ]]; then
                ## Parse for script-name --foo bar or --true
                if [[ "${_opt_type}" =~ ^'bool'* ]]; then
                    _var_value="$(argument_parser__scrub_by_type "${_user_opt}" "${_opt_type}")"
                    _exit_status="${?}"
                else
                    (( _args_user_list_index++ )) || { true; }
                    _var_value="$(argument_parser__scrub_by_type "${_args_user_list[${_args_user_list_index}]}" "${_opt_type}")"
                    _exit_status="${?}"
                    unset _args_user_list[$(( _args_user_list_index - 1 ))]
                fi
            elif [[ "${_user_opt}" =~ ^(${_acceptable_pattern})=[[:print:]]*$ ]]; then
                ## Parse for script-name --foo=bar
                _var_value="$(argument_parser__scrub_by_type "${_user_opt#*=}" "${_opt_type}")"
                _exit_status="${?}"
            elif [[ "${_opt_type}" =~ [[:print:]]*(nil|none)$ ]]; then
                ## Parse for script-name direct_value
                _var_value="$(argument_parser__scrub_by_type "${_user_opt}" "${_opt_type}")"
                _exit_status="${?}"
            fi
            (( _exit_status )) && { return ${_exit_status}; }

            ## Break on matched options after clearing temp variables and re-assigning
            ##  list (array) of user supplied arguments.
            ## Note, re-assigning is to ensure the next looping indexes correctly
            ##  and is designed to require less work on each iteration
            if (( ${#_var_value} )); then
                declare -g "${_var_name}=${_var_value}"
                declare -ag "_assigned_args+=( '${_opt_name}=${_var_value}' )"
                unset _user_opt
                unset _var_value
                unset _args_user_list[${_args_user_list_index}]
                unset _exit_status
                _args_user_list=( "${_args_user_list[@]}" )
                break
            fi
        done
        unset _opt_type
        unset _opt_name
        unset _var_name
    done
}


#
#    Inspiration &/or information sources
#
## https://stackoverflow.com/questions/16860877/remove-an-element-from-a-bash-array
## https://unix.stackexchange.com/questions/234264/how-can-i-use-a-variable-as-a-case-condition
