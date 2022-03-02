import "graphics" for Canvas
import "core/scene" for Scene, View
import "core/display" for Display

#!inject
class SleepAnimation is View {
  construct new() {
    _t = 2 * 60
  }

  update() {
    _t = _t - 1
    if (_t <= 0) {
      parent.removeViewChild(this)
    }
  }

  draw() {
    Canvas.cls(Display.fg)
    Canvas.print("Sleeping...", 0, 8, Display.bg, "m3x6")
    Canvas.print("Game was saved.", 0, Canvas.height - 7, Display.bg, "m3x6")
  }
}

