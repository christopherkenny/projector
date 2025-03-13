
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
  handout: false,
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
  
  if handout {
    enable-handout-mode(true)
  }

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
