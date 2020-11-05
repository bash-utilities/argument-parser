#!/usr/bin/env bash


tests__errors__number() {
    printf '# Started -> %s\n' "${FUNCNAME[0]}"

    local -a _acceptable_args=(
        '--float:number'
        '--integer:number'
        '--negative:number'
    )

    local -a _arguments_list=(
        '--float=S99.99'
        --integer='4two'
        --negative='unsuccessful'
    )

    local i
    local -a _error_argument
    local _exit_status
    local _expected_variable_name
    local -a _error_message
    local _parameter
    local _raw_value
    for i in "${!_arguments_list[@]}"; do
        _parameter="${_arguments_list[${i}]}"
        if [[ "${_parameter}" =~ '=' ]]; then
            _raw_value="${_parameter#*=}"
            _parameter="${_parameter%=*}"
        else
            (( i++ )) || { true; }
            _raw_value="${_arguments_list[${i}]}"
        fi

        if [[ ! "${_parameter}" =~ ^--[[:alnum:]]* ]]; then
            printf >&2 '%s error: pre-parsing _parameter -> %s\n' "${FUNCNAME[0]}" "${_parameter}"
            continue
        fi

        _expected_variable_name="$(sed '{
            s@--*@-@g;
            s@-@_@g;
        }' <<<"${_parameter}")"

        _error_argument=( "${_parameter}" "${_raw_value}" )

        argument_parser _error_argument _acceptable_args 2>/dev/null
        _exit_status="${?}"
        if ! (( _exit_status )); then
            local -n _parsed_variable_value="${_expected_variable_name}"
            _error_message=(
                "Function: ${FUNCNAME[0]}"
                "Exit status: ${_exit_status}"
                "Argument list: ${_error_argument[*]}"
                "Variable name: ${_expected_variable_name}"
                "Variable value: ${_parsed_variable_value}"
            )
            printf >&2 '  %s\n' "${_error_message[@]}"
            return 1
        fi
    done

    printf '# Finished -> %s\n' "${FUNCNAME[0]}"
}

