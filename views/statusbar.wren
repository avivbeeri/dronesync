import "graphics" for Canvas
import "input" for Mouse

import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config

import "./palette" for PAL
import "./views/window" for LogWindow

class StatusBar is View {
  construct new(parent, ctx) {
    super(parent)
    System.print(top)
    _ctx = ctx
  }

  update() {
    super.update()
    var player = _ctx.getEntityByTag("player", true)
    if (player) {
      _hp = player["stats"]["hp"]
      _maxHp = player["stats"]["hpMax"]
    }

    if (Mouse["left"].justPressed) {
      System.print("click")
      var pos = Mouse.pos
      var width = 8 * (6)
      var height = 12
      var left = Canvas.width -  width
      var top = 2
      if (pos.x >= left && pos.x < left + width && pos.y >= top && pos.y < top + height) {
        if (this.top.store.state["logOpen"] == false) {
          this.top.store.dispatch({ "type": "open" })
          parent.addViewChild(LogWindow.new(parent, _ctx))
        } else {
          this.top.store.dispatch({ "type": "close" })
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
    Canvas.print("HP: %(_hp) / %(_maxHp)", 4, 4, Display.fg)


    // Draw a button
    var width = 8 * (6)
    var height = 12
    var left = Canvas.width -  width
    var top = 2
    Canvas.rectfill(left, top, 8 * width, height, Display.fg)
    Canvas.print("Logs", left + 8, top  + 2, Display.bg)
  }
}

