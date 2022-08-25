"""Providers for building derivative rules"""

load(
    "//js/private:js_info.bzl",
    _JsInfo = "JsInfo",
    _js_info = "js_info",
    _js_info_complete = "js_info_complete",
)

JsInfo = _JsInfo
js_info = _js_info
js_info_complete = _js_info_complete
