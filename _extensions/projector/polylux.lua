local in_slide = false
local pending_callout = nil
local buffered_blocks = {}

-- Helper to flush any pending callout
local function flush_callout()
  if not pending_callout then return {} end

  local blocks = {}

  local macro = pending_callout.macro -- alert, example, projector-block
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

-- Updated Header handler
function Header(el)
  local blocks = {}

  -- Flush any pending callout
  for _, b in ipairs(flush_callout()) do
    table.insert(blocks, b)
  end

  -- Close open slide if needed
  if in_slide and el.level <= 2 then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    table.insert(blocks, pandoc.RawBlock("typst", ""))
    in_slide = false
  end

  if el.level == 1 then
    -- TODO 0.13 update to #toolbox.register-section
    local title = pandoc.utils.stringify(el)
    table.insert(blocks, pandoc.RawBlock("typst", ""))
    table.insert(blocks, pandoc.RawBlock("typst", '#projector-register-section("' .. title .. '")'))
    return blocks
  elseif el.level == 2 then
    -- TODO 0.13 update to #slide
    local title = pandoc.utils.stringify(el)
    table.insert(blocks, pandoc.RawBlock("typst", ""))
    table.insert(blocks, pandoc.RawBlock("typst", "#polylux-slide["))
    table.insert(blocks, pandoc.RawBlock("typst", "= " .. title))
    in_slide = true
    return blocks
  elseif el.level == 3 then
    local title = pandoc.utils.stringify(el)
    local class = el.classes[1]

    -- Class-based macro matching
    local macro_map = {
      alert = "alert",
      example = "example",
      tip = "tip",
      note = "note",
      info = "info",
      warning = "warning"
    }

    local macro = "projector-block" -- default fallback
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

    return {} -- don't emit anything yet
  end
end

function HorizontalRule()
  local blocks = {}

  -- Flush any callout first
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

-- Intercept normal blocks to buffer for callouts
function Para(el)
  if pending_callout then
    table.insert(buffered_blocks, el)
    return {}
  else
    return el
  end
end

function BulletList(el)
  if pending_callout then
    table.insert(buffered_blocks, pandoc.BulletList(el))
    return {}
  else
    return pandoc.BulletList(el)
  end
end

function finalize(doc)
  local blocks = doc.blocks

  -- Flush final callout
  for _, b in ipairs(flush_callout()) do
    table.insert(blocks, b)
  end

  -- Close final slide
  if in_slide then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    table.insert(blocks, pandoc.RawBlock("typst", ""))
  end

  return pandoc.Pandoc(blocks, doc.meta)
end

return {
  { Header = Header,  HorizontalRule = HorizontalRule, Para = Para, BulletList = BulletList },
  { Pandoc = finalize }
}
