
#let title-slide(title, subtitle, authors, date) = {
  polylux-slide[
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
          #author.name \
          #author.affiliation
        ])
      )
    }

    #if date != none {
      align(center)[#block(inset: 1em)[
          #date
        ]
      ]
    }
  ]
}

#let toc-slide(toc_title) = {
  polylux-slide[
    #let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    #heading(toc_title)
    #set text(size: 2em)
    // TODO 0.13 update to use new toolbox version
    #align(horizon)[
      #polylux-outline()
    ]
  ]
}

// TODO 0.13 update to slide
#let section-slide(name) = {
  polylux-slide[
    #set align(horizon)
    #set text(size: 4em)
    // TODO 0.13 update to #toolbox.register-section
    #utils.register-section(name)

    #strong(name)
  ]
}

#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1in, y: 1in),
  paper: "presentation-16-9",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  handout: false,
  background: none,
  theme: none,
  doc,
) = {

  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )

  show: it => {
    if theme != none {
      import theme: *
      show: projector-theme
      it
    } else {
      it
    }
  }

  show: it => {
    if background != none {
      set page(background: image(background, width: 100%, height: 100%))
      it
    } else {
      it
    }
  }

  set par(justify: true)

  set text(
    lang: lang,
    region: region,
    font: font,
    size: fontsize,
  )

  set heading(numbering: sectionnumbering)
  show heading: set text(size: 1.5em)
  set text(size: 1.25em)

  if handout {
    enable-handout-mode(true)
  }

  if title != none or authors != none or date != none {
    title-slide(title, subtitle, authors, date)
  }

  if toc {
    toc-slide(toc_title)
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none,
)
