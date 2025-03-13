#import "@preview/polylux:0.3.1": *

// Some definitions presupposed by pandoc's typst output.
#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {


  set page(
    paper: "presentation-16-9", // TODO put back to paper with better defaults
    margin: margin,
    numbering: "1",
  )
  
  set par(justify: true)
  
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
           
  set heading(numbering: sectionnumbering)

  if title != none or authors != none or date != none {
  
    polylux-slide[
      #if title != none {
        align(center)[
          #block(inset: 2em)[
            #text(weight: "bold", size: 30pt)[
              #title
            ]
            #if subtitle != none {
              linebreak()
              text(subtitle, size: 18pt, weight: "semibold")
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

#show: doc => article(
  title: [A presentation with Polylux via Quarto],
  authors: (
    ( name: [Author One],
      affiliation: [Harvard University],
      email: [] ),
    ( name: [Author Two],
      affiliation: [Yale University],
      email: [] ),
    ),
  date: [2025-03-13],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)


#polylux-slide[
= Introduction
#emph[TODO] Create an example file that demonstrates the formatting and features of your format.

]
#polylux-slide[
= More Information
You can learn more about creating custom Typst templates here:

#link("https://quarto.org/docs/prerelease/1.4/typst.html#custom-formats")

]



