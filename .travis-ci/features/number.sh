#!/usr/bin/env bash


tests__features__number() {
    printf '# Started -> %s\n' "${FUNCNAME[0]}"

    local -a _acceptable_args=(
        '--float-equals:number'
        '--float-long:number'
        '--float-nil:number-nil'
        '--float-short|-f:number'
        '--integer-equals:number'
        '--integer-long:number'
        '--integer-nil:number-nil'
        '--integer-short|-i:number'
        '--negative-equals:number'
        '--negative-long:number'
        '--negative-nil:number-nil'
        '--negative-short|-n:number'
    )

    local -a _arguments_list=(
        '--float-equals=99.99'
        --float-long 4.2
        8.3
        -f 7.58
        --integer-equals=99
        --integer-long 42
        83
        -i 758
        --negative-equals=-99
        --negative-long -42
        -8.3
        -n -7.58
    )

    local -a _expected_variable_values=(
        '_float_equals=99.99'
        '_float_long=4.2'
        '_float_nil=8.3'
        '_float_short=7.58'
        '_integer_equals=99'
        '_integer_long=42'
        '_integer_nil=83'
        '_integer_short=758'
        '_negative_equals=-99'
        '_negative_long=-42'
        '_negative_nil=-8.3'
        '_negative_short=-7.58'
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

