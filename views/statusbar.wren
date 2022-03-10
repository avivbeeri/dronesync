import "graphics" for Canvas
import "input" for Mouse, Keyboard
import "math" for M

import "core/config" for Config
import "core/display" for Display
import "core/scene" for Scene, View

import "./palette" for PAL
import "./views/window" for LogWindow, InventoryWindow

class StatusBar is View {
  construct new(parent, ctx) {
    super(parent)
    _ctx = ctx
    _range = 0
    _buttons = [
    {
      "label": "Logs",
      "top": 2,
      "height": 12,
      "hover": false,
      "window": LogWindow,
      "windowId": "log",
      "shortcut": "o"
    },
    {
      "label": "Inventory",
      "top": 2,
      "height": 12,
      "hover": false,
      "window": InventoryWindow,
      "windowId": "inventory",
      "shortcut": "i"
    }
    ]
    var left = Canvas.width
    for (button in _buttons) {
      button["width"] = 8 * (button["label"].count + 2)
      left = button["left"] = left - button["width"]
      left = left - 8
    }
  }

  update() {
    super.update()
    var player = _ctx.getEntityByTag("player", true)
    var drone = _ctx.getEntityByTag("drone", true)
    if (player) {
      _hp = player["stats"]["hp"]
      _maxHp = player["stats"]["hpMax"]
      _range = M.mid(0, 1 - (player.pos - drone.pos).length / drone["range"], 1)
    }

    var click = Mouse["left"].justPressed
    var pos = Mouse.pos
    for (button in _buttons) {
      button["hover"] = false
      var shortcutDown = false
      if (button["shortcut"]) {
        shortcutDown = Keyboard[button["shortcut"]].justPressed
        button["hover"] = Keyboard[button["shortcut"]].down
      }
      if (shortcutDown || (pos.x >= button["left"]&& pos.x < button["left"]+ button["width"]&& pos.y >= button["top"]&& pos.y < button["top"] + button["height"])) {
        button["hover"] = true
        if (shortcutDown || click) {
          if (!this.top.store.state["window"][button["windowId"]]) {
            this.top.store.dispatch({ "type": "window", "mode": "open", "id": button["windowId"] })
            parent.addViewChild(button["window"].new(parent, _ctx))
          } else {
            this.top.store.dispatch({ "type": "window", "mode": "close", "id": button["windowId"] })
          }
        }
      }
    }
  }

  process(event) {}

  draw() {
    var mapHeight = Config["map"]["height"]
    var mapWidth = Config["map"]["width"]
    var tileWidth = Config["map"]["tileWidth"]
    var tileHeight = Config["map"]["tileHeight"]

    for (x in 0...(Canvas.width / tileWidth).ceil) {
      Canvas.print("=", x * tileWidth, 14, Display.fg)
    }
    Canvas.print("HP: %(_hp) / %(_maxHp)", 32, 4, Display.fg)
    var color = Display.fg
    var symbol = "█"
    color = PAL[9]
    if (_range < 0.75) {
      symbol = "▆"
      color = PAL[9]
    }
    if (_range < 0.4) {
      symbol = "▄"
      color = PAL[5]
    }
    if (_range < 0.1) {
      symbol = "▂"
      color = PAL[6]
    }
    if (_range == 0) {
      symbol = " "
      color = PAL[6]
    }

    Canvas.print("[█]", 4, 4, PAL[3])
    Canvas.print("[ ]", 4, 4, Display.fg)
    Canvas.print(" %(symbol) ", 4, 4, color)


    // Draw a button
    var width = 8 * (6)
    var height = 12
    var left = Canvas.width -  width
    var top = 2
    for (button in _buttons) {
      var left = button["left"] + (button["width"] - (button["label"].count * 8)) / 2
      if (button["hover"]) {
        Canvas.rect(button["left"], button["top"], button["width"], button["height"], Display.fg)
      } else {
        Canvas.rectfill(button["left"], button["top"], button["width"], button["height"], Display.fg)
      }
      Canvas.print(button["label"], left, button["top"] + 2, button["hover"] ? Display.fg : Display.bg)
    }
  }
}

