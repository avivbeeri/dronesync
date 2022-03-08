import "graphics" for Canvas
import "input" for Mouse

import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config

import "./palette" for PAL
import "./views/window" for LogWindow, InventoryWindow

class StatusBar is View {
  construct new(parent, ctx) {
    super(parent)
    _ctx = ctx
    _buttons = [
    {
      "label": "Inventory",
      "top": 2,
      "height": 12,
      "hover": false,
      "window": InventoryWindow,
      "windowId": "inventory"
    },
    {
      "label": "Logs",
      "top": 2,
      "height": 12,
      "hover": false,
      "window": LogWindow,
      "windowId": "log"
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
    if (player) {
      _hp = player["stats"]["hp"]
      _maxHp = player["stats"]["hpMax"]
    }

    var click = Mouse["left"].justPressed
    var pos = Mouse.pos
    for (button in _buttons) {
      if (pos.x >= button["left"]&& pos.x < button["left"]+ button["width"]&& pos.y >= button["top"]&& pos.y < button["top"] + button["height"]) {
        button["hover"] = true
        if (click) {
          if (!this.top.store.state["window"][button["windowId"]]) {
            this.top.store.dispatch({ "type": "window", "mode": "open", "id": button["windowId"] })
            parent.addViewChild(button["window"].new(parent, _ctx))
          } else {
            this.top.store.dispatch({ "type": "window", "mode": "close", "id": button["windowId"] })
          }
        }
      } else {
        button["hover"] = false
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
    Canvas.print("HP: %(_hp) / %(_maxHp)", 4, 4, Display.fg)


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

