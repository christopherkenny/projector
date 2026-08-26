#import "@preview/polylux:0.4.0" as polylux
#import "../polylux-toolbox.typ" as toolbox-module

#let toolbox = toolbox-module.toolbox

#let slide = polylux.slide
#let focus-slide = slide
#let last-slide = slide
#let pause(..args) = [#show: later]
#let item-by-item = polylux.item-by-item
#let slide-number() = polylux.toolbox.slide-number
#let later = polylux.later
#let speaker-note = toolbox.pdfpc.speaker-note
#let setup(handout: false) = {
  if handout { polylux.enable-handout-mode(true) }
}
#let render-section(name, api: none, section-slide-fn: none) = section-slide-fn(api, name)
#let render-slide(title: none, slide-kind: "slide", body) = {
  let slide-fn = if slide-kind == "focus-slide" {
    focus-slide
  } else if slide-kind == "last-slide" {
    last-slide
  } else {
    slide
  }
  context {
    let figure-start = counter(figure.where(kind: "quarto-float-fig")).get().first()
    slide-fn[
      #counter(figure.where(kind: "quarto-float-fig")).update(figure-start)
      #if title != none { heading(level: 1, title) }
      #body
    ]
  }
}

#let default-toc-slide(api, toc_title) = (api.slide)[
  #let title = if toc_title == none { "Outline" } else { toc_title }
  #heading(title)
  #set text(size: 2em)
  #align(horizon)[
    #(api.toolbox.all-sections)((sections, current) => {
      sections
        .map(s => if s == current { emph(s) } else { s })
        .join([ #linebreak() ])
    })
  ]
]

#let default-section-slide(api, name) = (api.slide)[
  #align(horizon)[
    #text(size: 4em)[#strong(name)]
    #(api.toolbox.register-section)(name)
  ]
]

#let configure(theme: "none") = (
  toolbox: toolbox,
  api: (
    name: "polylux",
    theme: theme,
  ),
  slide: slide,
  focus-slide: focus-slide,
  last-slide: last-slide,
  pause: pause,
  item-by-item: item-by-item,
  slide-number: slide-number,
  later: later,
  speaker-note: speaker-note,
  setup: setup,
  apply: (body, paper: "presentation-16-9", margin: (x: 0.5in, y: 0.5in), fontsize: 11pt, handout: false, title: none, subtitle: none, authors: none, date: none, api: none, section-slide-fn: none, backend-customize: none) => body,
  render-section: render-section,
  render-slide: render-slide,
  default-toc-slide: default-toc-slide,
  default-section-slide: default-section-slide,
)
