#!/usr/bin/env bash


# Example Usage script for Bash Argument Parser
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


## Optional, but recommended to find true directory this script resides in
__SOURCE__="${BASH_SOURCE[0]}"
while [[ -h "${__SOURCE__}" ]]; do
    __SOURCE__="$(find "${__SOURCE__}" -type l -ls | sed -n 's@^.* -> \(.*\)@\1@p')"
done
__DIR__="$(cd -P "$(dirname "${__SOURCE__}")" && pwd)"


## Source module code within this script
source "${__DIR__}/shared_functions/argument_parser/argument_parser.sh"


## Save passed arguments and acceptable arguments to Bash arrays
_passed_args=("${@:?No arguments provided}")
_acceptable_args=(
    '--help|-h:bool'
    '--directory-path|-d:path'
    '--file-name|-f:print-nil'
)

## Pass arrays by reference/name to the `argument_parser` function
argument_parser '_passed_args' '_acceptable_args'
_exit_status="$?"


## Print documentation for the script and exit, or allow further execution
if ((_help)) || ((_exit_status)); then
    cat <<EOF
Augments script responds to

--help | -h

    Prints this message and exits

--file-name  | -f

    Example argument that may print ${_file_name:-a file name}

--directory-path

    Example augment for paths such as ${_directory_path:-/tmp}
EOF
    exit "${_exit_status:-0}"
fi


## Do scripted things with passed arguments, however, remember to check if
##  required values are not set and either throw an error or set a default
printf '_directory_path -> %s\n' "${_directory_path:?--directory-path not provided}"
printf '_file_name  -> %s\n' "${_file_name:-output.log}"
