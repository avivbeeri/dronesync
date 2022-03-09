import "graphics" for Color
import "core/display" for Display

// UI palette - swappable!
var Palette = [
  Color.hex("#000000"), // -
  Color.hex("#000000"), // -
  Color.hex("#666666"), // - gray for dim floor
  Color.hex("#222222"), // - darker gray for dim floor
  Color.hex("#AAAAAA"), // white
  Color.hex("#FFCC00"), // yellow
  Color.hex("#BB0101"), // red
  Color.hex("#792BE0"), // purple
  Color.hex("#ADADFF"), // blue
  Color.hex("#079300"), // green
  Color.hex("#FF1FD6"), // magenta
  Color.hex("#26D7CE"), // cyan
  Color.hex("#040404"), // black
]

var Crayon = [
  Color.hex("#000000"),
  Color.hex("#000000"),
  Color.hex("#717171"),
  Color.hex("#292929"),
  Color.hex("#ffffff"),
  Color.hex("#fff341"),
  Color.hex("#BB0101"), // red
  Color.hex("#a14ff1"),
  Color.hex("#2e608e"),
  Color.hex("#49dc41"),
  Color.hex("#FF1FD6"), // magenta
  Color.hex("#3bccf8"),

  Color.hex("#5d2540"),
  Color.hex("#672c26"),
  Color.hex("#ff752a"),
  Color.hex("#6f5a1d"),
  Color.hex("#215a39"),
  Color.hex("#2b2b63"),
]
var PAL = Crayon

// TODO: Color map based on use, for easy switching
