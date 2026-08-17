_G.LINK_SITE_URL_PROTECTED_MARKER = "🔒"
_G.LINK_SITE_URL_PROTECTED_MARKER_TYPST = [==[#text(font: "Apple Color Emoji", size: 8pt)[🔒]]==]

local script_dir = PANDOC_SCRIPT_FILE:match("^(.*)/[^/]*$") or "."
return dofile(script_dir .. "/link-site-url.lua")
