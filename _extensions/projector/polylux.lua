local in_slide = false  -- Track if we're inside a slide

function Header(el)
  local blocks = {}

  -- Close the previous slide if one was open
  if in_slide then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
  end

  -- Start a new slide
  table.insert(blocks, pandoc.RawBlock("typst", "#polylux-slide["))
  table.insert(blocks, pandoc.RawBlock("typst", "= " .. pandoc.utils.stringify(el)))

  in_slide = true  -- We are now inside a slide
  return blocks
end

function finalize(doc)
  local blocks = doc.blocks

  -- Close the last slide if still open
  if in_slide then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
  end

  return pandoc.Pandoc(blocks, doc.meta)
end

return {
  { Header = Header },
  { Pandoc = finalize }
}