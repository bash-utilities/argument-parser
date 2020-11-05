#!/usr/bin/env bash


tests__features__print() {
    printf '# Started -> %s\n' "${FUNCNAME[0]}"

    local -a _acceptable_args=(
        '--equals:print'
        '--long:print'
        '--nil:print-nil'
        '--short|-s:print'
    )

    local -a _arguments_list=(
        '--equals="5pam flav0red H@m"'
        --long 'Ham flavored Spam'
        '"Lamb" jelly'
        -s 'leaking faucets'
    )

    local -a _expected_variable_values=(
        '_equals="5pam flav0red H@m"'
        '_long=Ham flavored Spam'
        '_nil="Lamb" jelly'
        '_short=leaking faucets'
    )

    argument_parser _arguments_list _acceptable_args

    local i
    local _expected_variable_name
    local _expected_variable_value
    for i in "${!_expected_variable_values[@]}"; do
        _expected_variable_name="${_expected_variable_values[${i}]%=*}"
        _expected_variable_value="${_expected_variable_values[${i}]#*=}"
        local -n _parsed_variable_value="${_expected_variable_name}"
        if [[ "${_parsed_variable_value}" != "${_expected_variable_value}" ]]; then
            local -a _error_message=(
                "Function: ${FUNCNAME[0]}"
                "Variable name: ${_expected_variable_name}"
                "Expected value: ${_expected_variable_value}"
                "Parsed value: ${_parsed_variable_value}"
            )
            printf '  %s\n' "${_error_message[@]}"
            return 1
        fi
        unset "${_expected_variable_name}"
    done

    printf '# Finished -> %s\n' "${FUNCNAME[0]}"
}

