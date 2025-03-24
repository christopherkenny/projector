local in_slide = false
local pending_callout = nil
local buffered_blocks = {}
local global_incremental = false
local in_incremental_div = false
local in_nonincremental_div = false

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '\"' .. k .. '\"' end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

function sleep(n)
  if n > 0 then os.execute('ping -n ' .. tonumber(n + 1) .. ' localhost > NUL') end
end

function Meta(meta)
  if meta["bullet-incremental"] == true then
    global_incremental = true
  end
  return meta
end

-- Flush a pending callout into Typst
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

-- Handle headers
function Header(el)
  local blocks = {}

  -- Flush any callout before processing the new header
  for _, b in ipairs(flush_callout()) do
    table.insert(blocks, b)
  end

  -- Close slide if needed
  if in_slide and el.level <= 2 then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    table.insert(blocks, pandoc.RawBlock("typst", ""))
    in_slide = false
  end

  if el.level == 1 then
    local title = pandoc.utils.stringify(el)
    -- TODO 0.13 update to #toolbox.register-section later
    table.insert(blocks, pandoc.RawBlock("typst", ""))
    table.insert(blocks, pandoc.RawBlock("typst", '#projector-register-section("' .. title .. '")'))
    return blocks
  elseif el.level == 2 then
    local title = pandoc.utils.stringify(el)
    -- TODO 0.13 update to #slide
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
      reminder = "reminder", -- renamed from 'note'
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

-- Horizontal rule = unnamed slide break
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
  -- TODO 0.13 update to #slide
  table.insert(blocks, pandoc.RawBlock("typst", "#polylux-slide["))

  in_slide = true
  return blocks
end

-- Paragraphs, including `. . .` pause
function Para(el)
  if pending_callout then
    table.insert(buffered_blocks, el)
    return {}
  end

  local text = pandoc.utils.stringify(el)

  -- Match . . . only inside a slide
  if in_slide and text:match("^%. ?%. ?%.$") then
    -- TODO 0.13: replace #pause with Typst-native #show: once Quarto supports it
    return pandoc.RawBlock("typst", "#pause")
  end

  return el
end

-- Bullet lists, respecting global or local incremental settings
function BulletList(el)
  if pending_callout then
    table.insert(buffered_blocks, el)
    return {}
  end

  -- Skip incremental if inside .nonincremental
  if in_nonincremental_div then
    return pandoc.BulletList(el)
  end

  -- Only render incrementally if global or .incremental is set
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

-- Handle classed divs: .incremental and .nonincremental
function Div(el)
  if el.classes:includes("incremental") then
    in_incremental_div = true
    local walked = pandoc.walk_block(el, {
      BulletList = BulletList
    })
    in_incremental_div = false
    return walked.content -- ✅ Return only the inner content
  elseif el.classes:includes("nonincremental") then
    in_nonincremental_div = true
    local walked = pandoc.walk_block(el, {
      BulletList = BulletList
    })
    in_nonincremental_div = false
    return walked.content -- ✅ Same here
  end

  return el
end

-- Finalize document: flush last callout and close slide
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

-- Return full filter
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
