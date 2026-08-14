#let speaker-note(text) = {
  let text = if type(text) == str {
    text
  } else if type(text) == content and text.func() == raw {
    text.text.trim()
  } else {
    panic("A note must either be a string or a raw block")
  }
  [#metadata((t: "Note", v: text)) <pdfpc>]
}
#let config(
  duration-minutes: none,
  start-time: none,
  end-time: none,
  last-minutes: none,
  note-font-size: none,
  disable-markdown: false,
  default-transition: none,
) = {
  if duration-minutes != none {
    [#metadata((t: "Duration", v: duration-minutes)) <pdfpc>]
  }

  let time-config(time, message, tag) = {
    let value = if type(time) == datetime {
      time.display("[hour padding:zero repr:24]:[minute padding:zero]")
    } else if type(time) == str {
      time
    } else {
      panic(message + " must be a datetime or an HH:MM string")
    }
    [#metadata((t: tag, v: value)) <pdfpc>]
  }

  if start-time != none {
    time-config(start-time, "Start time", "StartTime")
  }
  if end-time != none {
    time-config(end-time, "End time", "EndTime")
  }
  if last-minutes != none {
    [#metadata((t: "LastMinutes", v: last-minutes)) <pdfpc>]
  }
  if note-font-size != none {
    [#metadata((t: "NoteFontSize", v: note-font-size)) <pdfpc>]
  }

  [#metadata((t: "DisableMarkdown", v: disable-markdown)) <pdfpc>]

  if default-transition != none {
    let angle(direction) = if direction == ltr {
      "0"
    } else if direction == rtl {
      "180"
    } else if direction == ttb {
      "90"
    } else if direction == btt {
      "270"
    } else {
      panic("angle must be a direction (ltr, rtl, ttb, or btt)")
    }
    let transition = (
      default-transition.at("type", default: "replace")
      + ":" + str(default-transition.at("duration-seconds", default: 1))
      + ":" + angle(default-transition.at("angle", default: rtl))
      + ":" + default-transition.at("alignment", default: "horizontal")
      + ":" + default-transition.at("direction", default: "outward")
    )
    [#metadata((t: "DefaultTransition", v: transition)) <pdfpc>]
  }
}
