import "graphics" for Canvas
import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config
import "./palette" for PAL

#!inject
class Tooltip is View {
  construct new(parent, text) {
    super(parent)
    _barTimer = 3 * 60
    _barText = text
  }

  update() {
    _barTimer = _barTimer - 1
    if (_barTimer <= 0) {
      parent.removeViewChild(this)
    }
  }

  process(event) {}

  draw() {
    if (_barTimer > 0) {
      Canvas.rectfill(0, Canvas.height - 9, Canvas.width, 9, Display.fg)
      Canvas.print(_barText, 0, Canvas.height - 8, Display.bg)
    }
  }
}

