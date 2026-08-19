#import "@local/projector:0.2.0": load-backend
#import "@preview/fontawesome:0.5.0": *

#let backend-name = "$if(backend)$$backend$$else$polylux$endif$"
#let backend-module = load-backend(backend-name)
#let backend-theme = "$if(projector_backend_theme)$$projector_backend_theme$$else$none$endif$"
#let backend = backend-module.configure(theme: backend-theme)
#let toolbox = backend.toolbox
#let slide = backend.slide
#let focus-slide = backend.focus-slide
#let last-slide = backend.last-slide
#let pause = backend.pause
#let item-by-item = backend.item-by-item
#let slide-number = backend.slide-number
#let later = backend.later
#let speaker-note = backend.speaker-note
#let backend-section-heading = backend.section-heading
#let backend-render-slide = backend.render-slide
#let projector-pause = pause

// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false,
    fill: background_color,
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"),
    width: 100%,
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%,
      below: 0pt,
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt,
          width: 100%,
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

// Shortcuts for callout types
#let alert(title, body, fill: red) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("triangle-exclamation"),
  icon_color: white
)

#let example(title, body, fill: rgb("e5f5ff")) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("lightbulb"),
  icon_color: blue
)

#let tip(title, body, fill: rgb("d2f4d2")) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("circle-check"),
  icon_color: green
)

#let reminder(title, body, fill: rgb("f5f5dc")) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("sticky-note"),
  icon_color: black
)

#let info(title, body, fill: rgb("e0f0ff")) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("circle-info"),
  icon_color: blue
)

#let warning(title, body, fill: orange) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("triangle-exclamation"),
  icon_color: white
)

#let projector-block(title, body) = callout(
  title: title,
  body: body
)

#let projector-default-title-slide(api, title, subtitle, authors, date) = {
  (api.slide)[
    #if title != none {
      align(center)[
        #block(inset: 1em)[
          #text(weight: "bold", size: 3em)[
            #title
          ]
          #if subtitle != none {
            linebreak()
            text(subtitle, size: 2em, weight: "semibold")
          }
        ]
      ]
    }
    #set text(size: 1.25em)

    #if authors != none and authors != [] {
      let count = authors.len()
      let ncols = calc.min(count, 3)
      grid(
        columns: (1fr,) * ncols,
        row-gutter: 1.5em,
        ..authors.map(author => align(center)[
          #author.name
          #linebreak()
          #author.affiliation
        ])
      )
    }

    #if date != none {
      align(center)[#block(inset: 1em)[#date]]
    }
  ]
}

#let projector-default-toc-slide(api, toc_title) = (backend.default-toc-slide)(api, toc_title)
#let projector-default-section-slide(api, name) = (backend.default-section-slide)(api, name)

$if(theme)$
#import "$theme$" as projector-theme-module
#let projector-theme = if "projector-theme" in projector-theme-module {
  (api, body) => projector-theme-module.projector-theme(api, body)
} else {
  (api, body) => body
}
#let title-slide = if "title-slide" in projector-theme-module {
  (api, title, subtitle, authors, date) => projector-theme-module.title-slide(api, title, subtitle, authors, date)
} else {
  projector-default-title-slide
}
#let toc-slide = if "toc-slide" in projector-theme-module {
  (api, toc_title) => projector-theme-module.toc-slide(api, toc_title)
} else {
  projector-default-toc-slide
}
#let section-slide = if "section-slide" in projector-theme-module {
  (api, name) => projector-theme-module.section-slide(api, name)
} else {
  projector-default-section-slide
}
$else$
#let projector-theme = (api, body) => body
#let title-slide = projector-default-title-slide
#let toc-slide = projector-default-toc-slide
#let section-slide = projector-default-section-slide
$endif$

#let backend-setup = backend.setup
#let backend-apply = backend.apply

$if(projector)$
$for(projector/pairs)$
#let $it.key$ = "$it.value$"
$endfor$
$endif$
