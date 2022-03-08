import "graphics" for Canvas
import "math" for Vec
import "input" for Mouse

import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config

import "./palette" for PAL
import "./inputs" for InputAction



#!inject
class Window is View {
  construct new(parent, ctx, size) {
    super(parent)
    if (!__pref) {
      __pref = {}
    }

    _ctx = ctx
    _rect = Vec.new()

    // Size x/y
    _rect.w = size.x
    _rect.z = size.y

    // Pos - centered
    _rect.x = (Canvas.width - _rect.w) / 2
    _rect.y = (Canvas.height - _rect.z) / 2
    _title = ""

    z = 1
  }

  title { _title }
  title=(v) { _title = v }

  x { _rect.x }
  x=(v) { _rect.x = v}
  y { _rect.y }
  y=(v) { _rect.y = v}
  width { _rect.w }
  width=(v) { _rect.w = v}
  height { _rect.z }
  height=(v) { _rect.z = v}

  update() {
    super.update()
    var pos = Mouse.pos
    if (pos.x >= x + width - 10 && pos.x < x + width && pos.y >= y - 10 && pos.y < y) {
      _hoverX = true
      if (Mouse["left"].justPressed) {
        // TODO: handle window ids for closing and opening stuff like this
        onRequestClose()
      }
      // TODO check click
    } else {
      _hoverX = false
    }

    if (Mouse["left"].justPressed && pos.x >= x - 4 && pos.x < x + width  + 8 && pos.y >= y - 10 && pos.y < y + height) {
      _held = true
      _lastMouse = pos
    }
    if (_held) {
      var diff = pos - _lastMouse
      x = x + diff.x
      y = y + diff.y
      _lastMouse = pos

      _held = Mouse["left"].down
      if (!_held) {
        onDrop()
      }
    }
  }
  onRequestClose() {}
  onClose() {}
  onDrop() {}
  storePref(label) {
    __pref[label] = _rect * 1
  }
  restorePref(label) {
    if (!__pref) {
      __pref = {}
    }
    if (__pref[label]) {
      _rect = __pref[label]
    }
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
    Canvas.rectfill(-4, -10, _rect.w + 8, 10, PAL[6])
    Canvas.print(_title, (_rect.w - _title.count * 8) / 2, -9, Display.fg)
    var color = PAL[4]
    if (_hoverX) {
      color = PAL[5]
    }
    Canvas.print("X", _rect.w - 8, -9, color)
    Canvas.clip(_rect.x, _rect.y, _rect.w, _rect.z)
    // Draw window contents
    drawContent()
    // reset
    Canvas.clip()
    Canvas.offset()
  }
}
class InventoryWindow is Window {
  construct new(parent, ctx) {
    // Assuming default font
    super(parent, ctx, Vec.new(8 * 20, 8 * 6))
    restorePref("inventory")
    title = "Inventory"
    var Sub
    Sub = top.store.subscribe {
      if (top.store.state["inventoryOpen"] == false) {
        parent.removeViewChild(this)
        Sub.call()
      }
    }
  }

  update() {
    super.update()
  }
  onDrop() {
    storePref("inventory")
  }

  drawContent() {
    super.drawContent()
  }
}

class LogWindow is Window {
  construct new(parent, ctx) {
    // Assuming default font
    super(parent, ctx, Vec.new(8 * 40, 8 * 3))
    restorePref("log")
    title = "Log"
    var Sub
    Sub = top.store.subscribe {

      if (!top.store.state["window"]["log"]) {
        onClose()
        parent.removeViewChild(this)
        Sub.call()
      }
    }
  }

  update() {
    super.update()
    _text = top.log.getLast(3)
  }
  onRequestClose() {
    this.top.store.dispatch({ "type": "window", "mode": "close", "id": "log" })
  }
  onDrop() {
    storePref("log")
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
