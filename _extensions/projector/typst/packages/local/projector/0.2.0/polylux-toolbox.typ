#import "@preview/polylux:0.4.0" as polylux
#import "pdfpc.typ" as pdfpc_module

#let register-section = polylux.toolbox.register-section
#let current-section = polylux.toolbox.current-section
#let all-sections = polylux.toolbox.all-sections
#let progress-ratio = polylux.toolbox.progress-ratio
#let last-slide-number = polylux.toolbox.last-slide-number
#let slide-number = polylux.toolbox.slide-number
#let big = polylux.toolbox.big
#let side-by-side = polylux.toolbox.side-by-side
#let full-width-block = polylux.toolbox.full-width-block
#let next-heading = polylux.toolbox.next-heading
#let pdfpc = pdfpc_module
#let toolbox = (
  register-section: register-section,
  current-section: current-section,
  all-sections: all-sections,
  progress-ratio: progress-ratio,
  last-slide-number: last-slide-number,
  slide-number: slide-number,
  big: big,
  side-by-side: side-by-side,
  full-width-block: full-width-block,
  next-heading: next-heading,
  pdfpc: (
    speaker-note: pdfpc.speaker-note,
    config: pdfpc.config,
    end-slide: pdfpc.end-slide,
    save-slide: pdfpc.save-slide,
    hidden-slide: pdfpc.hidden-slide,
  ),
)
