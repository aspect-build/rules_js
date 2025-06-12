@if not defined DEBUG_HELPER @ECHO OFF

if "%JS_BINARY__PATCH_NODE_FS%" == "1" (
  :: --expose-internals is needed for fs patches.
  %JS_BINARY__NODE_BINARY% ^
    --expose-internals --disable-warning=internal/test/binding ^
    --require %JS_BINARY__NODE_PATCHES% %*
) else (
  %JS_BINARY__NODE_BINARY% --require %JS_BINARY__NODE_PATCHES% %*
)
