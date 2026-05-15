// dep.mjs -- Simple ESM dependency that exports its own import.meta.url
// Used by the ESM sandbox test to verify ESM imports resolve correctly.

export const depUrl = import.meta.url;
