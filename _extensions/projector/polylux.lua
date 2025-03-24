local in_slide = false

function Header(el)
  local blocks = {}

  -- Close any open slide
  if in_slide then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    in_slide = false
  end

  if el.level == 1 then
    -- Register a section
    local title = pandoc.utils.stringify(el)
    -- TODO 0.13 update to #toolbox.register-section later
    table.insert(blocks, pandoc.RawBlock("typst", '#utils.register-section("' .. title .. '")'))
    return blocks
  elseif el.level == 2 then
    -- Start a new slide
    local title = pandoc.utils.stringify(el)
    -- TODO 0.13 update to #slide
    table.insert(blocks, pandoc.RawBlock("typst", "#polylux-slide["))
    table.insert(blocks, pandoc.RawBlock("typst", "= " .. title))
    in_slide = true
    return blocks
  else
    -- Lower-level headers stay as-is
    return el
  end
end

function finalize(doc)
  local blocks = doc.blocks
  if in_slide then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
  end
  return pandoc.Pandoc(blocks, doc.meta)
end

return {
  { Header = Header },
  { Pandoc = finalize }
}
