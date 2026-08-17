export function createRestrictedResourcesMiddleware(options = {}) {
  const protectedPrefix = options.protectedPrefix || "/resources_non_free/";
  const allowedIpRangesPath = options.allowedIpRangesPath || "/_extensions/PHBern-RConrardy/phbern/cloudflare/allowed-ip-ranges.csv";

  return async function onRequest(context) {
    const { request, env, next } = context;
    const url = new URL(request.url);

    if (!url.pathname.startsWith(protectedPrefix)) {
      return next();
    }

    const clientIp = request.headers.get("CF-Connecting-IP") || "";
    const allowedIpRanges = await loadAllowedIpRanges(request, env, allowedIpRangesPath);

    if (isAllowedIp(clientIp, allowedIpRanges) || hasValidPassword(request, env.RESTRICTED_PASSWORD)) {
      const response = await next();
      const guarded = new Response(response.body, response);
      guarded.headers.set("Cache-Control", "private, no-store");
      return guarded;
    }

    return new Response("Restricted", {
      status: 401,
      headers: {
        "WWW-Authenticate": 'Basic realm="PHBern"',
        "Cache-Control": "no-store",
      },
    });
  };
}

async function loadAllowedIpRanges(request, env, path) {
  if (!env.ASSETS) return [];

  const url = new URL(path, request.url);
  const response = await env.ASSETS.fetch(new Request(url, request));

  if (!response.ok) return [];

  return parseAllowedIpRangesCsv(await response.text());
}

function parseAllowedIpRangesCsv(csv) {
  return csv
    .split(/\r?\n/)
    .slice(1)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => line.split(",")[0].trim())
    .filter(Boolean);
}

function hasValidPassword(request, password) {
  if (!password) return false;

  const header = request.headers.get("Authorization");
  if (!header || !header.startsWith("Basic ")) return false;

  let decoded;
  try {
    decoded = atob(header.slice("Basic ".length));
  } catch {
    return false;
  }

  const separator = decoded.indexOf(":");
  const suppliedPassword = separator === -1 ? decoded : decoded.slice(separator + 1);

  return suppliedPassword === password;
}

function isAllowedIp(ip, ranges) {
  if (!ip || !ranges.length) return false;

  return ranges.some((range) => ipMatches(ip, range));
}

function ipMatches(ip, range) {
  if (range.includes("/")) {
    return ipv4InCidr(ip, range);
  }

  return ip === range;
}

function ipv4InCidr(ip, cidr) {
  if (!isIpv4(ip)) return false;

  const [range, bitsText] = cidr.split("/");
  const bits = Number(bitsText);

  if (!isIpv4(range) || !Number.isInteger(bits) || bits < 0 || bits > 32) {
    return false;
  }

  const mask = bits === 0 ? 0 : (0xffffffff << (32 - bits)) >>> 0;

  return (ipv4ToInt(ip) & mask) === (ipv4ToInt(range) & mask);
}

function isIpv4(ip) {
  return /^(\d{1,3}\.){3}\d{1,3}$/.test(ip) && ip.split(".").every((part) => Number(part) <= 255);
}

function ipv4ToInt(ip) {
  return ip.split(".").reduce((acc, part) => ((acc << 8) + Number(part)) >>> 0, 0);
}
