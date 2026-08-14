#let load-backend(name) = {
  if name == "polylux" {
    import "backends/polylux.typ" as backend
    backend
  } else if name == "touying" {
    import "backends/touying.typ" as backend
    backend
  } else {
    panic("Unsupported backend: " + name)
  }
}
