import "graphics" for Canvas
import "math" for Vec, M
import "input" for Mouse, Keyboard

import "core/config" for Config
import "core/display" for Display
import "core/scene" for Scene, View

import "./palette" for PAL
import "./inputs" for InputAction
import "core/rng" for Seed



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
    _closable = false

    z = 1
  }

  title { _title }
  title=(v) { _title = v }
  closable { _closable }
  closable=(v) { _closable = v }
  ctx { _ctx }

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

    if (pos.x >= x - 4 && pos.x < x + width  + 8 && pos.y >= y - 10 && pos.y < y) {
      Mouse.cursor = "hand"
      if (Mouse["left"].justPressed) {
        _held = true
        _lastMouse = pos
      }
    } else {
      Mouse.cursor = "arrow"
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
    if (_closable) {
      Canvas.print("X", _rect.w - 8, -9, color)
    }
    Canvas.clip(_rect.x, _rect.y, _rect.w, _rect.z)
    // Draw window contents
    drawContent()
    // reset
    Canvas.clip()
    Canvas.offset()
  }
}

class QueryWindow is Window {
  construct new(parent, ctx) {
    // Assuming default font
    super(parent, ctx, Vec.new(8 * 20, 8 * 6))
    title = "Query"
    closable = false

    _config = top.store.state["query"]["config"]
    _area = Display.print(_config["message"], {
      "align": "center",
      "size": Vec.new(Canvas.width / 2, Canvas.height / 2),
      "overflow": true
    })

    width = _config["message"].count * 8 + 16
    height = (_config["options"].count + 2) * 8 + _area.y
    width = _area.x + 16

    y = (Canvas.height - height) / 2
    x = (Canvas.width - width) / 2
  }

  update() {
    super.update()
    var pos = Mouse.pos
    var activate = false
    _hover = -1
    if (Mouse["left"].justPressed) {
      if (pos.x >= x && pos.x < x + width && pos.y >= y && pos.y < y + height) {
        _hover = (((pos.y) - (y + _area.y + 8)) / 8).floor
        _hover = M.max(-1, _hover)
      }
      activate = true
    } else {
      for (key in 0..9) {
        var i = (key + 9) % 10
        if ((Keyboard[key.toString].justPressed || (InputAction.shift.down && Keyboard["keypad %(key)"].justPressed)) && i < _config["options"].count) {
          _hover = i
          activate = true
        }
      }
    }
    activate = activate && _hover >= 0 && _hover < _config["options"].count
    if (activate) {
      top.store.dispatch({ "type": "query", "result": _config["options"][_hover][1] })
      parent.removeViewChild(this)
    }
    // Accept/fail - should become dynamic options
    if (InputAction.confirm.firing) {
      top.store.dispatch({ "type": "query", "result": "confirm" })
      parent.removeViewChild(this)
    } else if (InputAction.cancel.firing) {
      top.store.dispatch({ "type": "query", "result": "cancel" })
      parent.removeViewChild(this)
    }
  }

  drawContent() {
    super.drawContent()
    var y = 4
    Display.print(_config["message"], {
      "align": "center",
      "position": Vec.new(0, y),
      "color": Display.fg,
      "size": _area,
      "overflow": true
    })
    y = _area.y + 8
    var i = 0
    for (option in _config["options"]) {
      if (i == _hover) {
        Canvas.rectfill(0, y, width, 8, PAL[6])
      }
      Canvas.print("%(i+1)) %(option[0])", 0, y, Display.fg)
      y = y + 8
      i = i + 1
    }
  }
}

class InventoryWindow is Window {
  construct new(parent, ctx) {
    // Assuming default font
    super(parent, ctx, Vec.new(8 * 20, 8 * 6))
    title = "Inventory"
    closable = true
    y = 32
    x = Canvas.width - width - 8
    restorePref("inventory")
    var Sub
    _allowInput = true
    Sub = top.store.subscribe {
      _allowInput = (top.store.state["mode"] == "play")

      if (!top.store.state["window"]["inventory"]) {
        onClose()
        parent.removeViewChild(this)
        Sub.call()
      }
    }

    _hover = -1
    _contents = []
  }

  update() {
    super.update()
    var player = ctx.getEntityByTag("player", true)
    if (player) {
      var inventory = player["inventory"]
      _contents = []
      for (entry in inventory) {
        _contents.add(entry)
      }
    }
    if (_allowInput) {
      var pos = Mouse.pos
      _hover = -1
      if (pos.x >= x && pos.x < x + width && pos.y >= y && pos.y < y + height) {
        _hover = ((((pos.y) - (y+4))) / 8).floor
        _hover = M.max(0, _hover)
      }
      var activate = Mouse["left"].justPressed
      for (key in 0..9) {
        var i = (key + 9) % 10
        if ((Keyboard[key.toString].justPressed || (InputAction.shift.down && Keyboard["keypad %(key)"].justPressed)) && i < _contents.count) {
          _hover = i
          activate = true
          break
        }
      }
      if (activate && _hover != -1 && _hover < _contents.count) {
        this.top.store.dispatch({ "type": "item", "data": _contents[_hover] })
      }
    }
  }
  onRequestClose() {
    this.top.store.dispatch({ "type": "window", "mode": "close", "id": "inventory" })
  }
  onDrop() {
    storePref("inventory")
  }

  drawContent() {
    super.drawContent()
    var y = 4
    var i = 0
    for (entry in _contents) {
      var color = Display.fg
      var bg = PAL[0]
      if (i == _hover) {
        color = PAL[0]
        bg = PAL[6]
      }

      Canvas.rectfill(0, y-2, width, 8, bg)
      var name = entry["displayName"]
      var label = name
      if (i < 10) {
        label = "%(i+1)) %(label)"
      }
      Canvas.print(label, 2, y, color, "m3x6")
      if (entry["quantity"]) {
        if (entry["binary"]) {
          Canvas.rectfill(width - 14, y-1, 6, 7, entry["quantity"] == 0 ? Display.bg : PAL[5])
          Canvas.rect(width - 14, y-1, 6, 6, color)
        } else {
          var quantity = "x" + entry["quantity"].toString
          Canvas.print(quantity, width - (quantity.count * 4) - 7, y, color, "m3x6")
        }
      }
      y = y + 8
      i = i + 1
    }
  }
}

class LogWindow is Window {
  construct new(parent, ctx) {
    // Assuming default font
    super(parent, ctx, Vec.new(8 * 40, 8 * 3))
    y = Canvas.height - height - 16
    restorePref("log")
    title = "Log"
    closable = true
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
        Canvas.print(line, 2, y, Display.fg, "m3x6")
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
    title = "Mission Report"
    height = 8 * 6
    width = Canvas.width * 0.5
    x = (Canvas.width - width) / 2
    y = (Canvas.height - height) / 2
  }
  update() {
    if (InputAction.confirm.justPressed) {
      top.game.push(PlayScene, [])
    }
  }
  drawContent() {
    var text = "You died"
    var y = 12
    Canvas.print(text, (width - text.count * 8) / 2, y, Display.fg)
    text = "Press Enter to play again."
    y = 28
    Canvas.print(text, (width - text.count * 8) / 2, y, Display.fg)
  }
}
class ScoreWindow is GameEndWindow {
  construct new(parent, ctx, message) {
    super(parent, ctx, message)
    var v = ctx["time"]
    v = ctx["minDistance"]
    _score = [

      (ctx["objective"] ?
        [ "Objective complete", 150 ] :
        [ "Objective abandoned", 0 ]),
      [ "Time", (M.max(0, ctx["time"] - ctx["minDistance"]) / 200).floor * 10, -1, "-" ],
      [ "Alerts", ctx["alerts"] * 17, -1, "-"],
    ]
    _total = _score.reduce(0) {|total, line|
      return total + line[1] * (line.count > 2 ? line[2] : 1)
    }

    height = _score.count * 8 + 68
    width = Canvas.width * 0.75
    x = (Canvas.width - width) / 2
    y = (Canvas.height - height) / 2

    z = 2
    title = "Mission Report"
  }

  drawContent() {
    var y = 10
    var margin = 2 + width / 4
    var text = "Seed: %(Seed)"
    Canvas.print(text, margin, y, Display.fg)
    y = y + 16
    for (line in _score) {
      var text = line[0]
      var modifier = line.count > 3 ? line[3] : "+"
      var value = "%(modifier)%(line[1])"
      Canvas.print(text, margin, y, Display.fg)
      Canvas.print(value, width - margin - value.count * 8, y, Display.fg)
      y = y + 8
    }
    y = y + 8
    text = "Total: %(_total)"
    Canvas.print(text, width - margin - text.count * 8, y, Display.fg)
    y = y + 16

    text = "Press Enter to play again."
    Canvas.print(text, (width - text.count * 8) / 2, y, Display.fg)
  }
}

import "./scenes/play" for PlayScene
