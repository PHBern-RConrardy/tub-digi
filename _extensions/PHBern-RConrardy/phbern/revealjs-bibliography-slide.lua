local script_dir = PANDOC_SCRIPT_FILE:match("^(.*)/[^/]*$") or "."

local function extension_asset_path(relative_path)
  local input_file = quarto and quarto.doc and quarto.doc.input_file
    or (PANDOC_STATE.input_files and PANDOC_STATE.input_files[1])
    or "."
  local input_dir = pandoc.path.directory(input_file)

  if pandoc.path.is_relative(input_dir) then
    input_dir = pandoc.path.join({ pandoc.system.get_working_directory(), input_dir })
  end

  local target = pandoc.path.join({ script_dir, "assets", relative_path })
  return pandoc.path.make_relative(target, input_dir, true)
end

local function has_class(element, class_name)
  for _, class in ipairs(element.classes) do
    if class == class_name then
      return true
    end
  end

  return false
end

local function set_background(header, path, size, position)
  header.attributes["data-background-image"] = extension_asset_path(path)
  header.attributes["data-background-repeat"] = "no-repeat"
  header.attributes["data-background-size"] = size
  header.attributes["data-background-position"] = position
end

local function add_semantic_background(header)
  if has_class(header, "science") then
    set_background(
      header,
      "soco-st/493141_a-woman-doing-research-and-experiments.svg",
      "200px auto",
      "right 10px top 10px"
    )
    return true
  elseif has_class(header, "padlet") then
    set_background(header, "padlet.svg", "200px auto", "right 10px bottom 10px")
    return true
  elseif has_class(header, "paper") then
    set_background(
      header,
      "soco-st/492851_notepad-and-pen.svg",
      "170px auto",
      "right 10px bottom 44px"
    )
    return true
  elseif has_class(header, "pause") then
    set_background(header, "soco-st/492849_clock.svg", "auto 100%", "center center")
    return true
  end

  return false
end

local function add_markdown_blocks(doc, markdown)
  local blocks = pandoc.read(markdown, "markdown").blocks

  for _, block in ipairs(blocks) do
    table.insert(doc.blocks, block)
  end
end

local function with_scheme(url)
  if url:match("^%a[%w+.-]*://") then
    return url
  end

  return "https://" .. url
end

function Image(image)
  if image.src:match("^soco%-st/") then
    image.src = extension_asset_path(image.src)
    return image
  end
end

function Header(header)
  local has_background = add_semantic_background(header)
  local padlet_url = header.attributes["data-padlet-url"]
  local paper_link = header.attributes["data-paper-link"]

  if padlet_url and paper_link then
    error("A slide cannot use both data-padlet-url and data-paper-link.")
  end

  if not padlet_url and not paper_link then
    return has_background and header or nil
  end

  local link
  local div_class

  if padlet_url then
    link = pandoc.Link(
      pandoc.Inlines(padlet_url),
      with_scheme(padlet_url),
      "",
      pandoc.Attr("", {}, { target = "_blank", rel = "noopener noreferrer" })
    )
    div_class = "padlet-url"
  else
    link = pandoc.Link(pandoc.Inlines("Übungsblatt"), paper_link)
    div_class = "paper-link"
  end

  local para = pandoc.Para({ link })
  local div = pandoc.Div({ para }, pandoc.Attr("", { div_class }, {}))

  return { header, div }
end

function Pandoc(doc)
  add_markdown_blocks(doc, string.format([[
## Rechtliches

:::: {.columns}

::: {.column width="50%%"}
![](<%s>)
:::

::: {.column width="50%%"}
### Urheberrecht

- Bilder wie das links: CC BY [Soco St](https://www.svgrepo.com/author/soco-st/) via SVG Repo
- Eigene Slides unter [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)
:::

::::
]], extension_asset_path("soco-st/492964_male-judge-upper-body.svg")))

  table.insert(
    doc.blocks,
    pandoc.Header(2, pandoc.Inlines("Literatur"), pandoc.Attr("", { "smaller", "scrollable" }, {}))
  )

  table.insert(
    doc.blocks,
    pandoc.Div({}, pandoc.Attr("refs", {}, {}))
  )

  return doc
end
