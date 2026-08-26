#import "@preview/touying:0.7.4" as touying
#import "../touying-toolbox.typ" as toolbox-module

#let toolbox = toolbox-module.toolbox
#let slide = touying.slide
#let focus-slide = slide
#let last-slide = slide
#let pause = touying.pause
#let item-by-item = touying.item-by-item
#let slide-number() = context touying.utils.slide-counter.display()
#let later = (..args) => panic(
  "projector: `later` is Polylux-specific and unavailable with the Touying backend; use `pause` for a backend-neutral reveal break"
)
#let speaker-note = toolbox.pdfpc.speaker-note

#let config = (
  page: touying.config-page,
  common: touying.config-common,
  info: touying.config-info,
  colors: touying.config-colors,
  methods: touying.config-methods,
  store: touying.config-store,
)

#let utils = (
  display-current-heading: touying.utils.display-current-heading,
  display-current-short-heading: touying.utils.display-current-short-heading,
)

#let make-theme(theme-module, theme-function, heading-title: true) = (
  slide: theme-module.slide,
  heading-title: heading-title,
  focus-slide-special: "focus-slide" in theme-module,
  focus-slide: if "focus-slide" in theme-module {
    theme-module.focus-slide
  } else {
    theme-module.slide
  },
  last-slide-special: "last-slide" in theme-module,
  last-slide: if "last-slide" in theme-module {
    theme-module.last-slide
  } else {
    theme-module.slide
  },
  theme: theme-function,
)

#let select-theme(name) = if name == "none" {
  (
    slide: touying.slide,
    heading-title: false,
    focus-slide-special: false,
    focus-slide: touying.slide,
    last-slide-special: false,
    last-slide: touying.slide,
    theme: touying.touying-slides,
  )
} else if name == "default" {
  make-theme(
    touying.themes.default,
    touying.themes.default.default-theme,
    heading-title: false,
  )
} else if name == "simple" {
  make-theme(touying.themes.simple, touying.themes.simple.simple-theme)
} else if name == "metropolis" {
  make-theme(touying.themes.metropolis, touying.themes.metropolis.metropolis-theme)
} else if name == "dewdrop" {
  make-theme(touying.themes.dewdrop, touying.themes.dewdrop.dewdrop-theme)
} else if name == "university" {
  make-theme(touying.themes.university, touying.themes.university.university-theme)
} else if name == "aqua" {
  make-theme(touying.themes.aqua, touying.themes.aqua.aqua-theme)
} else if name == "stargazer" {
  make-theme(touying.themes.stargazer, touying.themes.stargazer.stargazer-theme)
} else {
  panic("Unsupported Touying theme: " + name)
}

#let configure(theme: "none") = {
  let selected = select-theme(theme)
  let slide = selected.slide
  let theme-function = selected.theme

  let render-section(name, api: none, section-slide-fn: none) = heading(depth: 1, name)

  let render-slide(title: none, slide-kind: "slide", body) = if theme != "none" {
    let slide-heading = if title == none {
      heading(depth: 2, outlined: false, [])
    } else {
      heading(depth: 2, title)
    }
    let needs-body-title = if slide-kind == "focus-slide" {
      selected.focus-slide-special or not selected.heading-title
    } else if slide-kind == "last-slide" {
      selected.last-slide-special or not selected.heading-title
    } else {
      not selected.heading-title
    }
    let visible-title = if title != none and needs-body-title {
      heading(depth: 3, outlined: false, title)
    } else {
      none
    }
    let content = slide-heading + visible-title + body
    if slide-kind == "slide" {
      content
    } else {
      let slide-fn = if slide-kind == "focus-slide" {
        selected.focus-slide
      } else {
        selected.last-slide
      }
      touying.touying-set-config(
        touying.config-common(slide-fn: slide-fn),
        content,
      )
    }
  } else {
    let slide-fn = if slide-kind == "focus-slide" {
      selected.focus-slide
    } else if slide-kind == "last-slide" {
      selected.last-slide
    } else {
      slide
    }
    slide-fn[
      #if title != none { heading(level: 1, title) }
      #body
    ]
  }

  let setup(handout: false) = none

  let backend-api = (
    name: "touying",
    theme: theme,
    config: config,
    utils: utils,
  )

  let apply(
    body,
    paper: "presentation-16-9",
    margin: (x: 0.5in, y: 0.5in),
    fontsize: 11pt,
    handout: false,
    title: none,
    subtitle: none,
    authors: none,
    date: none,
    api: none,
    section-slide-fn: none,
    backend-customize: none,
  ) = {
    let new-section-slide-fn = if api == none or section-slide-fn == none {
      none
    } else {
      body => touying.touying-slide-wrapper(self => {
        let section-heading = self.headings.last()
        let wrapper = section-slide-fn(api, section-heading.body)
        (wrapper.value.fn)(self)
      })
    }

    let render(page-config: (:)) = {
      let page = (
        paper: paper,
        margin: page-config.at("margin", default: margin),
        numbering: none,
        header: page-config.at("header", default: none),
        footer: page-config.at("footer", default: none),
      )
      if "fill" in page-config {
        page.insert("fill", page-config.fill)
      }

      let customization = if backend-customize == none {
        (:)
      } else {
        let value = backend-customize(api)
        if value == none { (:) } else { value }
      }
      let theme-args = customization.at("theme-args", default: (:))
      let theme-config = customization.at("theme-config", default: ())
      let customized-theme = theme-function.with(..theme-args)

      let configured-theme = customized-theme.with(
        touying.config-page(..page),
        touying.config-common(
          handout: handout,
          slide-level: 2,
          new-section-slide-fn: new-section-slide-fn,
          receive-body-for-new-section-slide-fn: true,
          slide-fn: slide,
          frozen-counters: (
            counter(figure.where(kind: "quarto-float-fig")),
          ),
        ),
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
        ..theme-config,
      )
      configured-theme({
        set text(size: fontsize * 1.25)
        body
      })
    }
    render(page-config: (margin: margin, header: none, footer: none))
  }

  let default-toc-slide(api, toc_title) = (api.slide)[
    #let title = if toc_title == none { "Outline" } else { toc_title }
    #heading(outlined: false, title)
    #set text(size: 2em)
    #(api.toolbox.all-sections)((sections, current) => {
      sections.join(linebreak())
    })
  ]

  let default-section-slide(api, name) = (api.slide)(
    config: touying.config-page(header: [#name]),
    [
      #align(horizon)[
        #text(size: 4em)[#strong(name)]
        #(api.toolbox.register-section)(name)
      ]
    ],
  )

  (
    toolbox: toolbox,
    api: backend-api,
    slide: slide,
    focus-slide: selected.focus-slide,
    last-slide: selected.last-slide,
    pause: pause,
    item-by-item: item-by-item,
    slide-number: slide-number,
    later: later,
    speaker-note: speaker-note,
    setup: setup,
    apply: apply,
    render-section: render-section,
    render-slide: render-slide,
    default-toc-slide: default-toc-slide,
    default-section-slide: default-section-slide,
  )
}
