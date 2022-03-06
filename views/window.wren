import "graphics" for Canvas
import "math" for Vec

import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config

import "./palette" for PAL
import "./inputs" for InputAction



#!inject
class Window is View {
  construct new(parent, ctx, size) {
    super(parent)
    _ctx = ctx
    _rect = Vec.new()

    // Size x/y
    _rect.w = size.x
    _rect.z = size.y

    // Pos - centered
    _rect.x = (Canvas.width - _rect.w) / 2
    _rect.y = (Canvas.height - _rect.z) / 2

    z = 1
  }

  width { _rect.w }
  height { _rect.z }

  update() {
    super.update()
  }
  process(event) {
    super.process(event)
  }
  drawContent() {
    super.draw()
  }

  draw() {
    Canvas.offset(_rect.x, _rect.y)
    // Canvas.clip(_rect.x - 4, _rect.y-4, _rect.w + 8, _rect.z + 8)
    // Draw window decorations
    Canvas.rectfill(-4, -4, _rect.w + 8, _rect.z + 8, Display.bg)
    Canvas.rect(-1, -1, _rect.w + 2, _rect.z + 2, Display.fg)
    Canvas.rect(-3, -3, _rect.w + 6, _rect.z + 6, Display.fg)
    Canvas.rectfill(-2, -3, _rect.w + 4, 2, PAL[6])
    Canvas.clip(_rect.x, _rect.y, _rect.w, _rect.z)
    // Draw window contents
    drawContent()
    // reset
    Canvas.clip()
    Canvas.offset()
  }
}

class LogWindow is Window {
  construct new(parent, ctx) {
    // Assuming default font
    super(parent, ctx, Vec.new(8 * 40, 8 * 3))
    var Sub
    Sub = top.store.subscribe {

      if (top.store.state["logOpen"] == false) {
        parent.removeViewChild(this)
        Sub.call()
      }
    }
  }

  update() {
    super.update()
    _text = top.log.getLast(3)
  }

  drawContent() {
    super.drawContent()
    var y = 1
    if (_text) {
      for (line in _text) {
        Canvas.print(line, 0, y, Display.fg, "m3x6")
        y = y + 8
      }
    }
  }
}

class MessageWindow is Window {
  construct new(parent, ctx, message) {
    // Assuming default font
    var width = (message.count+2) * 8
    super(parent, ctx, Vec.new(width, 16))
    _message = message
  }


  drawContent() {
    super.drawContent()
    Canvas.print(_message, 8, 4, Display.fg)
  }
}

class GameEndWindow is MessageWindow {
  construct new(parent, ctx, message) {
    super(parent, ctx, message)
    z = 2
  }

  update() {
    if (InputAction.confirm.justPressed) {
      top.game.push(PlayScene, [])
    }
  }
}

import "./scenes/play" for PlayScene
