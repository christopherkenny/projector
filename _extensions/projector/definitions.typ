#import "@preview/polylux:0.3.1": *

// Some definitions presupposed by pandoc's typst output.
#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

// TODO 0.13 update to slide
#let projector-register-section(name) = polylux-slide[
  #set align(horizon)
  #set text(size: 4em)
  // TODO 0.13 update to #toolbox.register-section
  #utils.register-section(name)

  #strong(name)
]
