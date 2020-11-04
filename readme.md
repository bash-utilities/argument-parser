# Bash Argument Parser
[heading__title]:
  #bash-argument-parser
  "&#x2B06; Top of ReadMe File"


This repository is intended as a `git submodule` for other Bash scripts that'd be _fancier_ if they'd parse arguments.


------


#### Table of Contents


- [&#x2B06; Top of ReadMe File][heading__title]

- [Requirements](#requirements)

- [&#9889; Quick Start][heading__quick_start]

  - [Edit Your ReadMe File][heading__your_readme_file]
  - [Utilize Argument Parser][heading__utilize_submodule]
  - [Commit and Push][heading__commit_and_push]

- [&#x2696; License][license]



------


## Requirements


Bash version `4.4` or greater and the following command line utilities;


- `printf` for _returning_ values between functions

- `sed` for _scrubbing_ values within select functions

- `declare` with `-a` and `-g` options available for declaring globally scoped Bash variables and arrays

- `local` with `-n` option available for passing references to variables between functions

- `shopt` with `-s extglob` available for extending what Bash `case` statements are allowed to expand.


> See `info printf` and `info sed` for documentation and `help declare` and `help local` for more information on additional options.


## Quick Start
[heading__quick_start]:
  #quick-start
  "&#9889; Perhaps as easy as one, 2.0,..."

**Bash Variables**


```Bash
_module_https_url='https://github.com/bash-utilities/argument-parser.git'
_module_relative_path='modules/argument-parser'
```


**Bash Submodule Commands**


```Bash
cd "<your-git-project-path>"

mkdir -vp "modules"

git submodule add -b master --name argument-parser "${_module_https_url}" "${_module_relative_path}"
```


### Your ReadMe File
[heading__your_readme_file]:
  #your-readme-file
  "Suggested additions for your ReadMe.md file so everyone has a good time with submodules"


> **Your Quick Start Section**


```MarkDown
Clone with the following to avoid incomplete downloads



    git clone --recurse-submodules <url-for-your-project>


Update/upgrade submodules via


    git submodule update --init --recursive
    git submodule update --merge
```


### Utilize Argument Parser
[heading__utilize_submodule]:
  #utilize-argument-parser
  "How to make use of this submodule within another project"


```bash
#!/usr/bin/env bash


## Find true directory this script resides in
__SOURCE__="${BASH_SOURCE[0]}"
while [[ -h "${__SOURCE__}" ]]; do
    __SOURCE__="$(find "${__SOURCE__}" -type l -ls | sed -n 's@^.* -> \(.*\)@\1@p')"
done
__DIR__="$(cd -P "$(dirname "${__SOURCE__}")" && pwd)"


## Source module code within this script
source "${__DIR__}/modules/argument-parser/argument-parser.sh"


## Save passed arguments and acceptable arguments to Bash arrays
_passed_args=("${@:?No arguments provided}")
_acceptable_args=(
    '--help|-h:bool'
    '--directory-path|-d:path'
    '--file-name:print-nil'
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

--directory-path

    Example augment for paths such as ${_directory_path:-/tmp}

<file-name>

    Example argument that may print ${_file_name:-a file name}
EOF
    exit "${_exit_status:-0}"
fi


## Do scripted things with passed arguments, however, remember to check if
##  required values are not set and either throw an error or set a default
printf '_directory_path -> %s\n' "${_directory_path:?--directory-path not provided}"
printf '_file_name  -> %s\n' "${_file_name:-output.log}"
```


Arguments such as _`--file-name`_ are _transmuted_ into variable names like _`_file_name`_, and short options may be listed with pipes (`|`) as a separator; eg. _`--directory-path|-d|--dpath`_ would match and set the _`_directory_path`_ variable for `-d`, or `--dpath`, etc. The first option listed will become the variable name, thus it's a _good idea_ to list the long option first, eg. _`-d|--directory-path`_ would be a _bad idea_ as that would set a variable named _`_d`_... a nightmare to debug.


Available argument parsing _types_ are


- `:bool` sets `0` or `1` for `false` or `true` if related argument was passed

- `:raw` sets _unfiltered_ value for related argument

- `:path` sets value for related argument minus non-alphanumeric or; ` `, `~`, `+`, `_`, `.`, `@`, `:`, `-`, characters as well as removing duplicated `..` and/or `--` from the beginning of passed value

- `:posix` filters passed value for non-alphanumeric or; `_`, `.`, `-`, characters as well as removing duplicated `..` and/or `--` from the beginning of passed value. Additionally the `_`, `.`, `-` characters are _scrubbed_ from both the beginning and end of passed value, and only the **first** `32` characters that pass these constraints are set

- `:print` sets passed value minus any _non-`[:print:]`-able_ characters

- `:regex` similar to `:print`, but also allows for tabs (`\t`) at the beginning and new lines (`\n`) at the end of the passed value

- `:list` _scrubs_ leading duplicated `..` and/or `--` from passed value and sets anything alphanumeric and; `,`, `+`, `_`, `.`, `@`, `:`, `-` characters if any from passed value

- `:alpha_numeric` _scrubs_ any non-alphanumeric characters from passed value


> Note, `:list` does **not** set an array but instead a string that contains the most common list separators, in the future an `:array` _type_ might be added to set a Bash arrays too.


These are intended for catching or forgiving typos, and should not be considered secure in untrusted and/or hostile environments.


The `-nil` _modifier_ may be appended to any but `:bool` option _types_ to make an argument _greedy_, eg. _`--file-name`_ from the above [example](#example-usage) script will also set from something like _`script-name.sh --directory-path=/tmp file-name.ext`_ meaning that the `--file-name` option was _assumed_ to prefix the _`file-name.ext`_ value.


One warning regarding the `-nil` _modifier_, place argument options using `-nil` at the end/bottom of the `_acceptable_args` Bash array, eg...


```bash
_acceptable_args=(
    '--help|-h:bool'
    '--file-name|-f:print-nil'
    '--directory-path|-d:path'
)
```


... would be lead to a _bad time_ when attempting to use the values within _`_file_name`_ and _`_directory_path`_ variables.


Multiple `-nil` modified options maybe _stacked_, eg...


```bash
_acceptable_args=(
    '--help|-h:bool'
    '--source-path|-s:path-nil'
    '--destination-path|-d:path-nil'
)
```


### Commit and Push
[heading__commit_and_push]:
  #commit-and-push
  "It may be just this easy..."


```Bash
git add .gitmodules
git add modules/argument-parser


## Add any changed files too


git commit -F- <<'EOF'
Submodule `bash-utilities/argument-parser` added for argument parsing


## Add anything else of note...
EOF


git push origin gh-pages
```


___



## License
[license]:
  #license
  "&#x2696; Legal bits of Open Source software"


```
Argument Parser documentation from Bash Utilities
Copyright (C) 2020  S0AndS0

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation; version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```
