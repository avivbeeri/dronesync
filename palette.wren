import "graphics" for Color
import "core/display" for Display
var Palette = [
  Display.bg,
  Display.fg,
  Color.hex("#444444"), // - gray for dim floor

// UI palette - swappable!
  Color.hex("#ffe8cf"), // - cream
  Color.hex("#df904f"), // - orange
  Color.hex("#af2850"), // - red
  Color.hex("#792BE0"), // - purple
]
var PAL = Palette


// TODO: Color map based on use, for easy switching
