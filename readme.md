## Bash Argument Parser


This repository is intended as a `git submodule` for other Bash scripts that'd be _fancier_ if they'd parse arguments.


------


#### Table of Contents


- [Requirements](#requirements)
- [Installation](#installation)
- [Example Usage](#example-usage)
- [Support](#support)


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


By adding one of the available `clone` URLs to a current project...


```bash
_url='https://github.com/bash-utilities/argument-parser.git'
_dir='modules/argument-parser'

cd your-project
git submodule add -b master --name argument-parser "${_url}" "${_dir}"
```


> Note, older versions of `git` may require the following to populate `${_dir}`...


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


> Note, if at any point in the future `git submodule foreach git status` reports a detached `HEAD`, and that is somehow bothersome then try...


```bash
cd modules/argument-parser
git checkout master
git pull
```


> ... to re-attach the submodule's `HEAD` once again.


## Example Usage


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
    '--file-name|-f:print-nil'
    '--directory-path:path'
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


## Do scripted things with passed arguments, however, do remember to check
##  if required values are set and either throw an error or default
printf '_directory_path -> %s\n' "${_directory_path:?--path not provided}"
printf '_file_name  -> %s\n' "${_file_name:-output.log}"
```


Arguments such as _`--file-name`_ are _transmuted_ into variable names like _`_file_name`_, and short options may be listed with pipes (`|`) as a separator; eg. _`--file-name|-f|--fname|-n`_ would match and set the _`_file_name`_ variable for `-f`, `-n`, or `--fname`, etc. The first option listed will become the variable name, thus it's a _good idea_ to list the long option first, eg. _`-f|--file-name`_ would be a _bad idea_ as that would set a variable named _`_f`_... a nightmare to debug.


Available argument parsing _types_ are


- `:bool` sets `0` or `1` for `false` or `true` if related argument was passed

- `:raw` sets _unfiltered_ value for related argument

- `:path` sets value for related argument minus non-alphanumeric or; ` `, `~`, `+`, `_`, `.`, `@`, `:`, `-`, characters as well as removing duplicated `..` and/or `--` from the beginning of passed value

- `:posix` filters passed value for non-alphanumeric or; `_`, `.`, `-`, characters as well as removing duplicated `..` and/or `--` from the beginning of passed value. Additionally the `_`, `.`, `-` characters are _scrubbed_ from both the beginning and end of passed value, and only the **first** `32` characters that pass these constraints are set

- `:print` sets passed value minus any _non-`[:print:]`-able_ characters

- `:regex` similar to `:print`, but also allows for tabs (`\t`) at the beginning and new lines (`\n`) at the end of the passed value, and attempts to escape any periods (`.`) with a back-slash (`\`)

- `:list` _scrubs_ leading duplicated `..` and/or `--` from passed value and sets anything alphanumeric and; `,`, `+`, `_`, `.`, `@`, `:`, `-` characters if any from passed value

- `:alpha_numeric` _scrubs_ any non-alphanumeric characters from passed value


These are intended for catching or forgiving typos, and should not be considered secure in untrusted and/or hostile environments.


The `-nil` _modifier_ may be appended to any but `:bool` option _types_ to make an argument option optional, eg. _`--file-name`_ from the above [example](#example-usage) script will also set from something like _`script-name.sh --directory-path=/tmp file-name.ext`_ meaning that the `--file-name` option was _assumed_ to prefix the _`file-name.ext`_ value.


> Note, `:list` does **not** set an array but instead a string that contains the most common list separators, in the future an `:array` _type_ might be added to set a Bash arrays too.


## Support


Open a new _`Issue`_ (or up-vote currently opened <sub>[![Issues][badge__issues]][relative_link__issues]</sub> if similar) to report bugs and/or make feature requests a higher priority for project maintainers. Submit _`Pull Requests`_ after _`Forking`_ this repository to add features or fix bugs, and be counted among this project's contributing <sub>[![Members][badge__members]][relative_link__members]</sub>


> See GitHub's documentation on [Forking][help_fork] and issuing [Pull Requests][help_pull_request] if these are new terms.



[relative_link__issues]: issues
[relative_link__members]: network/members


[badge__issues]: https://img.shields.io/github/issues/bash-utilities/argument-parser.svg
[badge__members]: https://img.shields.io/github/forks/bash-utilities/argument-parser.svg?color=005571&label=members



[help_fork]: https://help.github.com/en/articles/fork-a-repo
[help_pull_request]: https://help.github.com/en/articles/about-pull-requests
