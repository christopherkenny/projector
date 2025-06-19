#let grey-gray = rgb("#dbdbdb")
#let grey-dark-gray = rgb("#4a4a4a")

#let projector-theme(doc) = {
  // Set the default text and background colors
  set text(stroke: grey-dark-gray)
  set page(fill: grey-gray)
  show heading: it => {
    it
    v(1em)
  }
  set box(stroke: black, outset: 2em)
  doc
}

#import "@preview/polylux:0.4.0": *
#let section-slide(name) = {
  slide[
    #set text(size: 3em)
    #name
    #toolbox.register-section(name)
  ]
}
