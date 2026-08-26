-- Typst + Quarto slide filter
-- Keep this filter focused on the Pandoc AST. Backend-specific Typst code
-- belongs in definitions.typ and the backend adapter modules.

local backends = {
  polylux = {
    pause = "#show: later",
  },
  touying = {
    theme_key = "touying-theme",
    default_theme = "simple",
    pause = "#pause",
  },
}

local backend = "polylux"
local backend_spec = backends.polylux
local pending_callout = nil
local buffered_blocks = {}
local global_incremental = false
local in_incremental_div = false
local in_nonincremental_div = false
local column_incremental_position = nil
local in_slide = false
-- Toggle this manually if you want `.notes` blocks exported as pdfpc notes.
local include_pdfpc_notes = false

local function typst_string(value)
  value = tostring(value or "")
  value = value:gsub("\\", "\\\\")
  value = value:gsub('"', '\\"')
  value = value:gsub("\r\n", "\\n")
  value = value:gsub("\n", "\\n")
  return '"' .. value .. '"'
end

local function is_pause_para(el)
  if el.t ~= "Para" or not in_slide then return false end
  local text = pandoc.utils.stringify(el)
  return text:match("^%. ?%. ?%.$") or text == "…"
end

local function append_all(target, source)
  for _, value in ipairs(source) do
    table.insert(target, value)
  end
end

local function append_blocks(target, source)
  if source.t ~= nil then
    table.insert(target, source)
  else
    append_all(target, source)
  end
end

local function buffer_or_return(value)
  if pending_callout then
    append_blocks(buffered_blocks, value)
    return {}
  end
  return value
end

local function close_explicit_slide(blocks)
  if in_slide then
    table.insert(blocks, pandoc.RawBlock("typst", "]"))
    table.insert(blocks, pandoc.RawBlock("typst", ""))
    in_slide = false
  end
end

local function flush_callout()
  if not pending_callout then return {} end

  local blocks = {}
  table.insert(blocks, pandoc.RawBlock("typst", ""))
  table.insert(
    blocks,
    pandoc.RawBlock(
      "typst",
      "#" .. pending_callout.macro .. "(" .. typst_string(pending_callout.title) .. ")["
    )
  )
  append_all(blocks, buffered_blocks)
  table.insert(blocks, pandoc.RawBlock("typst", "]"))
  table.insert(blocks, pandoc.RawBlock("typst", ""))

  pending_callout = nil
  buffered_blocks = {}
  return blocks
end

function Meta(meta)
  backend = meta["backend"] ~= nil
    and pandoc.utils.stringify(meta["backend"])
    or "polylux"
  backend_spec = backends[backend]
  if backend_spec == nil then
    error("Unsupported backend: " .. backend)
  end

  if backend ~= "touying" and meta["touying-theme"] ~= nil then
    error("touying-theme is only supported by the 'touying' backend")
  end
  if backend_spec.theme_key ~= nil then
    if meta[backend_spec.theme_key] == nil and backend_spec.default_theme ~= nil then
      meta[backend_spec.theme_key] = pandoc.MetaString(backend_spec.default_theme)
    end
    if meta[backend_spec.theme_key] ~= nil then
      meta["projector_backend_theme"] = pandoc.MetaString(
        pandoc.utils.stringify(meta[backend_spec.theme_key])
      )
    end
  end

  meta["backend"] = pandoc.MetaString(backend)

  global_incremental = meta["bullet-incremental"] == true
  pending_callout = nil
  buffered_blocks = {}
  in_incremental_div = false
  in_nonincremental_div = false
  column_incremental_position = nil
  in_slide = false
  return meta
end

function Header(el)
  local blocks = flush_callout()

  if in_slide and el.level <= 2 then
    close_explicit_slide(blocks)
  end

  if el.level == 1 then
    local section_name = pandoc.utils.stringify(el)
    table.insert(
      blocks,
      pandoc.RawBlock(
        "typst",
        "#backend-render-section(" .. typst_string(section_name)
          .. ", api: theme-api, section-slide-fn: section-slide)"
      )
    )
    return blocks
  elseif el.level == 2 then
    local macro = "slide"
    local slide_types = { focus = true, last = true }
    for _, class in ipairs(el.classes) do
      if slide_types[class] then
        macro = class .. "-slide"
        break
      end
    end

    table.insert(blocks, pandoc.RawBlock("typst", ""))
    table.insert(
      blocks,
      pandoc.RawBlock(
        "typst",
        "#backend-render-slide(title: " .. typst_string(pandoc.utils.stringify(el))
          .. ", slide-kind: " .. typst_string(macro) .. ")["
      )
    )
    in_slide = true
    return blocks
  elseif el.level == 3 then
    local macro = "projector-block"
    local callout_macros = {
      alert = true,
      example = true,
      tip = true,
      reminder = true,
      info = true,
      warning = true,
    }
    for _, class in ipairs(el.classes) do
      if callout_macros[class] then
        macro = class
        break
      end
    end

    pending_callout = {
      title = pandoc.utils.stringify(el),
      macro = macro,
    }
    return blocks
  end

  if #blocks == 0 then
    return el
  end
  table.insert(blocks, el)
  return blocks
end

function HorizontalRule()
  local blocks = flush_callout()
  close_explicit_slide(blocks)
  table.insert(blocks, pandoc.RawBlock("typst", ""))
  table.insert(blocks, pandoc.RawBlock("typst", "#backend-render-slide["))
  in_slide = true
  return blocks
end

function Para(el)
  if is_pause_para(el) then
    local blocks = flush_callout()
    table.insert(blocks, pandoc.RawBlock("typst", backend_spec.pause))
    return blocks
  end

  if pending_callout then
    table.insert(buffered_blocks, el)
    return {}
  end
  return el
end

local function incremental_list(el)
  local rendered = pandoc.write(pandoc.Pandoc({ el }), "markdown")
  rendered = rendered:gsub("%s+$", "")
  local opening = "#item-by-item["
  if column_incremental_position ~= nil then
    opening = "#item-by-item(start: " .. tostring(column_incremental_position) .. ")["
    column_incremental_position = column_incremental_position + #el.content
  end
  return {
    pandoc.RawBlock("typst", opening),
    pandoc.RawBlock("typst", rendered),
    pandoc.RawBlock("typst", "]"),
  }
end

function BulletList(el)
  if in_nonincremental_div then return buffer_or_return(el) end
  if in_incremental_div or global_incremental then
    return buffer_or_return(incremental_list(el))
  end
  return buffer_or_return(el)
end

function OrderedList(el)
  if in_nonincremental_div then return buffer_or_return(el) end
  if in_incremental_div or global_incremental then
    return buffer_or_return(incremental_list(el))
  end
  return buffer_or_return(el)
end

local function transform_div(el)
  if el.classes:includes("columns") then
    local fractions = {}
    local columns = {}
    local aligns = {}
    local outer_align = el.attributes["align"]
    local total_width = el.attributes["totalwidth"]
    local owns_incremental_sequence = column_incremental_position == nil
    local pending_column_pauses = 0
    if owns_incremental_sequence then
      column_incremental_position = 1
    end

    for _, block in ipairs(el.content) do
      if block.t == "Div" and block.classes:includes("column") then
        local width = block.attributes["width"]
        local fraction = "auto"
        if width then
          local percentage = tonumber(width:match("^(%d+)%%$"))
          fraction = percentage and (tostring(percentage) .. "fr") or width
        end

        local previous_incremental = in_incremental_div
        local previous_nonincremental = in_nonincremental_div
        if block.classes:includes("incremental") then
          in_incremental_div = true
        end
        if block.classes:includes("nonincremental") then
          in_nonincremental_div = true
        end

        local walked = block:walk({
          traverse = "topdown",
          Div = function(nested)
            if nested.classes:includes("columns")
                or nested.classes:includes("incremental")
                or nested.classes:includes("nonincremental")
                or nested.classes:includes("notes") then
              return transform_div(nested), false
            end
            return nested
          end,
          BulletList = BulletList,
          OrderedList = OrderedList,
          Para = Para,
        })
        in_incremental_div = previous_incremental
        in_nonincremental_div = previous_nonincremental
        local content = pandoc.write(pandoc.Pandoc(walked.content), "typst")
        content = content:gsub("%s+$", "")
        if pending_column_pauses > 0 then
          content = string.rep(backend_spec.pause .. "\n", pending_column_pauses) .. content
          pending_column_pauses = 0
        end
        table.insert(columns, "[" .. content .. "]")
        table.insert(fractions, fraction)
        table.insert(aligns, block.attributes["align"] or "left")
      elseif is_pause_para(block) then
        pending_column_pauses = pending_column_pauses + 1
      end
    end

    if owns_incremental_sequence then
      column_incremental_position = nil
    end

    local result = {
      "#grid(",
      "  columns: (" .. table.concat(fractions, ", ") .. "),",
      "  gutter: 1em,",
      "  align: (" .. table.concat(aligns, ", ") .. "),",
      "  " .. table.concat(columns, ",\n  "),
      ")",
    }
    local wrapped = table.concat(result, "\n")

    if total_width and total_width ~= "textwidth" then
      wrapped = "#block(width: " .. total_width .. ")[\n" .. wrapped .. "\n]"
    end
    if outer_align then
      wrapped = "#align(" .. outer_align .. ")[\n" .. wrapped .. "\n]"
    end
    local result_blocks = { pandoc.RawBlock("typst", wrapped) }
    if pending_column_pauses > 0 then
      table.insert(
        result_blocks,
        pandoc.RawBlock("typst", string.rep(backend_spec.pause .. "\n", pending_column_pauses))
      )
    end
    return result_blocks
  end

  if el.classes:includes("incremental") then
    local previous_incremental = in_incremental_div
    in_incremental_div = true
    local walked = pandoc.walk_block(el, {
      BulletList = BulletList,
      OrderedList = OrderedList,
    })
    in_incremental_div = previous_incremental
    return walked.content
  elseif el.classes:includes("nonincremental") then
    local previous_nonincremental = in_nonincremental_div
    in_nonincremental_div = true
    local walked = pandoc.walk_block(el, {
      BulletList = BulletList,
      OrderedList = OrderedList,
    })
    in_nonincremental_div = previous_nonincremental
    return walked.content
  elseif el.classes:includes("notes") then
    if not include_pdfpc_notes then return {} end
    return pandoc.RawBlock(
      "typst",
      "#speaker-note(" .. typst_string(pandoc.utils.stringify(el.content)) .. ")"
    )
  end

  return el
end

function Div(el)
  if not pending_callout then
    return transform_div(el)
  end

  local callout = pending_callout
  pending_callout = nil
  local result = transform_div(el)
  pending_callout = callout
  return buffer_or_return(result)
end

local function buffer_block(el)
  return buffer_or_return(el)
end

function finalize(doc)
  append_all(doc.blocks, flush_callout())
  close_explicit_slide(doc.blocks)
  return pandoc.Pandoc(doc.blocks, doc.meta)
end

return {
  { Meta = Meta },
  {
    traverse = "topdown",
    Div = Div,
    BulletList = BulletList,
    OrderedList = OrderedList,
    BlockQuote = buffer_block,
    CodeBlock = buffer_block,
    DefinitionList = buffer_block,
    Figure = buffer_block,
    Header = Header,
    HorizontalRule = HorizontalRule,
    LineBlock = buffer_block,
    Para = Para,
    Plain = buffer_block,
    RawBlock = buffer_block,
    Table = buffer_block,
  },
  { Pandoc = finalize },
}
