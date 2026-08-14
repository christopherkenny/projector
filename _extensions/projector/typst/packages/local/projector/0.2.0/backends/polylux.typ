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
#let apply(body, ..args) = body
#let section-heading(name) = none
