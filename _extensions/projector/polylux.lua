local in_slide = false

function Header(el)
  local blocks = {}

  -- Close any open slide (only when current header is level 1 or 2)
  if in_slide and el.level <= 2 then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    table.insert(blocks, pandoc.RawBlock("typst", "")) -- blank line after closing slide
    in_slide = false
  end

  if el.level == 1 then
    -- Register a section
    local title = pandoc.utils.stringify(el)
    table.insert(blocks, pandoc.RawBlock("typst", "")) -- blank line
    -- TODO 0.13 update to #toolbox.register-section later
    table.insert(blocks, pandoc.RawBlock("typst", '#utils.register-section("' .. title .. '")'))
    return blocks
  elseif el.level == 2 then
    -- Start a new slide
    local title = pandoc.utils.stringify(el)
    table.insert(blocks, pandoc.RawBlock("typst", "")) -- blank line
    -- TODO 0.13 update to #slide
    table.insert(blocks, pandoc.RawBlock("typst", "#polylux-slide["))
    table.insert(blocks, pandoc.RawBlock("typst", "= " .. title))
    in_slide = true
    return blocks
  elseif el.level >= 3 then
    if in_slide then
      return el -- keep level 3+ headers inside slides
    else
      -- Outside slide: emit warning as Typst comment
      local title = pandoc.utils.stringify(el)
      io.stderr:write("[polylux.lua] Warning: Header level " .. el.level .. ' "' .. title .. '" appears outside a slide.\n')
      return {} -- drop from output
    end
  end
end

function finalize(doc)
  local blocks = doc.blocks
  if in_slide then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    table.insert(blocks, pandoc.RawBlock("typst", "")) -- blank line after final slide
  end
  return pandoc.Pandoc(blocks, doc.meta)
end

return {
  { Header = Header },
  { Pandoc = finalize }
}
