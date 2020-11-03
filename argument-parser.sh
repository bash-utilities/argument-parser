#!/usr/bin/env bash


# argument-parser.sh, source it in other Bash scripts for argument parsing
# Copyright (C) 2019  S0AndS0
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


shopt -s extglob


_TRUE='1'
_DEFAULT_ACCEPTABLE_ARG_LIST=('--help|-h:bool' '--foo|-f:print' '--path:path-nil')


arg_scrubber_alpha_numeric(){
    printf '%s' "${@//[^a-z0-9A-Z]/}"
}


arg_scrubber_list(){
    printf '%s' "$(sed 's@\.\.*@.@g; s@--*@-@g' <<<"${@//[^a-z0-9A-Z,+_./@:-]/}")"
}


arg_scrubber_number(){
    printf '%s\n' "$(sed 's@\.\.*@.@g; s@--*@-@g' <<<"${@//[^0-9.-]/}")"
}


arg_scrubber_path(){
    printf '%s' "$(sed 's@\.\.*@.@g; s@--*@-@g' <<<"${@//[^a-z0-9A-Z ~+_./@:-]/}")"
}


arg_scrubber_posix(){
    local _value="${@//[^a-z0-9A-Z_.-]/}"
    _value="$(sed 's@^[-_.]@@g; s@[-_.]$@@g; s@\.\.*@.@g; s@--*@-@g' <<<"${_value}")"
    printf '%s' "${_value::32}"
}


arg_scrubber_regex(){
    printf '%s' "$(sed 's@.@\\.@g' <<<"${@//[^[:print:]$'\t'$'\n']/}")"
}


return_scrubbed_arg(){
    local _raw_value="${1}"
    local _opt_type="${2:?## Error - no option type provided to return_scrubbed_arg}"
    local _value
    case "${_opt_type}" in
        'alpha_numeric'*) _value="$(arg_scrubber_alpha_numeric "${_raw_value}")" ;;
        'bool'*)          _value="${_TRUE}"                                      ;;
        'list'*)          _value="$(arg_scrubber_list "${_raw_value}")"          ;;
        'number'*)        _value="$(arg_scrubber_number "${_raw_value}")"        ;;
        'path'*)          _value="$(arg_scrubber_path "${_raw_value}")"          ;;
        'posix'*)         _value="$(arg_scrubber_posix "${_raw_value}")"         ;;
        'print'*)         _value="${_raw_value//[^[:print:]]/}"                  ;;
        'raw'*)           _value="${_raw_value}"                                 ;;
        'regex'*)         _value="$(arg_scrubber_regex "${_raw_value}")"         ;;
    esac

    if [[ "${_opt_type}" =~ ^'bool'* ]] || [[ "${_raw_value}" == "${_value}" ]]; then
        printf '%s' "${_value}"
    else
        printf '## Error - return_scrubbed_arg detected differences in values\n' >&2
        return 1
    fi
}


argument_parser(){
    local -n _arg_user_ref="${1:?# No reference to an argument list/array provided}"
    local -n _arg_accept_ref="${2:-_DEFAULT_ACCEPTABLE_ARG_LIST}"
    local _args_user_list=( "${_arg_user_ref[@]}" )
    unset _assigned_args
    for _acceptable_args in ${_arg_accept_ref[@]}; do
        ## Take a break when user supplied argument list becomes empty
        [[ "${#_args_user_list[@]}" == '0' ]] && break
        ## First in listed acceptable arg is used as variable name to save value to
        ##  example, '--foo-bar fizz' would transmute into '_foo_bar=fizz'
        local _opt_name="${_acceptable_args%%[:|]*}"
        local _var_name="${_opt_name#*[-]}"
        _var_name="${_var_name#*[-]}"
        _var_name="_${_var_name//-/_}"
        ## Divine the type of argument allowed for this iteration of acceptable args
        case "${_acceptable_args}" in
            *':'*) local _opt_type="${_acceptable_args##*[:]}" ;;
            *)     local _opt_type="bool"                      ;;
        esac
        ## Set case expressions to match user arguments against and for non-bool type
        ##  what alternative case expression to match on.
        ##  example '--foo|-f' will also check for '--foo=*|-f=*'
        local _arg_opt_list="${_acceptable_args%%:*}"
        local _valid_opts_pattern="@(${_arg_opt_list})"
        case "${_arg_opt_list}" in
            *'|'*) local _valid_opts_pattern_alt="@(${_arg_opt_list//|/=*|}=*)" ;;
            *)     local _valid_opts_pattern_alt="@(${_arg_opt_list}=*)"        ;;
        esac
        ## Attempt to match up user supplied arguments with those that are valid
        for (( i = 0; i < "${#_args_user_list[@]}"; i++ )); do
            local _user_opt="${_args_user_list[${i}]}"
            case "${_user_opt}" in
                ${_valid_opts_pattern})     ## Parse for script-name --foo bar or --true
                    if [[ "${_opt_type}" =~ ^'bool'* ]]; then
                        local _var_value="$(return_scrubbed_arg "${_user_opt}" "${_opt_type}")"
                        local _exit_status="${?}"
                    else
                        i+=1
                        local _var_value="$(return_scrubbed_arg "${_args_user_list[${i}]}" "${_opt_type}")"
                        local _exit_status="${?}"
                        unset _args_user_list[$(( i - 1 ))]
                    fi
                ;;
                ${_valid_opts_pattern_alt}) ## Parse for script-name --foo=bar
                    local _var_value="$(return_scrubbed_arg "${_user_opt#*=}" "${_opt_type}")"
                    local _exit_status="${?}"
                ;;
                *)                          ## Parse for script-name direct_value
                    case "${_opt_type}" in
                        *'nil'|*'none')
                            local _var_value="$(return_scrubbed_arg "${_user_opt}" "${_opt_type}")"
                            local _exit_status="${?}"
                        ;;
                    esac
                ;;
            esac
            if ((_exit_status)); then return ${_exit_status}; fi
            ## Break on matched options after clearing temp variables and re-assigning
            ##  list (array) of user supplied arguments.
            ## Note, re-assigning is to ensure the next looping indexes correctly
            ##  and is designed to require less work on each iteration
            if [ -n "${_var_value}" ]; then
                declare -g "${_var_name}=${_var_value}"
                declare -ag "_assigned_args+=('${_opt_name}=\"${_var_value}\"')"
                unset _user_opt
                unset _var_value
                unset _args_user_list[${i}]
                unset _exit_status
                _args_user_list=("${_args_user_list[@]}")
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
