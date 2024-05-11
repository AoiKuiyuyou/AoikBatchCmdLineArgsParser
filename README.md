# AoikBatchCmdLineArgsParser
Batch command line arguments parser:
- [aoik_batch_cmd_line_args_parser_dde.bat](src/aoik_batch_cmd_line_args_parser_dde.bat)
- [aoik_batch_cmd_line_args_parser_ede.bat](src/aoik_batch_cmd_line_args_parser_ede.bat)

Tested working with:
- Windows 10 cmd.exe

Inspired by: [this post](https://stackoverflow.com/questions/3973824/windows-bat-file-optional-argument-parsing/8162578#8162578)

## Features
- Supported to define a normal option or a flag option.

- Supported to define an option key to contain `%`, `^`, `!` and ` `
  space.

- Supported to define an option default value to contain `%`, `^`, `!`
  and ` ` space.

- Supported to supply an option actual value to contain `%`, `^`, `!`
  and ` ` space.

- Supported to supply an option actual value that is empty.

- Prevented `^` and `!` in an option definition from being treated
  specially so no escaping or quoting is needed.

- Prevented `-key` supplied from matching `--key` defined.

- Provided both `DisableDelayedExpansion` and `EnableDelayedExpansion`
  versions.

- Added extensive comments to explain how the parsing works.

## Usage
- The `OPT_DEFS` variable contains a list of option definitions, delimited
  by unquoted ` ` space.

- An option definition is an `_OPT_KEY_:_OPT_DFT_` pair.
  The option key and option default value are delimited by `:` colon.
  E.g. `--title:test` defines a normal option taking a value.
  E.g. `--version` defines a flag option taking no value.

- `"` double quote should not be used either in an option definition, or
  in the middle of a command line argument, because it would cause quote
  mismatch which interferes with Batch's execution.

- `'` single quote is used to quote option default values. It is not
  allowed to be part of an option default value, but is ok to be part of
  an option actual value.

- Command line argument `--key=val` is automatically converted to two
  arguments `--key` and `val` by CMD. The parser does not handle the
  `--key=val` style directly. If the Batch script is not run by CMD, e.g.
  by a Cygwin program instead, only the `--key val` style works, the
 `--key=val` style not works.

- If the execution failed with the error
  `The syntax of the command is incorrect` or
  `The system cannot find the batch label specified`,
  it might be caused by a bug of Batch that has something to do with the
  number of characters in the code. To let the error go away, try adding
  some comment lines to the middle of the code.

## Examples
- To get result `--flag=1`, define option `--flag`, supply argument
  `--flag`.

- To get result `--key=val`, define option `--key:val`, supply argument
  `--key val` or `--key=val`.

- To get result `--key=`, define option `--key:''`, supply argument
  `--key ""` or `--key=""`.

- To get result `--%=%`, define option `--%%:%%`, supply argument `--% %`
  or `--%=%`.

- To get result `--^=^`, define option `--^:^`, supply argument
  `"--^" "^"` or `"--^"="^"`.

- To get result `--!=!`, define option `--!:!`, supply argument `--! !`
  or `--!=!`.

- To get result `--key with spaces=val with spaces`,
  define option `'--key with spaces':'val with spaces'`,
  supply argument `"--key with spaces" "val with spaces"`
  or `"--key with spaces"="val with spaces"`.
