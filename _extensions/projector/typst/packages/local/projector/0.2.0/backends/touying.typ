#import "@preview/touying:0.7.4" as touying
#import "../touying-toolbox.typ" as toolbox-module

#let toolbox = toolbox-module.toolbox
#let slide = touying.slide
#let focus-slide = slide
#let last-slide = slide
#let pause = touying.pause
#let item-by-item = touying.item-by-item
#let slide-number() = context touying.utils.slide-counter.display()
#let later = (..args) => none
#let speaker-note = toolbox.pdfpc.speaker-note
#let setup(handout: false) = none
#let apply(
  body,
  slide-fn: touying.slide,
  theme: touying.touying-slides,
  paper: "presentation-16-9",
  margin: (x: 0.5in, y: 0.5in),
  handout: false,
  title: none,
  subtitle: none,
  authors: none,
  date: none,
) = {
  let render(page-config: (:)) = theme.with(
    touying.config-page(
      paper: paper,
      margin: page-config.at("margin", default: margin),
      numbering: none,
      header: page-config.at("header", default: none),
      footer: page-config.at("footer", default: none),
      fill: page-config.at("fill", default: white),
    ),
    touying.config-common(
      handout: handout,
      slide-level: 2,
      new-section-slide-fn: none,
      slide-fn: slide-fn,
    ),
    touying.config-methods(init: (self: none, body) => body),
    touying.config-info(
      title: title,
      subtitle: subtitle,
      author: if authors == none or authors == [] { none } else {
        authors.map(author => {
          let affiliation = author.at("affiliation", default: none)
          if affiliation == none or affiliation == [ ] { author.name }
          else { [#author.name, #h(0.5em) #affiliation] }
        }).join([, ])
      },
      date: date,
    ),
  )(body)
  render(page-config: (margin: margin, header: none, footer: none, fill: white))
}
#let section-heading(name) = {
  show heading.where(level: 1): it => none
  eval("= #text(" + repr(name) + ")", mode: "markup")
}
