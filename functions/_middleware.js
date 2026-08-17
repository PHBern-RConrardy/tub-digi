import { createRestrictedResourcesMiddleware } from "../_extensions/PHBern-RConrardy/phbern/cloudflare/restricted-resources.js";

export const onRequest = createRestrictedResourcesMiddleware();
