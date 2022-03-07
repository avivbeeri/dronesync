import "graphics" for Color
import "core/display" for Display

// UI palette - swappable!
var Palette = [
  Display.bg,
  Display.fg,
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
var PAL = Palette


// TODO: Color map based on use, for easy switching
