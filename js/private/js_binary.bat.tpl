@echo off
setlocal enabledelayedexpansion

rem This batch script is a wrapper around the NodeJS JavaScript file
rem entry point with the following bazel label:
rem     {{entry_point_label}}
rem
rem The script's was generated to execute the js_binary target
rem     {{target_label}}
rem
rem The template used to generate this script is
rem     {{template_label}}

{{envs}}

rem ==============================================================================
rem Prepare stdout capture, stderr capture && logging
rem ==============================================================================

if defined JS_BINARY__STDOUT_OUTPUT_FILE (
    set "STDOUT_CAPTURE=%TEMP%\stdout_%RANDOM%_%TIME:~-2%.tmp"
) else if defined JS_BINARY__SILENT_ON_SUCCESS (
    set "STDOUT_CAPTURE=%TEMP%\stdout_%RANDOM%_%TIME:~-2%.tmp"
)

if defined JS_BINARY__STDERR_OUTPUT_FILE (
    set "STDERR_CAPTURE=%TEMP%\stderr_%RANDOM%_%TIME:~-2%.tmp"
) else if defined JS_BINARY__SILENT_ON_SUCCESS (
    set "STDERR_CAPTURE=%TEMP%\stderr_%RANDOM%_%TIME:~-2%.tmp"
)

set "JS_BINARY__LOG_PREFIX={{log_prefix_rule_set}}[{{log_prefix_rule}}]"

goto :main

:logf_stderr
set "format_string=%~1"
shift
if defined STDERR_CAPTURE (
    echo !format_string! >> "!STDERR_CAPTURE!"
) else (
    echo !format_string! >&2
)
exit /b 0

:logf_fatal
if defined JS_BINARY__LOG_FATAL (
    if defined STDERR_CAPTURE (
        echo FATAL: %JS_BINARY__LOG_PREFIX%: >> "!STDERR_CAPTURE!"
    ) else (
        echo FATAL: %JS_BINARY__LOG_PREFIX%: >&2
    )
    call :logf_stderr %*
)
exit /b 0

:logf_error
if defined JS_BINARY__LOG_ERROR (
    if defined STDERR_CAPTURE (
        echo ERROR: %JS_BINARY__LOG_PREFIX%: >> "!STDERR_CAPTURE!"
    ) else (
        echo ERROR: %JS_BINARY__LOG_PREFIX%: >&2
    )
    call :logf_stderr %*
)
exit /b 0

:logf_warn
if defined JS_BINARY__LOG_WARN (
    if defined STDERR_CAPTURE (
        echo WARN: %JS_BINARY__LOG_PREFIX%: >> "!STDERR_CAPTURE!"
    ) else (
        echo WARN: %JS_BINARY__LOG_PREFIX%: >&2
    )
    call :logf_stderr %*
)
exit /b 0

:logf_info
if defined JS_BINARY__LOG_INFO (
    if defined STDERR_CAPTURE (
        echo INFO: %JS_BINARY__LOG_PREFIX%: >> "!STDERR_CAPTURE!"
    ) else (
        echo INFO: %JS_BINARY__LOG_PREFIX%: >&2
    )
    call :logf_stderr %*
)
exit /b 0

:logf_debug
if defined JS_BINARY__LOG_DEBUG (
    if defined STDERR_CAPTURE (
        echo DEBUG: %JS_BINARY__LOG_PREFIX%: >> "!STDERR_CAPTURE!"
    ) else (
        echo DEBUG: %JS_BINARY__LOG_PREFIX%: >&2
    )
    call :logf_stderr %*
)
exit /b 0

:resolve_execroot_bin_path
set "short_path=%~1"
if "!short_path:~0,3!"=="..\\" (
    set "RESULT=%JS_BINARY__EXECROOT%\%BAZEL_BINDIR%\external\!short_path:~3!"
) else (
    set "RESULT=%JS_BINARY__EXECROOT%\%BAZEL_BINDIR%\!short_path!"
)
if not defined BAZEL_BINDIR (
    set "RESULT=%JS_BINARY__EXECROOT%\%JS_BINARY__BINDIR%\!short_path!"
    if "!short_path:~0,3!"=="..\\" (
        set "RESULT=%JS_BINARY__EXECROOT%\%JS_BINARY__BINDIR%\external\!short_path:~3!"
    )
)
exit /b 0

:resolve_execroot_src_path
set "short_path=%~1"
if "!short_path:~0,3!"=="..\\" (
    set "RESULT=%JS_BINARY__EXECROOT%\external\!short_path:~3!"
) else (
    set "RESULT=%JS_BINARY__EXECROOT%\!short_path!"
)
exit /b 0

:cleanup_and_exit
if defined STDERR_CAPTURE (
    if defined JS_BINARY__STDERR_OUTPUT_FILE (
        copy "!STDERR_CAPTURE!" "%JS_BINARY__STDERR_OUTPUT_FILE%" >nul
    )
    if %ERRORLEVEL% neq 0 (
        type "!STDERR_CAPTURE!" >&2
    ) else if not defined JS_BINARY__SILENT_ON_SUCCESS (
        type "!STDERR_CAPTURE!" >&2
    )
    del "!STDERR_CAPTURE!" >nul 2>&1
)

if defined STDOUT_CAPTURE (
    if defined JS_BINARY__STDOUT_OUTPUT_FILE (
        copy "!STDOUT_CAPTURE!" "%JS_BINARY__STDOUT_OUTPUT_FILE%" >nul
    )
    if %ERRORLEVEL% neq 0 (
        type "!STDOUT_CAPTURE!"
    ) else if not defined JS_BINARY__SILENT_ON_SUCCESS (
        type "!STDOUT_CAPTURE!"
    )
    del "!STDOUT_CAPTURE!" >nul 2>&1
)

if defined JS_BINARY__LOG_DEBUG (
    call :logf_debug "exit code: %ERRORLEVEL%"
)

if defined JS_BINARY__PUSHD (
    popd
)

exit /b %ERRORLEVEL%

:main

rem ==============================================================================
rem Initialize RUNFILES environment variable
rem ==============================================================================
{{initialize_runfiles}}
set "JS_BINARY__RUNFILES=%RUNFILES%"

rem ==============================================================================
rem Prepare to run main program
rem ==============================================================================

rem Convert stdout, stderr and exit_code capture outputs paths to absolute paths
if defined JS_BINARY__STDOUT_OUTPUT_FILE (
    set "temp_path=%JS_BINARY__STDOUT_OUTPUT_FILE%"
    if not "!temp_path:~1,1!"==":" (
        set "JS_BINARY__STDOUT_OUTPUT_FILE=%CD%\%JS_BINARY__STDOUT_OUTPUT_FILE%"
    )
)
if defined JS_BINARY__STDERR_OUTPUT_FILE (
    set "temp_path=%JS_BINARY__STDERR_OUTPUT_FILE%"
    if not "!temp_path:~1,1!"==":" (
        set "JS_BINARY__STDERR_OUTPUT_FILE=%CD%\%JS_BINARY__STDERR_OUTPUT_FILE%"
    )
)
if defined JS_BINARY__EXIT_CODE_OUTPUT_FILE (
    set "temp_path=%JS_BINARY__EXIT_CODE_OUTPUT_FILE%"
    if not "!temp_path:~1,1!"==":" (
        set "JS_BINARY__EXIT_CODE_OUTPUT_FILE=%CD%\%JS_BINARY__EXIT_CODE_OUTPUT_FILE%"
    )
)

rem Detect bazel-out segment in current directory
set "bazel_out_segment="
echo "%CD%" | findstr /c:"\bazel-out\" >nul && set "bazel_out_segment=\bazel-out\"
if not defined bazel_out_segment (
    echo "%CD%" | findstr /c:"\BAZEL-~1\" >nul && set "bazel_out_segment=\BAZEL-~1\"
)
if not defined bazel_out_segment (
    echo "%CD%" | findstr /c:"\bazel-~1\" >nul && set "bazel_out_segment=\bazel-~1\"
)

if defined bazel_out_segment (
    if defined JS_BINARY__USE_EXECROOT_ENTRY_POINT (
        if defined JS_BINARY__EXECROOT (
            call :logf_debug "inheriting JS_BINARY__EXECROOT %JS_BINARY__EXECROOT% from parent js_binary process as JS_BINARY__USE_EXECROOT_ENTRY_POINT is set"
        )
    ) else (
        rem We in runfiles and we don't yet know the execroot
        rem Find the position of bazel_out_segment and extract execroot
        for /f "tokens=1 delims=" %%i in ('echo "%CD%" ^| findstr /n /c:"!bazel_out_segment!"') do (
            set "temp_line=%%i"
        )
        rem Extract everything before bazel-out segment
        call :extract_execroot_from_path "%CD%" "!bazel_out_segment!"
    )
) else (
    if defined JS_BINARY__USE_EXECROOT_ENTRY_POINT (
        if defined JS_BINARY__EXECROOT (
            call :logf_debug "inheriting JS_BINARY__EXECROOT %JS_BINARY__EXECROOT% from parent js_binary process as JS_BINARY__USE_EXECROOT_ENTRY_POINT is set"
        )
    ) else (
        rem We are in execroot or in some other context all together such as a nodejs_image or a manually run js_binary
        set "JS_BINARY__EXECROOT=%~dp0"
    )

    if not defined JS_BINARY__NO_CD_BINDIR (
        if not defined BAZEL_BINDIR (
            call :logf_fatal "BAZEL_BINDIR must be set in environment to the makevar $(BINDIR) in js_binary build actions (which run in the execroot) so that build actions can change directories to always run out of the root of the Bazel output tree. See https://docs.bazel.build/versions/main/be/make-variables.html#predefined_variables. This is automatically set by 'js_run_binary' (https://github.com/aspect-build/rules_js/blob/main/docs/js_run_binary.md) which is the recommended rule to use for using a js_binary as the tool of a build action. If this is not a build action you can set the BAZEL_BINDIR to '.' instead to suppress this error. For more context on this design decision, please read the aspect_rules_js README https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs."
            goto :cleanup_and_exit
        )

        rem Since the process was launched in the execroot, we automatically change directory into the root of the
        rem output tree (which we expect to be set in BAZEL_BIN). See
        rem https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs
        rem for more context on why we do this.
        call :logf_debug "changing directory to BAZEL_BINDIR (root of Bazel output tree) %BAZEL_BINDIR%"
        set JS_BINARY__PUSHD=1
        pushd "%BAZEL_BINDIR%"
    )
)

if defined JS_BINARY__USE_EXECROOT_ENTRY_POINT (
    if not defined BAZEL_BINDIR (
        call :logf_fatal "Expected BAZEL_BINDIR to be set when JS_BINARY__USE_EXECROOT_ENTRY_POINT is set"
        goto :cleanup_and_exit
    )
    if not defined JS_BINARY__COPY_DATA_TO_BIN (
        if not defined JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN (
            call :logf_fatal "Expected js_binary copy_data_to_bin to be True when js_run_binary use_execroot_entry_point is True. To disable this validation you can set allow_execroot_entry_point_with_no_copy_data_to_bin to True in js_run_binary"
            goto :cleanup_and_exit
        )
    )
)

if defined JS_BINARY__NO_RUNFILES (
    if not defined JS_BINARY__COPY_DATA_TO_BIN (
        if not defined JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN (
            call :logf_fatal "Expected js_binary copy_data_to_bin to be True when js_binary use_execroot_entry_point is True. To disable this validation you can set allow_execroot_entry_point_with_no_copy_data_to_bin to True in js_run_binary"
            goto :cleanup_and_exit
        )
    )
)

if defined JS_BINARY__USE_EXECROOT_ENTRY_POINT (
    call :resolve_execroot_bin_path "{{entry_point_path}}"
    set "entry_point=%RESULT%"
) else if defined JS_BINARY__NO_RUNFILES (
    call :resolve_execroot_bin_path "{{entry_point_path}}"
    set "entry_point=%RESULT%"
) else (
    set "entry_point=%JS_BINARY__RUNFILES%\{{workspace_name}}\{{entry_point_path}}"
)
if not exist "!entry_point!" (
    call :logf_fatal "the entry_point '%entry_point%' not found"
    goto :cleanup_and_exit
)

set "node={{node}}"
rem Check if node path is absolute (starts with drive letter)
echo "%node%" | findstr "^[A-Za-z]:" >nul
if %errorlevel% equ 0 (
    rem A user may specify an absolute path to node using target_tool_path in node_toolchain
    set "JS_BINARY__NODE_BINARY=%node%"
    if not exist "!JS_BINARY__NODE_BINARY!" (
        call :logf_fatal "node binary '%JS_BINARY__NODE_BINARY%' not found"
        goto :cleanup_and_exit
    )
) else (
    if defined JS_BINARY__NO_RUNFILES (
        call :resolve_execroot_src_path "{{node}}"
        set "JS_BINARY__NODE_BINARY=%RESULT%"
    ) else (
        set "JS_BINARY__NODE_BINARY=%JS_BINARY__RUNFILES%\{{workspace_name}}\{{node}}"
    )
    if not exist "!JS_BINARY__NODE_BINARY!" (
        call :logf_fatal "node binary '%JS_BINARY__NODE_BINARY%' not found"
        goto :cleanup_and_exit
    )
)

set "npm={{npm}}"
if defined npm (
    echo "%npm%" | findstr "^[A-Za-z]:" >nul
    if !errorlevel! equ 0 (
        rem A user may specify an absolute path to npm using npm_path in node_toolchain
        set "JS_BINARY__NPM_BINARY=%npm%"
        if not exist "!JS_BINARY__NPM_BINARY!" (
            call :logf_fatal "npm binary '%JS_BINARY__NPM_BINARY%' not found"
            goto :cleanup_and_exit
        )
    ) else (
        if defined JS_BINARY__NO_RUNFILES (
            call :resolve_execroot_src_path "%npm%"
            set "JS_BINARY__NPM_BINARY=%RESULT%"
        ) else (
            set "JS_BINARY__NPM_BINARY=%JS_BINARY__RUNFILES%\{{workspace_name}}\%npm%"
        )
        if not exist "!JS_BINARY__NPM_BINARY!" (
            call :logf_fatal "npm binary '%JS_BINARY__NPM_BINARY%' not found"
            goto :cleanup_and_exit
        )
    )
)

if defined JS_BINARY__NO_RUNFILES (
    call :resolve_execroot_bin_path "{{node_wrapper}}"
    set "JS_BINARY__NODE_WRAPPER=%RESULT%"
) else (
    set "JS_BINARY__NODE_WRAPPER=%JS_BINARY__RUNFILES%\{{workspace_name}}\{{node_wrapper}}"
)
if not exist "%JS_BINARY__NODE_WRAPPER%" (
    call :logf_fatal "node wrapper '%JS_BINARY__NODE_WRAPPER%' not found"
    goto :cleanup_and_exit
)

if defined JS_BINARY__NO_RUNFILES (
    call :resolve_execroot_src_path "{{node_patches}}"
    set "JS_BINARY__NODE_PATCHES=%RESULT%"
) else (
    set "JS_BINARY__NODE_PATCHES=%JS_BINARY__RUNFILES%\{{workspace_name}}\{{node_patches}}"
)
if not exist "%JS_BINARY__NODE_PATCHES%" (
    call :logf_fatal "node patches '%JS_BINARY__NODE_PATCHES%' not found"
    goto :cleanup_and_exit
)

rem Change directory to user specified package if set
if defined JS_BINARY__CHDIR (
    call :logf_debug "changing directory to user specified package %JS_BINARY__CHDIR%"
    cd /d "%JS_BINARY__CHDIR%"
)

rem Gather node options
set "JS_BINARY__NODE_OPTIONS="
{{node_options}}

rem Process command line arguments
set "ARGS="
set "ALL_ARGS={{fixed_args}} %*"
for %%a in (%ALL_ARGS%) do (
    set "ARG=%%a"
    if "!ARG:~0,15!"=="--node_options=" (
        set "JS_BINARY__NODE_OPTIONS=!JS_BINARY__NODE_OPTIONS! !ARG:~15!"
    ) else (
        set "ARGS=!ARGS! %%a"
    )
)

rem Configure JS_BINARY__FS_PATCH_ROOTS for node fs patches which are run via --require in the node wrapper.
rem Don't override JS_BINARY__FS_PATCH_ROOTS if already set by an outer js_binary in case a js_binary such
rem as js_run_devserver runs another js_binary tool.
if not defined JS_BINARY__FS_PATCH_ROOTS (
    set "JS_BINARY__FS_PATCH_ROOTS=%JS_BINARY__EXECROOT%;%JS_BINARY__RUNFILES%"
)

rem Enable coverage if requested
if defined COVERAGE_DIR (
    call :logf_debug "enabling v8 coverage support %COVERAGE_DIR%"
    set "NODE_V8_COVERAGE=%COVERAGE_DIR%"
)

rem Put the node wrapper directory on the path so that child processes find it first
for %%i in ("%JS_BINARY__NODE_WRAPPER%") do set "NODE_WRAPPER_DIR=%%~dpi"
set "PATH=%NODE_WRAPPER_DIR%;%PATH%"

rem Debug logs
if defined JS_BINARY__LOG_DEBUG (
    call :logf_debug "PATH %PATH%"
    if defined BAZEL_BINDIR call :logf_debug "BAZEL_BINDIR %BAZEL_BINDIR%"
    if defined BAZEL_BUILD_FILE_PATH call :logf_debug "BAZEL_BUILD_FILE_PATH %BAZEL_BUILD_FILE_PATH%"
    if defined BAZEL_COMPILATION_MODE call :logf_debug "BAZEL_COMPILATION_MODE %BAZEL_COMPILATION_MODE%"
    if defined BAZEL_INFO_FILE call :logf_debug "BAZEL_INFO_FILE %BAZEL_INFO_FILE%"
    if defined BAZEL_PACKAGE call :logf_debug "BAZEL_PACKAGE %BAZEL_PACKAGE%"
    if defined BAZEL_TARGET_CPU call :logf_debug "BAZEL_TARGET_CPU %BAZEL_TARGET_CPU%"
    if defined BAZEL_TARGET_NAME call :logf_debug "BAZEL_TARGET_NAME %BAZEL_TARGET_NAME%"
    if defined BAZEL_VERSION_FILE call :logf_debug "BAZEL_VERSION_FILE %BAZEL_VERSION_FILE%"
    if defined BAZEL_WORKSPACE call :logf_debug "BAZEL_WORKSPACE %BAZEL_WORKSPACE%"
    call :logf_debug "JS_BINARY__FS_PATCH_ROOTS %JS_BINARY__FS_PATCH_ROOTS%"
    call :logf_debug "JS_BINARY__NODE_PATCHES %JS_BINARY__NODE_PATCHES%"
    call :logf_debug "JS_BINARY__NODE_OPTIONS %JS_BINARY__NODE_OPTIONS%"
    if defined JS_BINARY__BINDIR call :logf_debug "JS_BINARY__BINDIR %JS_BINARY__BINDIR%"
    if defined JS_BINARY__BUILD_FILE_PATH call :logf_debug "JS_BINARY__BUILD_FILE_PATH %JS_BINARY__BUILD_FILE_PATH%"
    if defined JS_BINARY__COMPILATION_MODE call :logf_debug "JS_BINARY__COMPILATION_MODE %JS_BINARY__COMPILATION_MODE%"
    call :logf_debug "JS_BINARY__NODE_BINARY %JS_BINARY__NODE_BINARY%"
    call :logf_debug "JS_BINARY__NODE_WRAPPER %JS_BINARY__NODE_WRAPPER%"
    if defined JS_BINARY__NPM_BINARY call :logf_debug "JS_BINARY__NPM_BINARY %JS_BINARY__NPM_BINARY%"
    if defined JS_BINARY__NO_RUNFILES call :logf_debug "JS_BINARY__NO_RUNFILES %JS_BINARY__NO_RUNFILES%"
    if defined JS_BINARY__PACKAGE call :logf_debug "JS_BINARY__PACKAGE %JS_BINARY__PACKAGE%"
    if defined JS_BINARY__TARGET_CPU call :logf_debug "JS_BINARY__TARGET_CPU %JS_BINARY__TARGET_CPU%"
    if defined JS_BINARY__TARGET_NAME call :logf_debug "JS_BINARY__TARGET_NAME %JS_BINARY__TARGET_NAME%"
    if defined JS_BINARY__WORKSPACE call :logf_debug "JS_BINARY__WORKSPACE %JS_BINARY__WORKSPACE%"
    call :logf_debug "js_binary entry point %entry_point%"
    if defined JS_BINARY__USE_EXECROOT_ENTRY_POINT call :logf_debug "JS_BINARY__USE_EXECROOT_ENTRY_POINT %JS_BINARY__USE_EXECROOT_ENTRY_POINT%"
)

rem Info logs
if defined JS_BINARY__LOG_INFO (
    if defined BAZEL_TARGET call :logf_info "BAZEL_TARGET %BAZEL_TARGET%"
    if defined JS_BINARY__TARGET call :logf_info "JS_BINARY__TARGET %JS_BINARY__TARGET%"
    call :logf_info "JS_BINARY__RUNFILES %JS_BINARY__RUNFILES%"
    call :logf_info "JS_BINARY__EXECROOT %JS_BINARY__EXECROOT%"
    call :logf_info "PWD %CD%"
)

rem ==============================================================================
rem Run the main program
rem ==============================================================================

if defined JS_BINARY__LOG_INFO (
    call :logf_info "running %JS_BINARY__NODE_WRAPPER% %JS_BINARY__NODE_OPTIONS% -- %entry_point% %ARGS%"
)

rem Execute the node wrapper with proper output redirection
if defined STDOUT_CAPTURE (
    if defined STDERR_CAPTURE (
        "%JS_BINARY__NODE_WRAPPER%" %JS_BINARY__NODE_OPTIONS% -- "%entry_point%" %ARGS% 1>>"%STDOUT_CAPTURE%" 2>>"%STDERR_CAPTURE%"
    ) else (
        "%JS_BINARY__NODE_WRAPPER%" %JS_BINARY__NODE_OPTIONS% -- "%entry_point%" %ARGS% 1>>"%STDOUT_CAPTURE%"
    )
) else (
    if defined STDERR_CAPTURE (
        "%JS_BINARY__NODE_WRAPPER%" %JS_BINARY__NODE_OPTIONS% -- "%entry_point%" %ARGS% 2>>"%STDERR_CAPTURE%"
    ) else (
        "%JS_BINARY__NODE_WRAPPER%" %JS_BINARY__NODE_OPTIONS% -- "%entry_point%" %ARGS%
    )
)

set "RESULT=%ERRORLEVEL%"

rem ==============================================================================
rem Mop up after main program
rem ==============================================================================

if defined JS_BINARY__EXPECTED_EXIT_CODE (
    if %RESULT% neq %JS_BINARY__EXPECTED_EXIT_CODE% (
        call :logf_error "expected exit code to be '%JS_BINARY__EXPECTED_EXIT_CODE%', but got '%RESULT%'"
        if %RESULT% equ 0 (
            rem This exit code is handled specially by Bazel:
            rem https://github.com/bazelbuild/bazel/blob/486206012a664ecb20bdb196a681efc9a9825049/src/main/java/com/google/devtools/build/lib/util/ExitCode.java#L44
            set "BAZEL_EXIT_TESTS_FAILED=3"
            call :cleanup_and_exit
            exit /b 3
        )
        call :cleanup_and_exit
        exit /b %RESULT%
    ) else (
        call :cleanup_and_exit
        exit /b 0
    )
)

if defined JS_BINARY__EXIT_CODE_OUTPUT_FILE (
    rem Exit zero if the exit code was captured
    echo %RESULT%> "%JS_BINARY__EXIT_CODE_OUTPUT_FILE%"
    call :cleanup_and_exit
    exit /b 0
) else (
    call :cleanup_and_exit
    exit /b %RESULT%
)

rem ==============================================================================
rem Helper functions
rem ==============================================================================

:extract_execroot_from_path
set "full_path=%~1"
set "segment=%~2"
rem Check if segment is empty or undefined
if "%segment%"=="" (
    set "JS_BINARY__EXECROOT=%full_path%"
    exit /b 0
)
rem Simple approach: find the segment and take everything before it
for /f "tokens=1 delims=" %%a in ('echo "%full_path%" ^| findstr /o /c:"%segment%"') do (
    set "pos_info=%%a"
    goto :found_segment
)
rem If segment not found, use the full path as execroot
set "JS_BINARY__EXECROOT=%full_path%"
exit /b 0

:found_segment
rem Extract position number (before the colon)
for /f "tokens=1 delims=:" %%b in ("!pos_info!") do (
    set "pos=%%b"
)
rem Calculate the position to extract (pos-1)
set /a "extract_pos=!pos!-1"
if !extract_pos! leq 0 (
    set "JS_BINARY__EXECROOT=%full_path%"
) else (
    set "JS_BINARY__EXECROOT=!full_path:~0,%extract_pos%!"
)
exit /b 0
