## Bash Argument Parser


This repository is intended as a `git submodule` for other Bash scripts that'd be _fancier_ if they'd parse arguments.


------


#### Table of Contents


- [Requirements](#requirements)
- [Installation](#installation)
- [Example Usage](#example-usage)
- [Support](#support)
- [License](#license)


------


## Requirements


Bash version 4 or greater and the following command line utilities;


- `printf` for _returning_ values between functions

- `sed` for _scrubbing_ values within select functions

- `declare` with `-a` and `-g` options available for declaring globally scoped Bash variables and arrays

- `local` with `-n` option available for passing references to variables between functions

- `shopt` with `-s extglob` available for extending what Bash `case` statements are allowed to expand.


> See `info printf` and `info sed` for documentation and `help declare` and `help local` for more information on additional options.


## Installation


Add one of the available `clone` URLs to a current project...


```bash
_url='git@github.com:bash-utilities/argument-parser.git'
_dir='modules/argument-parser'

cd your-project
git submodule add -b master "${_url}" "${_dir}"
```


Or add to a new project...


```bash
_url='https://github.com/bash-utilities/argument-parser.git'

git init new-project
cd new-project
git submodule add -b master "${_url}" "${_dir}"
```


> Older versions of `git` may require the following to populate `${_dir}`...


```bash
git submodule update --init --recursive
```


Check that something similar to the following results from `git status`...


```git
On branch master

Initial commit

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

	new file:   .gitmodules
	new file:   modules/argument-parser
```


... `commit` and `push` these changes then notify anyone contributing to your project that...


```bash
git submodule update --init --recursive
git submodule update --merge
```


... commands may be useful for updating.


> Tip, those that make a fresh `clone` of your project may use...


```bash
git clone --recurse-submodules <your-repositorys-url>
```


> ... to set-up all the various submodules that your project utilizes.


> Note, if at any point in the future `git submodule foreach git status` reports a detached `HEAD`, and that is somehow bothersome then try...


```bash
cd modules/argument-parser
git checkout master
git pull
```


> ... to re-attach the submodule's `HEAD` once again.


Tip, to make `merge` and `remote` the default for `git submodule update` commands...


```bash
git config -f .gitmodules submodule.${_destination}.update 'merge,remote'
```


... which'll also ensure those cloning your project are working from the latest revision of this project.


## Example Usage


```bash
#!/usr/bin/env bash


## Optional, but recommended to find true directory this script resides in
__SOURCE__="${BASH_SOURCE[0]}"
while [[ -h "${__SOURCE__}" ]]; do
    __SOURCE__="$(find "${__SOURCE__}" -type l -ls | sed -n 's@^.* -> \(.*\)@\1@p')"
done
__DIR__="$(cd -P "$(dirname "${__SOURCE__}")" && pwd)"


## Source module code within this script
source "${__DIR__}/modules/argument-parser/argument_parser.sh"


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

- `:regex` similar to `:print`, but also allows for tabs (`\t`) at the beginning and new lines (`\n`) at the end of the passed value, and attempts to escape any periods (`.`) with a back-slash (`\`)

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


... would set _`_source_path`_ and _`_destination_path`_ variables in that order if no option names where provided


## Support


Open a new _`Issue`_ (or up-vote currently opened <sub>[![Issues][badge__issues]][relative_link__issues]</sub> if similar) to report bugs and/or make feature requests a higher priority for project maintainers. Submit _`Pull Requests`_ after _`Forking`_ this repository to add features or fix bugs, and be counted among this project's <sub>[![Members][badge__contributors]][relative_link__members]</sub>


> See GitHub's documentation on [Forking][help_fork] and issuing [Pull Requests][help_pull_request] if these are new terms.
>
> And check the chapter regarding [submodules][git_book__submodules] from the Git book prior to opening issues regarding submodule _trouble-shooting_


Supporting projects like this one through <sub>[![Liberapay][badge__liberapay]][liberapay_donate]</sub> or via Bitcoin <sub>[![BTC][badge__bitcoin]][btc]</sub> is most welcomed, and encourages projects like these to remain free of advertising.


## License


```
Bash Argument Parser, a submodule for other Bash scripts tracked by Git
Copyright (C) 2019  S0AndS0

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



[help_fork]: https://help.github.com/en/articles/fork-a-repo
[help_pull_request]: https://help.github.com/en/articles/about-pull-requests

[git_book__submodules]: https://git-scm.com/book/en/v2/Git-Tools-Submodules


[relative_link__issues]: issues
[relative_link__members]: network/members
[source_link__argument_parser]: argument_parser.sh


[badge__issues]: https://img.shields.io/github/issues/bash-utilities/argument-parser.svg
[badge__contributors]: https://img.shields.io/github/forks/bash-utilities/argument-parser.svg?color=005571&label=Contributors

[badge__liberapay]: https://img.shields.io/badge/Liberapay-gray.svg?logo=liberapay
[badge__bitcoin]: https://img.shields.io/badge/1Dr9KYZz9jkUea5xTxeGyScu7AwC4MwR5c-gray.svg?logo=bitcoin


[liberapay_donate]: https://liberapay.com/bash-utilities/donate
[btc]: https://www.blockchain.com/btc/address/1Dr9KYZz9jkUea5xTxeGyScu7AwC4MwR5c
