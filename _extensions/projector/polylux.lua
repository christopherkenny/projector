-- Typst + Quarto Polylux Lua Filter
-- Updated with support for slides, callouts, pause, bullet list control, and grid-based column layout with comprehensive alignment options

local in_slide = false
local pending_callout = nil
local buffered_blocks = {}
local global_incremental = false
local in_incremental_div = false
local in_nonincremental_div = false

function Meta(meta)
  if meta["bullet-incremental"] == true then
    global_incremental = true
  end
  return meta
end

local function flush_callout()
  if not pending_callout then return {} end
  local blocks = {}
  local macro = pending_callout.macro
  local title = pending_callout.title
  table.insert(blocks, pandoc.RawBlock("typst", ""))
  table.insert(blocks, pandoc.RawBlock("typst", "#" .. macro .. '("' .. title .. '")['))
  for _, b in ipairs(buffered_blocks) do
    table.insert(blocks, b)
  end
  table.insert(blocks, pandoc.RawBlock("typst", "]"))
  table.insert(blocks, pandoc.RawBlock("typst", ""))
  pending_callout = nil
  buffered_blocks = {}
  return blocks
end

function Header(el)
  local blocks = {}
  for _, b in ipairs(flush_callout()) do
    table.insert(blocks, b)
  end
  if in_slide and el.level <= 2 then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    table.insert(blocks, pandoc.RawBlock("typst", ""))
    in_slide = false
  end
  if el.level == 1 then
    local title = pandoc.utils.stringify(el)
    table.insert(blocks, pandoc.RawBlock("typst", ""))
    table.insert(blocks, pandoc.RawBlock("typst", '#projector-register-section("' .. title .. '")'))
    return blocks
  elseif el.level == 2 then
    local title = pandoc.utils.stringify(el)
    table.insert(blocks, pandoc.RawBlock("typst", ""))
    table.insert(blocks, pandoc.RawBlock("typst", "#polylux-slide["))
    table.insert(blocks, pandoc.RawBlock("typst", "= " .. title))
    in_slide = true
    return blocks
  elseif el.level == 3 then
    local title = pandoc.utils.stringify(el)
    local macro_map = {
      alert = "alert",
      example = "example",
      tip = "tip",
      reminder = "reminder",
      info = "info",
      warning = "warning"
    }
    local macro = "projector-block"
    for _, cls in ipairs(el.classes) do
      if macro_map[cls] then
        macro = macro_map[cls]
        break
      end
    end
    pending_callout = {
      title = title,
      macro = macro
    }
    return blocks
  end
end

function HorizontalRule()
  local blocks = {}
  for _, b in ipairs(flush_callout()) do
    table.insert(blocks, b)
  end
  if in_slide then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    table.insert(blocks, pandoc.RawBlock("typst", ""))
  end
  table.insert(blocks, pandoc.RawBlock("typst", ""))
  table.insert(blocks, pandoc.RawBlock("typst", "#polylux-slide["))
  in_slide = true
  return blocks
end

function Para(el)
  if pending_callout then
    table.insert(buffered_blocks, el)
    return {}
  end
  local text = pandoc.utils.stringify(el)
  if in_slide and text:match("^%. ?%. ?%.$") then
    return pandoc.RawBlock("typst", "#pause")
  end
  return el
end

function BulletList(el)
  if pending_callout then
    table.insert(buffered_blocks, el)
    return {}
  end
  if in_nonincremental_div then
    return pandoc.BulletList(el)
  end
  if not global_incremental and not in_incremental_div then
    return pandoc.BulletList(el)
  end
  local rendered = pandoc.write(pandoc.Pandoc({ el }), "markdown")
  rendered = rendered:gsub("%s+$", "")
  return {
    pandoc.RawBlock("typst", "#line-by-line["),
    pandoc.RawBlock("typst", rendered),
    pandoc.RawBlock("typst", "]")
  }
end

function Div(el)
  if el.classes:includes("columns") then
    local column_fractions = {}
    local columns = {}
    local align_outer = el.attributes["align"]
    local total_width = el.attributes["totalwidth"]
    local column_aligns = {}

    for _, block in ipairs(el.content) do
      if block.t == "Div" and block.classes:includes("column") then
        local width = block.attributes["width"]
        local fraction = "auto"
        if width then
          local percentage = tonumber(width:match("^(%d+)%%$"))
          if percentage then
            fraction = tostring(percentage) .. "fr"
          else
            fraction = width
          end
        end

        local content = pandoc.write(pandoc.Pandoc(block.content), "typst")
        content = content:gsub("%s+$", "")

        table.insert(columns, "[" .. content .. "]")

        local align_inner = block.attributes["align"] or "left"
        table.insert(column_fractions, fraction)
        table.insert(column_aligns, align_inner)
      end
    end

    local grid = {}
    table.insert(grid, "#grid(")
    table.insert(grid, "  columns: (" .. table.concat(column_fractions, ", ") .. "),")
    table.insert(grid, "  gutter: 1em,")
    table.insert(grid, "  align: (" .. table.concat(column_aligns, ", ") .. "),")
    table.insert(grid, "  " .. table.concat(columns, ",\n  "))
    table.insert(grid, ")")

    local wrapped = table.concat(grid, "\n")

    if total_width and total_width ~= "textwidth" then
      wrapped = "#block(width: " .. total_width .. ")[\n" .. wrapped .. "\n]"
    end

    if align_outer then
      wrapped = "#align(" .. align_outer .. ")[\n" .. wrapped .. "\n]"
    end

    return { pandoc.RawBlock("typst", wrapped) }
  end

  if el.classes:includes("incremental") then
    in_incremental_div = true
    local walked = pandoc.walk_block(el, {
      BulletList = BulletList
    })
    in_incremental_div = false
    return walked.content
  elseif el.classes:includes("nonincremental") then
    in_nonincremental_div = true
    local walked = pandoc.walk_block(el, {
      BulletList = BulletList
    })
    in_nonincremental_div = false
    return walked.content
  end

  return el
end

function finalize(doc)
  local blocks = doc.blocks
  for _, b in ipairs(flush_callout()) do
    table.insert(blocks, b)
  end
  if in_slide then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    table.insert(blocks, pandoc.RawBlock("typst", ""))
  end
  return pandoc.Pandoc(blocks, doc.meta)
end

return {
  { Meta = Meta },
  {
    Header = Header,
    HorizontalRule = HorizontalRule,
    Para = Para,
    BulletList = BulletList,
    Div = Div
  },
  { Pandoc = finalize }
}
