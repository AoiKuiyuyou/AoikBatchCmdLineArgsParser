@ECHO OFF

REM # ++++++++++ AoikBatchCmdLineArgsParser [EnableDelayedExpansion] ++++++++++
REM # Version: 1.0.0
REM #
REM # Inspired by this post:
REM # https://stackoverflow.com/questions/3973824/windows-bat-file-optional-argument-parsing/8162578#8162578
REM #
REM # +++++ Features +++++
REM # - Supported to define a normal option or a flag option.
REM #
REM # - Supported to define an option key to contain `%`, `^`, `!` and ` `
REM #   space.
REM #
REM # - Supported to define an option default value to contain `%`, `^`, `!`
REM #   and ` ` space.
REM #
REM # - Supported to supply an option actual value to contain `%`, `^`, `!`
REM #   and ` ` space.
REM #
REM # - Supported to supply an option actual value that is empty.
REM #
REM # - Prevented `^` and `!` in an option definition from being treated
REM #   specially so no escaping or quoting is needed.
REM #
REM # - Prevented `-key` supplied from matching `--key` defined.
REM #
REM # - Provided both `DisableDelayedExpansion` and `EnableDelayedExpansion`
REM #   versions.
REM #
REM # - Added extensive comments to explain how the parsing works.
REM #
REM # +++++ Usage +++++
REM # - The `OPT_DEFS` variable contains a list of option definitions, delimited
REM #   by unquoted ` ` space.
REM #
REM # - An option definition is an `_OPT_KEY_:_OPT_DFT_` pair.
REM #   The option key and option default value are delimited by `:` colon.
REM #   E.g. `--title:test` defines a normal option taking a value.
REM #   E.g. `--version` defines a flag option taking no value.
REM #
REM # - `"` double quote should not be used either in an option definition, or
REM #   in the middle of a command line argument, because it would cause quote
REM #   mismatch which interferes with Batch's execution.
REM #
REM # - `'` single quote is used to quote option default values. It is not
REM #   allowed to be part of an option default value, but is ok to be part of
REM #   an option actual value.
REM #
REM # - Command line argument `--key=val` is automatically converted to two
REM #   arguments `--key` and `val` by CMD. The parser does not handle the
REM #   `--key=val` style directly. If the Batch script is not run by CMD, e.g.
REM #   by a Cygwin program instead, only the `--key val` style works, the
REM #  `--key=val` style not works.
REM #
REM # - If the execution failed with the error
REM #   `The syntax of the command is incorrect` or
REM #   `The system cannot find the batch label specified`,
REM #   it might be caused by a bug of Batch that has something to do with the
REM #   number of characters in the code. To let the error go away, try adding
REM #   some comment lines to the middle of the code.
REM #
REM # +++++ Examples +++++
REM # - To get result `--flag=1`, define option `--flag`, supply argument
REM #   `--flag`.
REM #
REM # - To get result `--key=val`, define option `--key:val`, supply argument
REM #   `--key val` or `--key=val`.
REM #
REM # - To get result `--key=`, define option `--key:''`, supply argument
REM #   `--key ""` or `--key=""`.
REM #
REM # - To get result `--%=%`, define option `--%%:%%`, supply argument `--% %`
REM #   or `--%=%`.
REM #
REM # - To get result `--^=^`, define option `--^:^`, supply argument
REM #   `"--^" "^"` or `"--^"="^"`.
REM #
REM # - To get result `--!=!`, define option `--!:!`, supply argument `--! !`
REM #   or `--!=!`.
REM #
REM # - To get result `--key with spaces=val with spaces`,
REM #   define option `'--key with spaces':'val with spaces'`,
REM #   supply argument `"--key with spaces" "val with spaces"`
REM #   or `"--key with spaces"="val with spaces"`.

REM # Create a local context. All variables set will not leak to outer context.
SETLOCAL EnableDelayedExpansion

REM # Set program name.
SET "PROG_NAME=aoik_batch_cmd_line_args_parser_ede"

REM # Set log prefix.
SET "LOG_PREFIX=# +++++ [%PROG_NAME%] "

REM # Code below aims to define the command line options.
REM //ECHO 1>&2%LOG_PREFIX%INFO: 1O9J8: opts_define

REM # Disable delayed expansion so that `^` and `!` are not treated specially by
REM # delayed expansion. `^` may still be treated specially by early expansion
REM # but can be preserved by enclosing `"`.
SETLOCAL DisableDelayedExpansion

REM # The command line option definitions.
SET "OPT_DEFS=--flag '--flag2' --key:val '--key2':'val2' --key3:'' --%%:%% --^:^ --!:! --%%%%:%%%% --^^:^^ --!!:!! '--%%%%%%':'%%%%%%' '--^^^':'^^^' '--!!!':'!!!' '--key with spaces':'val with spaces'"

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 3L9E7: OPT_DEFS_INIT: "%OPT_DEFS%"

REM # Store the option definitions to variable `VAL`, which will be accessed in
REM # the subroutines below.
SET "VAL=%OPT_DEFS%"

REM # Escape `^` and `!` to counteract the delayed expansion on the `FOR` loop
REM # variable below.
CALL :val_escape_caret
CALL :val_escape_exclamation

REM # Enable delayed expansion to get the latest value after the escaping.
SETLOCAL EnableDelayedExpansion

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 9H4U2: OPT_DEFS_ESC: `!VAL!`

REM # ----- 8S1I6 -----
REM # Use the `FOR` loop variable trick to pass the value to the outer context.
REM #
REM # The enclosing `"` will not cause quote mismatch as the option definitions
REM # contain no `"`.
REM #
FOR /f delims^=^ eol^= %%X IN ("!VAL!") DO (
  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 1A7Q5: for_var: OPT_DEFS: `%%X!!` [after delayed expansion]

  REM # End the two local contexts entered above.
  ENDLOCAL
  ENDLOCAL

  REM # Set the variable of the outer context.
  REM #
  REM # Early expansion's special treatment of `^` not happens to a `FOR` loop
  REM # variable so enclosing `"` is not needed.
  REM #
  REM # Delayed expansion's special treatment of `^` and `!` is triggered by a
  REM # `!` present after the early expansion, and is counteracted by the
  REM # escaping above.
  REM #
  SET OPT_DEFS=%%X!!
)

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 8N6O4: OPT_DEFS: `!OPT_DEFS!`

REM # Add a leading space and an ending space to the option definitions.
REM #
REM # This ensures each option key is preceded by a space, including the first
REM # one. This ensures each option default value is followed by a space,
REM # including the last one. The two facts ensured make some checks done below
REM # apply for the first and last option definitions too, besides option
REM # definitions in the middle.
REM #
SET "OPT_DEFS= !OPT_DEFS! "

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 5N2Y1: OPT_DEFS_SP: `!OPT_DEFS!`

REM # In `OPT_DEFS_SQ`, option keys and option default values are always quoted
REM # by `'`. They are appended at 1B4W3.
REM # Used to check the presence of an option key at 2M5K7.
REM #
REM # `SQ` means single quote.
REM #
SET "OPT_DEFS_SQ= "

REM # Convert `'` to `"` in `OPT_DEFS` so that when the `FOR` loop below does
REM # field splitting, quoted spaces in option default values are treated
REM # literally instead of as field delimiters.
REM #
REM # Enclosing `"` will cause quote mismatch for the variable expansion so is
REM # not used.
REM #
REM # `DQ` means double quote.
REM #
SET OPT_DEFS_DQ=!OPT_DEFS:'="!

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 3O1J7: OPT_DEFS_DQ: `!OPT_DEFS_DQ!`

REM # Code below aims to parse the option definitions.
REM //ECHO 1>&2%LOG_PREFIX%INFO: 1F8J7: opt_defs_parse

REM # ----- 3S7Y1 -----
REM # Parse the option definitions to set the default value for each option key.
REM #
REM # The `FOR` loop's field splitting by default uses unquoted spaces as
REM # delimiters. That is why `OPT_DEFS_DQ`, the double quote version of
REM # `OPT_DEFS` is used to preserve quoted spaces in default option values.
REM #
REM # `%%O`: Each option definition.
REM # The `FOR` loop will not make a field empty so `%%O` must be nonempty.
REM #
FOR %%O IN (!OPT_DEFS_DQ!) DO (
  REM # Code below aims to store the option definition in `%%O` to variable
  REM # `OPT_DEF` to preserve `^` and `!` in it.
  REM //ECHO 1>&2%LOG_PREFIX%INFO: 6V4O7: opt_def_to_var

  REM # Clear the old value.
  SET "OPT_DEF="

  REM # Disable delayed expansion so that `^` and `!` are not treated specially
  REM # by delayed expansion. `^` may still be treated specially by early
  REM # expansion but can be preserved by enclosing `"`.
  SETLOCAL DisableDelayedExpansion

  REM # Echo after delayed expansion is disabled, otherwise `^` and `!` will be
  REM # treated specially by delayed expansion if a `!` is present.
  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 2Q9C7: for_var: OPT_DEF: %%O

  REM # Store the option definition to variable `VAL`, which will be accessed in
  REM # the subroutines below.
  REM #
  REM # Early expansion's special treatment of `^` not happens to a `FOR` loop
  REM # variable so enclosing `"` is not needed.
  REM #
  REM # Delayed expansion's special treatment of `^` and `!` not happens here
  REM # because delayed expansion is disabled above.
  REM #
  SET VAL=%%O

  REM # Convert `"` to `'` so that the subroutines below can use enclosing `"`.
  CALL :val_dq_to_sq

  REM # Escape `^` and `!` to counteract the delayed expansion on the `FOR` loop
  REM # variable below.
  CALL :val_escape_caret
  CALL :val_escape_exclamation

  REM # Enable delayed expansion to get the latest value after the escaping.
  SETLOCAL EnableDelayedExpansion

  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 3C4F7: OPT_DEF_ESC: `!VAL!`

  REM # Use the `FOR` loop variable trick to pass the value to the outer
  REM # context.
  REM #
  REM # The enclosing `"` will not cause quote mismatch as the option definition
  REM # contains no `"`.
  REM #
  FOR /f delims^=^ eol^= %%X IN ("!VAL!") DO (
    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 9E7G1: for_var: OPT_DEF: `%%X!!` [after delayed expansion]

    REM # End the two local contexts entered above.
    ENDLOCAL
    ENDLOCAL

    REM # Set the variable of the outer context.
    REM #
    REM # Early expansion's special treatment of `^` not happens to a `FOR` loop
    REM # variable so enclosing `"` is not needed.
    REM #
    REM # Delayed expansion's special treatment of `^` and `!` is triggered by a
    REM # `!` present after the early expansion, and is counteracted by the
    REM # escaping above.
    REM #
    SET OPT_DEF=%%X!!
  )

  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 7U3L2: OPT_DEF: `!OPT_DEF!`

  REM # Code below aims to validate the option definition.
  REM //ECHO 1>&2%LOG_PREFIX%INFO: 1D6X2: opt_def_validate

  REM # ----- 2P4G5 -----
  REM # If the first character of the option definition is `:`.
  REM #
  REM # This handles the case `SET "OPT_DEFS=:_OPT_DFT_"`.
  REM #
  IF "!OPT_DEF:~0,1!" == ":" (
    ECHO 1>&2%LOG_PREFIX%ERROR: 6U8V7: option_key_empty: option_def="!OPT_DEF:"='!"
    GOTO :exit_code_1
  )

  REM # ----- 3E8K6 -----
  REM # If the first two characters of the option definition is `''`.
  REM #
  REM # This handles the case `SET "OPT_DEFS='':_OPT_DFT_"`.
  REM #
  IF "!OPT_DEF:~0,2!" == "''" (
    ECHO 1>&2%LOG_PREFIX%ERROR: 8Z5Y9: option_key_empty: option_def="!OPT_DEF:"='!"
    GOTO :exit_code_1
  )

  REM # Code below aims to parse the option definition.
  REM //ECHO 1>&2%LOG_PREFIX%INFO: 6B4W3: opt_def_parse

  REM # Parse the option definition into option key and option default value.
  REM #
  REM # `delims=:`: Split the option definition pair `_OPT_KEY_:_OPT_DFT_` into
  REM # fields by delimiter `:`.
  REM #
  REM # `tokens=1,*`: Assign the first field `_OPT_KEY_` to `%%A`, assign the
  REM # rest `_OPT_DFT_` to `%%B`.
  REM #
  REM # `%%A`: option key `_OPT_KEY_`.
  REM #
  REM # `%%B`: option default value `_OPT_DFT_`.
  REM #
  REM # The enclosing `"` will not cause quote mismatch as the option definition
  REM # contains no `"`.
  REM #
  FOR /f "delims=: eol= tokens=1,*" %%A IN ("!OPT_DEF!") DO (
    REM # Can not do `SET "%%~A=%%~B"` directly because `^` and `!` will be
    REM # treated specially by delayed expansion if a `!` is present.

    REM # Code below aims to store the option key in `%%A` to variable `OPT_KEY`
    REM # to preserve `^` and `!` in it.
    REM //ECHO 1>&2%LOG_PREFIX%INFO: 3Y6Z4: opt_key_to_var

    REM # Clear the old value.
    SET "OPT_KEY="

    REM # Disable delayed expansion so that `^` and `!` are not treated
    REM # specially by delayed expansion. `^` may still be treated specially by
    REM # early expansion but can be preserved by enclosing `"`.
    SETLOCAL DisableDelayedExpansion

    REM # Echo after delayed expansion is disabled, otherwise `^` and `!` will
    REM # be treated specially by delayed expansion if a `!` is present.
    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 5A8P3: for_var: OPT_KEY: `%%A`

    REM # Store the option key to variable `VAL`, which will be accessed in the
    REM # subroutines below.
    REM #
    REM # Early expansion's special treatment of `^` not happens to a `FOR` loop
    REM # variable so enclosing `"` is not needed.
    REM #
    REM # Delayed expansion's special treatment of `^` and `!` not happens here
    REM # because delayed expansion is disabled above.
    REM #
    SET VAL=%%A

    REM # Escape `^` and `!` to counteract the delayed expansion on the `FOR`
    REM # loop variable below.
    CALL :val_escape_caret
    CALL :val_escape_exclamation

    REM # Enable delayed expansion to get the latest value after the escaping.
    SETLOCAL EnableDelayedExpansion

    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 1U8O4: OPT_KEY_ESC: `!VAL!`

    REM # Use the `FOR` loop variable trick to pass the value to the outer
    REM # context.
    REM #
    REM # The enclosing `"` will not cause quote mismatch as the option key
    REM # contains no `"`.
    REM #
    FOR /f delims^=^ eol^= %%X IN ("!VAL!") DO (
      REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 2X9V5: for_var: OPT_KEY: `%%X!!` [after delayed expansion]

      REM # End the two local contexts entered above.
      ENDLOCAL
      ENDLOCAL

      REM # Set the variable of the outer context.
      REM #
      REM # Early expansion's special treatment of `^` not happens to a `FOR`
      REM # loop variable so enclosing `"` is not needed.
      REM #
      REM # Delayed expansion's special treatment of `^` and `!` is triggered by
      REM # a `!` present after the early expansion, and is counteracted by the
      REM # escaping above.
      REM #
      SET OPT_KEY=%%X!!
    )

    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 9M3V7: OPT_KEY: `!OPT_KEY!`

    REM # Should not happen. Ensured at 2P4G5.
    IF "!OPT_KEY!" == "" (
      ECHO 1>&2%LOG_PREFIX%ERROR: 9L7X3: option_key_empty: option_def="!OPT_DEF:"='!"
      GOTO :exit_code_1
    )

    REM # Should not happen. Ensured at 3E8K6.
    IF "!OPT_KEY!" == "''" (
      ECHO 1>&2%LOG_PREFIX%ERROR: 1T8F6: option_key_empty: option_def="!OPT_DEF:"='!"
      GOTO :exit_code_1
    )

    REM # Code below aims to store the option default value in `%%B` to variable
    REM # `OPT_DFT` to preserve `^` and `!` in it.
    REM //ECHO 1>&2%LOG_PREFIX%INFO: 5N2D3: opt_dft_to_var

    REM # Clear the old value.
    REM #
    REM # If `%%B` is empty, the `FOR` loop below will not run so `OPT_DFT`
    REM # may contain the old value if not cleared here.
    REM #
    SET "OPT_DFT="

    REM # Disable delayed expansion so that `^` and `!` are not treated
    REM # specially by delayed expansion. `^` may still be treated specially by
    REM # early expansion but can be preserved by enclosing `"`.
    SETLOCAL DisableDelayedExpansion

    REM # Echo after delayed expansion is disabled, otherwise `^` and `!` will
    REM # be treated specially by delayed expansion if a `!` is present.
    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 6V4C1: for_var: OPT_DFT: `%%B`

    REM # Store the option default value to variable `VAL`, which will be
    REM # accessed in the subroutines below.
    REM #
    REM # Early expansion's special treatment of `^` not happens to a `FOR` loop
    REM # variable so enclosing `"` is not needed.
    REM #
    REM # Delayed expansion's special treatment of `^` and `!` not happens here
    REM # because delayed expansion is disabled above.
    REM #
    SET VAL=%%B

    REM # Escape `^` and `!` to counteract the delayed expansion on the `FOR`
    REM # loop variable below.
    CALL :val_escape_caret
    CALL :val_escape_exclamation

    REM # Enable delayed expansion to get the latest value after the escaping.
    SETLOCAL EnableDelayedExpansion

    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 8A9T4: OPT_DFT_ESC: `!VAL!`

    REM # Use the `FOR` loop variable trick to pass the value to the outer
    REM # context.
    REM #
    REM # The enclosing `"` will not cause quote mismatch as the option default
    REM # value contains no `"`.
    REM #
    FOR /f delims^=^ eol^= %%X IN ("!VAL!") DO (
      REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 1S2P6: for_var: OPT_DFT: `%%X!!` [after delayed expansion]

      REM # End the two local contexts entered above.
      ENDLOCAL
      ENDLOCAL

      REM # Set the variable of the outer context.
      REM #
      REM # Early expansion's special treatment of `^` not happens to a `FOR`
      REM # loop variable so enclosing `"` is not needed.
      REM #
      REM # Delayed expansion's special treatment of `^` and `!` is triggered by
      REM # a `!` present after the early expansion, and is counteracted by the
      REM # escaping above.
      REM #
      SET OPT_DFT=%%X!!
    )

    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 2I5X3: OPT_DFT: `!OPT_DFT!`

    REM # If the option default value is empty, not even a `''`, then the option
    REM # is a flag option.
    IF "!OPT_DFT!" == "" (
      SET OPT_IS_FLAG=1
    ) ELSE (
      SET OPT_IS_FLAG=0
    )

    REM # If the first character of the option key is `'`, strip off the
    REM # enclosing `'`.
    IF NOT "!OPT_KEY!" == "" IF "!OPT_KEY:~0,1!" == "'" (
      SET "OPT_KEY=!OPT_KEY:~1,-1!"
    )

    REM # If the first character of the option default value is `'`, strip off
    REM # the enclosing `'`.
    IF NOT "!OPT_DFT!" == "" IF "!OPT_DFT:~0,1!" == "'" (
      SET "OPT_DFT=!OPT_DFT:~1,-1!"
    )

    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 8Y9G4: OPT_KEY_NQ: `!OPT_KEY!`

    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 9A6D2: OPT_DFT_NQ: `!OPT_DFT!`

    REM # ----- 2W5X9 -----
    REM # Set the default value of the option key.
    REM #
    REM # The enclosing `"` will not cause quote mismatch as the option key and
    REM # option default value contain no `"`.
    REM #
    SET "!OPT_KEY!=!OPT_DFT!"

    REM # If the `SET` command failed.
    REM #
    REM # This handles the case `SET "OPT_DEFS=' ':_OPT_DFT_"`.
    REM #
    IF ERRORLEVEL 1 (
      ECHO 1>&2%LOG_PREFIX%ERROR: 6S9T7: option_def_invalid: option_def="!OPT_DEF:"='!"
      GOTO :exit_code_1
    )

    REM # ----- 1B4W3 -----
    REM # Add the option key and option default value to `OPT_DEFS_SQ`.
    REM #
    REM # Option keys and option default values are always quoted by `'` in
    REM # `OPT_DEFS_SQ`.
    REM #
    REM # The enclosing `"` will not cause quote mismatch as the option key and
    REM # option default value contain no `"`.
    REM #
    IF "!OPT_IS_FLAG!" == "1" (
      SET "OPT_DEFS_SQ=!OPT_DEFS_SQ!'!OPT_KEY!': "
    ) ELSE (
      SET "OPT_DEFS_SQ=!OPT_DEFS_SQ!'!OPT_KEY!':'!OPT_DFT!' "
    )

    REM # If the `SET` command failed.
    IF ERRORLEVEL 1 (
      ECHO 1>&2%LOG_PREFIX%ERROR: 2Q9V6: option_def_invalid: option_def="!OPT_DEF:"='!"
      GOTO :exit_code_1
    )
  )
)

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 8F1G3: OPT_DEFS_SQ: "!OPT_DEFS_SQ!"

REM # Double `^` in `OPT_DEFS_SQ`.
REM # Used to check the presence of an option key at 2M5K7.
REM #
REM # `SQ` means single quote.
REM # `DC` means double caret.
REM #
SET "OPT_DEFS_SQ_DC=!OPT_DEFS_SQ:^=^^!"

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 9A5H2: OPT_DEFS_SQ_DC: "!OPT_DEFS_SQ_DC!"

REM # Code below aims to parse the command line arguments into options.
REM //ECHO 1>&2%LOG_PREFIX%INFO: 2F7K5: opts_parse

:opts_parse_loop
REM # If the option key in `%~1` is not empty.
REM #
REM # Code below assumes `%~1` and `%~2` contain no `"`.
REM # Otherwise it will cause quote mismatch.
REM #
IF NOT "%~1" == "" (
  REM //ECHO 1>&2%LOG_PREFIX%INFO: 5J9O2: opt_parse

  REM # Code below aims to store the option key in `%~1` to variable `OPT_KEY`
  REM # to preserve `^` and `!` in it.
  REM //ECHO 1>&2%LOG_PREFIX%INFO: 6Z7V2: opt_key_to_var

  REM # Clear the old value.
  SET "OPT_KEY="

  REM # Disable delayed expansion so that `^` and `!` are not treated specially
  REM # by delayed expansion. `^` may still be treated specially by early
  REM # expansion but can be preserved by enclosing `"`.
  SETLOCAL DisableDelayedExpansion

  REM # Echo after delayed expansion is disabled, otherwise `^` and `!` will be
  REM # treated specially by delayed expansion if a `!` is present.
  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 7O2R8: ARG_1: "%~1"

  REM # Store the option key to variable `VAL`, which will be accessed in the
  REM # subroutines below.
  REM #
  REM # The enclosing `"` will not cause quote mismatch only if `%~1` contains
  REM # no `"`.
  REM #
  SET "VAL=%~1"

  REM # Escape `^` and `!` to counteract the delayed expansion on the `FOR` loop
  REM # variable below.
  CALL :val_escape_caret
  CALL :val_escape_exclamation

  REM # Enable delayed expansion to get the latest value after the escaping.
  SETLOCAL EnableDelayedExpansion

  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 6S2L3: OPT_KEY_ESC: `!VAL!`

  REM # Use the `FOR` loop variable trick to pass the value to the outer context.
  REM #
  REM # The enclosing `"` will not cause quote mismatch only if `%~1` contains
  REM # no `"`.
  REM #
  FOR /f delims^=^ eol^= %%X IN ("!VAL!") DO (
    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 4I1Q9: for_var: OPT_KEY: `%%X!!` [after delayed expansion]

    REM # End the two local contexts entered above.
    ENDLOCAL
    ENDLOCAL

    REM # Set the variable of the outer context.
    REM #
    REM # Early expansion's special treatment of `^` not happens to a `FOR` loop
    REM # variable so enclosing `"` is not needed.
    REM #
    REM # Delayed expansion's special treatment of `^` and `!` is triggered by a
    REM # `!` present after the early expansion, and is counteracted by the
    REM # escaping above.
    REM #
    SET OPT_KEY=%%X!!
  )

  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 3W7B4: OPT_KEY: "!OPT_KEY!"

  REM # ----- 2M5K7 -----
  REM # Remove the option key, the option definitions before it, and the colon
  REM # after it from `OPT_DEFS_SQ_DC`.
  REM #
  REM # E.g. `OPT_DEFS_SQ_DC` is ` '-a':'1' '-b':'2' '-c':'3' `, `OPT_KEY` is
  REM # `-b`, then `OPT_DEFS_REM` is `'2' '-c':'3' `.
  REM #
  REM # The meaning of `%%OPT_DEFS_SQ_DC:* '!OPT_KEY!':=%%`:
  REM # `%%` on both sides: Escape for `%`.
  REM # `:` before `* '!OPT_KEY!':`: Delimiter for variable content replacement.
  REM # `=` after `* '!OPT_KEY!':`: Delimiter for variable content replacement.
  REM # `*` of `* '!OPT_KEY!':`: Wildcard to match option definitions before the
  REM # option key.
  REM # ` ` of `* '!OPT_KEY!':`: The space before the option key in the option
  REM # definition. This aims to prevent e.g. the option key `-key` supplied
  REM # from matching `--key` defined.
  REM # `!OPT_KEY!` of `* '!OPT_KEY!':`: The option key in the option
  REM # definition.
  REM # `:` of `* '!OPT_KEY!':`: The colon between the option key and the option
  REM # default value in the option definition.
  REM #
  REM # `CALL` will double `^` in `OPT_KEY`. That is why `OPT_DEFS_SQ_DC`,
  REM # the double caret version of `OPT_DEFS_SQ`, is used.
  REM # `CALL` will  not double `^` in `OPT_DEFS_SQ_DC` because `%%` escapes
  REM # thus `OPT_DEFS_SQ_DC` is not a variable as far as `CALL` concerns.
  REM #
  REM # The code run by `CALL` will do early expansion but not delayed
  REM # expansion even if the calling context has enabled delayed expansion.
  REM # The enclosing `"` keeps `^` from being treated specially by the early
  REM # expansion.
  REM #
  REM # Can not set `OPT_DEFS_REM` directly like
  REM # `SET "OPT_DEFS_REM=!OPT_DEFS_SQ:* '%~1':=!"`
  REM # because `^` and `!` in `%~1` will be treated specially by delayed
  REM # expansion if a `!` is present.
  REM.#
  REM # The enclosing `"` will not cause quote mismatch only if `%~1` contains
  REM # no `"`.
  REM.#
  CALL SET "OPT_DEFS_REM=%%OPT_DEFS_SQ_DC:* '!OPT_KEY!':=%%"

  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 8C6T3: OPT_DEFS_REM: "!OPT_DEFS_REM!"

  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 1U3T7: OPT_DEFS_SQ_DC: "!OPT_DEFS_SQ_DC!"

  REM # If removed nothing from `OPT_DEFS_SQ_DC`, the option key is not defined.
  IF "!OPT_DEFS_REM!" == "!OPT_DEFS_SQ_DC!" (
    ECHO 1>&2%LOG_PREFIX%ERROR: 1A7U8: option_key_undefined: "!OPT_KEY!"
    GOTO :exit_code_1
  )

  IF "!OPT_DEFS_REM:~0,1!" == " " (
    REM # If the first character of the option default value is a space, the
    REM # option key is a flag option.

    REM # Set the actual value of the option key.
    SET "!OPT_KEY!=1"

    REM # Shift off the option key.
    SHIFT /1
  ) ELSE (
    REM # If the first character of the option default value is not a space, the
    REM # option key is a normal option.

    REM # Code below aims to store the option value in `%~2` to variable
    REM # `OPT_VAL` to preserve `^` and `!` in it.
    REM //ECHO 1>&2%LOG_PREFIX%INFO: 7D4Q9: opt_val_to_var

    REM # Clear the old value.
    SET "OPT_VAL="

    REM # Disable delayed expansion so that `^` and `!` are not treated
    REM # specially by delayed expansion. `^` may still be treated specially
    REM # by early expansion but can be preserved by enclosing `"`.
    SETLOCAL DisableDelayedExpansion

    REM # Echo after delayed expansion is disabled, otherwise `^` and `!` will
    REM # be treated specially by delayed expansion if a `!` is present.
    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 3F5N1: ARG_2: "%~2"

    REM # Store the option value to variable `VAL`, which will be accessed in
    REM # the subroutines below.
    REM #
    REM # The enclosing `"` will not cause quote mismatch only if `%~2`
    REM # contains no `"`.
    REM #
    SET "VAL=%~2"

    REM # Escape `^` and `!` to counteract the delayed expansion on the `FOR`
    REM # loop variable below.
    CALL :val_escape_caret
    CALL :val_escape_exclamation

    REM # Enable delayed expansion to get the latest value after the escaping.
    SETLOCAL EnableDelayedExpansion

    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 2T7A3: OPT_VAL_ESC: `!VAL!`

    IF "!VAL!" == "" (
      REM # End the two local contexts entered above.
      ENDLOCAL
      ENDLOCAL

      REM # Set the variable of the outer context.
      SET "OPT_VAL="
    ) ELSE (
      REM # Use the `FOR` loop variable trick to pass the value to the outer
      REM # context.
      REM #
      REM # The enclosing `"` will not cause quote mismatch only if `%~2`
      REM # contains no `"`.
      REM #
      FOR /f delims^=^ eol^= %%X IN ("!VAL!") DO (
        REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 1X7J6: for_var: OPT_VAL: `%%X!!` [after delayed expansion]

        REM # End the two local contexts entered above.
        ENDLOCAL
        ENDLOCAL

        REM # Set the variable of the outer context.
        REM #
        REM # Early expansion's special treatment of `^` not happens to a `FOR`
        REM # loop variable so enclosing `"` is not needed.
        REM #
        REM # Delayed expansion's special treatment of `^` and `!` is triggered
        REM # by a `!` present after the early expansion, which is counteracted
        REM # by the escaping above.
        REM #
        SET OPT_VAL=%%X!!
      )
    )

    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 8X6A5: OPT_KEY: `!OPT_KEY!`

    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 9E2T7: OPT_VAL: `!OPT_VAL!`

    REM # Set the actual value of the option key.
    REM #
    REM # The enclosing `"` will not cause quote mismatch only if `%~1` and
    REM # `%~2` contain no `"`.
    REM #
    SET "!OPT_KEY!=!OPT_VAL!"

    REM # If the `SET` command failed.
    IF ERRORLEVEL 1 (
      ECHO 1>&2%LOG_PREFIX%ERROR: 8W5J9: option_invalid: `!OPT_KEY! !OPT_VAL!`
      GOTO :exit_code_1
    )

    REM # Shift off the option key and option value.
    SHIFT /1
    SHIFT /1
  )

  SET "OPT_KEY="

  SET "OPT_VAL="

  GOTO :opts_parse_loop
) ELSE (
  REM # If the option key in `%~1` is empty.

  REM # If the next argument in `%~2` is not empty.
  IF NOT "%~2" == "" (
    ECHO 1>&2%LOG_PREFIX%ERROR: 5R8O3: option_key_empty
    GOTO :exit_code_1
  )
)
GOTO :opts_parse_end

:exit_code_0
REM # Exit with code 0.
REM #
REM # `EXIT /B 0` inside parentheses not sets the exit code properly.
REM # Use `GOTO :exit_code_0` instead.
REM #
EXIT /B 0

:exit_code_1
REM # Exit with code 1.
REM #
REM # `EXIT /B 1` inside parentheses not sets the exit code properly.
REM # Use `GOTO :exit_code_1` instead.
REM #
EXIT /B 1

:val_dq_to_sq
REM # Replace `"` with `'` in variable `VAR`.

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 3D6B8: val_dq_to_sq: before: `%VAL%`

REM # If `VAR` is not empty.
REM #
REM # An empty variable can not do content replacement.
REM #
REM # Enclosing `"` will cause quote mismatch for the variable expansion so is
REM # not used. As a result, unquoted `^` in `VAL` will be treated specially
REM # during the expansion. The caller should ensure `^` has enclosing `"`.
REM #
IF NOT [%VAL%] == [] (
  REM # The enclosing `"` will not cause quote mismatch because all inner `"`
  REM # have just been replaced with `'`.
  SET "VAL=%VAL:"='%"
)

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 6N7C9: val_dq_to_sq: after: "%VAL%"

EXIT /B 0

:val_escape_caret
REM # Escape `^` with `^^` in variable `VAR`.
REM #
REM # `VAR` is required to contain no `"`.

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 4R7Z5: val_escape_caret: before: "%VAL%"

REM # If `VAR` is not empty.
REM #
REM # An empty variable can not do content replacement.
REM #
IF NOT "%VAL%" == "" (
  SET "VAL=%VAL:^=^^%"
)

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 5T2F9: val_escape_caret: after: "%VAL%"

EXIT /B 0

:val_escape_exclamation
REM # Escape `!` with `^!` in variable `VAR`.
REM #
REM # `VAR` is required to contain no `"`.

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 6J3G7: val_escape_exclamation: before: "%VAL%"

REM # If `VAR` is not empty.
REM #
REM # An empty variable can not do content replacement.
REM #
IF NOT "%VAL%" == "" (
  SET "VAL=%VAL:!=^!%"
)

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 7Y8N2: val_escape_exclamation: after: "%VAL%"

EXIT /B 0

:opts_parse_end

SET "OPT_DEFS="
SET "OPT_DEFS_SQ="
SET "OPT_DEFS_SQ_DC="
SET "OPT_DEFS_DQ="
SET "OPT_DEFS_REM="
SET "OPT_DEF="
SET "OPT_KEY="
SET "OPT_DFT="
SET "OPT_IS_FLAG="
SET "VAL="
REM # ========== AoikBatchCmdLineArgsParser [EnableDelayedExpansion] ==========

REM //ECHO 1>&2%LOG_PREFIX%INFO: 3W1U7: opts_show
SET -
