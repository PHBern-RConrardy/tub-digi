local site_url = nil
local source_dir = ""
local project_dir = nil
local context_loaded = false
local protected_marker = LINK_SITE_URL_PROTECTED_MARKER
local protected_marker_typst = LINK_SITE_URL_PROTECTED_MARKER_TYPST

local function stringify(value)
  if value == nil then
    return nil
  end
  return pandoc.utils.stringify(value)
end

local function trim_trailing_slash(value)
  return value:gsub("/+$", "")
end

local function trim(value)
  return value:match("^%s*(.-)%s*$")
end

local function unquote(value)
  local first = value:sub(1, 1)
  local last = value:sub(-1)
  if (first == '"' and last == '"') or (first == "'" and last == "'") then
    return value:sub(2, -2)
  end
  return value
end

local function starts_with(value, prefix)
  return value:sub(1, #prefix) == prefix
end

local function strip_pwd(path)
  local pwd = os.getenv("PWD")
  if pwd and starts_with(path, pwd .. "/") then
    return path:sub(#pwd + 2)
  end
  return path
end

local function parent_dir(path)
  return path:match("^(.*)/[^/]+/?$") or path
end

local function find_project_dir()
  if project_dir then
    return project_dir
  end

  -- Prefer Quarto's project context; fall back to walking upward for direct Pandoc runs.
  if quarto and quarto.project and quarto.project.directory then
    project_dir = quarto.project.directory
    return project_dir
  end

  local dir = os.getenv("PWD") or "."
  while dir and dir ~= "" do
    local file = io.open(dir .. "/_quarto.yml", "r")
    if file then
      file:close()
      project_dir = dir
      return project_dir
    end

    local parent = parent_dir(dir)
    if parent == dir then
      break
    end
    dir = parent
  end

  return nil
end

local function project_relative_path(path)
  local root = find_project_dir()
  local pwd = os.getenv("PWD") or "."

  path = path:gsub("\\", "/")

  if root and starts_with(path, root .. "/") then
    return path:sub(#root + 2)
  end

  if starts_with(path, "/") then
    return strip_pwd(path)
  end

  if root and starts_with(pwd, root .. "/") then
    local pwd_relative = pwd:sub(#root + 2)
    if pwd_relative ~= "" then
      return pwd_relative .. "/" .. path
    end
  end

  return path
end

local function dirname(path)
  path = project_relative_path(path)

  local dir = path:match("^(.*)/[^/]*$")
  return dir or ""
end

local function split_target(target)
  local path = target
  local suffix = ""

  local query_at = path:find("?", 1, true)
  local hash_at = path:find("#", 1, true)
  local split_at = nil

  if query_at and hash_at then
    split_at = math.min(query_at, hash_at)
  else
    split_at = query_at or hash_at
  end

  if split_at then
    suffix = path:sub(split_at)
    path = path:sub(1, split_at - 1)
  end

  return path, suffix
end

local function normalize_path(path)
  local absolute = starts_with(path, "/")
  local parts = {}

  for part in path:gmatch("[^/]+") do
    if part == ".." then
      if #parts > 0 then
        table.remove(parts)
      end
    elseif part ~= "." and part ~= "" then
      table.insert(parts, part)
    end
  end

  local normalized = table.concat(parts, "/")
  if absolute then
    return "/" .. normalized
  end
  return normalized
end

local function has_scheme(target)
  return target:match("^%a[%w+.-]*:") ~= nil
end

local function detect_source_dir()
  -- Resolve relative links as if they started next to the rendered document.
  -- Quarto exposes this path even when Pandoc receives a temporary input file.
  if quarto and quarto.doc and quarto.doc.project_output_file and quarto.doc.project_output_file() then
    return dirname(quarto.doc.project_output_file())
  elseif quarto and quarto.doc and quarto.doc.input_file then
    return dirname(quarto.doc.input_file)
  elseif PANDOC_STATE.input_files and PANDOC_STATE.input_files[1] then
    return dirname(PANDOC_STATE.input_files[1])
  end

  return ""
end

local function read_site_url_from_project()
  local root = find_project_dir()
  local config = root and (root .. "/_quarto.yml") or "_quarto.yml"
  local file = io.open(config, "r")
  if not file then
    return nil
  end

  for line in file:lines() do
    local value = line:match("^%s*site%-url:%s*(.-)%s*$")
    if value and value ~= "" then
      file:close()
      return trim_trailing_slash(unquote(trim(value)))
    end
  end

  file:close()
  return nil
end

local function load_context(meta)
  -- website.site-url is not always present in format metadata, so read _quarto.yml
  -- as a fallback. This keeps the public URL single-sourced in the project config.
  if meta then
    local website = meta.website
    if website and website["site-url"] then
      site_url = trim_trailing_slash(stringify(website["site-url"]))
    elseif meta["site-url"] then
      site_url = trim_trailing_slash(stringify(meta["site-url"]))
    end
  end

  if not site_url then
    site_url = read_site_url_from_project()
  end

  if not context_loaded then
    source_dir = detect_source_dir()
    context_loaded = true
  end
end

local function should_rewrite(target)
  load_context()

  -- Leave external links, protocol-relative links, and same-document anchors alone.
  return site_url
    and target ~= ""
    and not starts_with(target, "#")
    and not starts_with(target, "//")
    and not has_scheme(target)
end

local protected_path

local function absolute_site_url(target)
  local path, suffix = split_target(target)
  local site_path = path

  if not starts_with(site_path, "/") and source_dir ~= "" and not protected_path(site_path) then
    site_path = source_dir .. "/" .. site_path
  end

  site_path = normalize_path(site_path)
  -- Hyperlink targets in packaged formats should carry URL-safe spaces.
  site_path = site_path:gsub(" ", "%%20")
  if not starts_with(site_path, "/") then
    site_path = "/" .. site_path
  end

  return site_url .. site_path .. suffix
end

protected_path = function(target)
  local path = split_target(target)

  if site_url and starts_with(path, site_url) then
    path = path:sub(#site_url + 1)
  end

  path = path:gsub("\\", "/")
  path = normalize_path(path)

  return path == "resources_non_free"
    or starts_with(path, "resources_non_free/")
    or path:find("/resources_non_free/", 1, true) ~= nil
end

local function protected_marker_inlines(target)
  if not protected_marker or not protected_path(target) then
    return nil
  end

  if protected_marker_typst then
    return {
      pandoc.RawInline("typst", protected_marker_typst),
      pandoc.Space(),
    }
  end

  return {
    pandoc.Str(protected_marker),
    pandoc.Space(),
  }
end

local function meta_filter(meta)
  load_context(meta)
  return meta
end

local function link_filter(link)
  local marker = protected_marker_inlines(link.target)

  if should_rewrite(link.target) then
    link.target = absolute_site_url(link.target)
  end

  if marker then
    table.insert(marker, link)
    return marker
  end

  return link
end

return {
  {
    Meta = meta_filter,
    Link = link_filter,
  },
}
