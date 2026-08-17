local script_dir = PANDOC_SCRIPT_FILE:match("^(.*)/[^/]*$") or "."
return dofile(script_dir .. "/link-site-url.lua")
