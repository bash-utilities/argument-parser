#!/usr/bin/env bash

set -E -o functrace


## Find true directory this script resides in
__SOURCE__="${BASH_SOURCE[0]}"
while [[ -h "${__SOURCE__}" ]]; do
    __SOURCE__="$(find "${__SOURCE__}" -type l -ls | sed -n 's@^.* -> \(.*\)@\1@p')"
done
__DIR__="$(cd -P "$(dirname "${__SOURCE__}")" && pwd)"
__PARENT_DIR__=$(dirname "${__DIR__}")


# shellcheck source=argument-parser.sh
source "${__PARENT_DIR__}/argument-parser.sh"

# shellcheck source=.travis-ci/errors/number.sh
source "${__DIR__}/errors/number.sh"

# shellcheck source=.travis-ci/features/boolean.sh
source "${__DIR__}/features/boolean.sh"

# shellcheck source=.travis-ci/features/number.sh
source "${__DIR__}/features/number.sh"

# shellcheck source=.travis-ci/features/print.sh
source "${__DIR__}/features/print.sh"

# shellcheck source=.travis-ci/features/regexp.sh
source "${__DIR__}/features/regexp.sh"

# echo "__DIR__ -> ${__DIR__}"
# echo "__PARENT_DIR__ -> ${__PARENT_DIR__}"


##
#
test_function() {
    local _function_name="${1:?No function_name name provided}"
    "${_function_name}" || {
        local _status="${?}"
        printf 'Failed -> %s\n' "${_function_name}"
        return "${_status}"
    }
}


test_function tests__errors__number

test_function tests__features__boolean
test_function tests__features__number
test_function tests__features__print
test_function tests__features__regexp

