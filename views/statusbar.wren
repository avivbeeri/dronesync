import "graphics" for Canvas

import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config

import "./palette" for PAL


#!inject
class StatusBar is View {
  construct new(parent, ctx) {
    super(parent)
    _ctx = ctx
  }

  update() {
    var player = _ctx.getEntityByTag("player", true)
    if (player) {
      _hp = player["stats"]["hp"]
      _maxHp = player["stats"]["hpMax"]
    }
  }
  process(event) {}
  draw() {
    var mapHeight = Config["map"]["height"]
    var mapWidth = Config["map"]["width"]
    var tileWidth = Config["map"]["tileWidth"]
    var tileHeight = Config["map"]["tileHeight"]

    for (x in 0...(Canvas.width / tileWidth).ceil) {
      Canvas.print("-", x * tileWidth, 14, Display.fg)
    }
    Canvas.print("HP: %(_hp) / %(_maxHp)", 4, 4, Display.fg)
  }
}

