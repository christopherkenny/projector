
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
  doc,
) = {


  set page(
    paper: paper, // TODO put back to paper with better defaults
    margin: margin,
    numbering: "1",
  )

  set par(justify: true)

  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)

  set heading(numbering: sectionnumbering)
  show heading: set text(size: 1.5em)
  set text(size: 1.25em)

  if handout {
    enable-handout-mode(true)
  }

  if title != none or authors != none or date != none {

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

      #if authors != none and authors != [] {
        let count = authors.len()
        let ncols = calc.min(count, 3)
        grid(
          columns: (1fr,) * ncols,
          row-gutter: 1.5em,
          ..authors.map(author =>
              align(center)[
                #author.name \
                #author.affiliation
              ]
          )
        )
      }

      #if date != none {
        align(center)[#block(inset: 1em)[
          #date
        ]
      ]
    }
    ]

    if toc {
      polylux-slide[
        #let title = if toc_title == none {
          auto
        } else {
          toc_title
        #heading(toc_title)
        #set text(size: 2em)
        // TODO 0.13 update to use new toolbox version
        #align(horizon)[
          #polylux-outline()
        ]
      ]
    }

  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
