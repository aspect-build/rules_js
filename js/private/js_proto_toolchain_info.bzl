"""The JsProtoToolchainInfo provider."""

JsProtoToolchainInfo = provider(
    doc = "Information on how to invoke the JavaScript or TypeScript protoc plugin.",
    fields = ["output_file_extensions"],
)
