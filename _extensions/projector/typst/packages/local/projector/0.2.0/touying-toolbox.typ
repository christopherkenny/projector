#import "@preview/touying:0.7.4" as touying
#import "pdfpc-core.typ" as pdfpc_module

#let sections-state = state("projector-touying-sections", ())

#let progress-ratio(callback) = touying.utils.touying-progress(callback)

#let next-heading(level: 1, fn) = context {
  let headings = query(heading.where(level: level).after(here()))
  if headings.len() > 0 {
    let next = headings.first()
    if next.location().page() == here().page() {
      fn(next.body)
    }
  }
}

#let big(body) = {
  block(height: 1fr, width: 100%, {
    layout(size => {
      let (width, height) = size
      set text(top-edge: "bounds", bottom-edge: "bounds")
      scale(body, x: width, y: height, reflow: true)
    })
  })
}

#let side-by-side(columns: none, gutter: 1em, ..bodies) = {
  let bodies = bodies.pos()
  let columns = if columns == none { (1fr,) * bodies.len() } else { columns }
  if columns.len() != bodies.len() {
    panic("number of columns must match number of content arguments")
  }
  grid(columns: columns, gutter: gutter, ..bodies)
}

#let full-width-block(..args) = context {
  let page-margin = page.margin
  let margins = if type(page-margin) in (length, relative) {
    (left: page-margin, right: page-margin)
  } else if type(page-margin) == dictionary {
    let left = if "left" in page-margin {
      page-margin.left
    } else if "rest" in page-margin {
      page-margin.rest
    }
    let right = if "right" in page-margin {
      page-margin.right
    } else if "rest" in page-margin {
      page-margin.rest
    }
    if none in (left, right) or auto in (left, right) {
      panic("left and right margin must be specified and not be auto")
    }
    (left: left, right: right)
  }
  let margin-width = margins.left + margins.right
  show: move.with(dx: -margins.left)
  block(width: 100% + margin-width, ..args)
}

#let all-sections(callback) = context {
  let sections = sections-state.final()
  let current = if sections-state.get().len() > 0 {
    sections-state.get().last()
  } else {
    []
  }
  callback(sections, current)
}

#let register-section(name) = context {
  let location = here()
  sections-state.update(sections => {
    sections.push(link(location, name))
    sections
  })
}

#let slide-number = context touying.utils.slide-counter.display()
#let last-slide-number = touying.utils.last-slide-number
#let current-section = context {
  let sections = sections-state.get()
  if sections.len() > 0 {
    sections.last()
  } else {
    []
  }
}

#let pdfpc = (
  speaker-note: pdfpc_module.speaker-note,
  config: pdfpc_module.config,
)
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
  pdfpc: pdfpc,
)
