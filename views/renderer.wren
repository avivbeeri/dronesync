import "graphics" for Canvas
import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config
import "./palette" for PAL
import "./entities/player" for PlayerEntity

#!inject
class WorldRenderer is View {
  construct new(parent, ctx, x, y) {
    super(parent)
    _ctx = ctx
    _x = x
    _y = y
  }

  update() {

  }

  process(event) {
    super.process(event)
  }

  draw() {
    var mapHeight = Config["map"]["height"]
    var mapWidth = Config["map"]["width"]
    var tileWidth = Config["map"]["tileWidth"]
    var tileHeight = Config["map"]["tileHeight"]
    var yOff = _y + 2
    var xOff = _x + 0

    var player = _ctx.getEntityByTag("player")
    // var xOff = (Canvas.width - 8 - 12) / 2 + 1
    // Canvas.offset(xOff - player.pos.x * 8, 20 - player.pos.y * 8)
    for (y in 0...mapHeight) {
      for (x in 0...mapWidth) {
        var tile = _ctx.map[x, y]
        if (tile["kind"] == "floor") {
          Canvas.print(".", xOff + x * tileWidth + (tileWidth * 0.5).floor, yOff + y * tileHeight, PAL[2])
        }
        if (tile["kind"] == "wall") {
          Canvas.print("#", xOff + x * tileWidth, yOff + y * tileHeight, Display.fg)
        }
        if (tile["kind"] == "door") {
          Canvas.print("1", xOff + x * tileWidth, yOff + y * tileHeight, Display.fg)
          Canvas.rectfill(x * xOff + tileWidth, yOff + y * tileHeight, tileWidth, tileHeight, Display.bg)
        }
      }
    }
    for (entity in _ctx.entities) {
      var color = Display.bg
      if (entity.has("stunTimer") && entity["stunTimer"] > 0) {
        color = PAL[4]
      }
      Canvas.rectfill(xOff + entity.pos.x * tileWidth, yOff + entity.pos.y * tileHeight, tileWidth - 1, tileHeight - 1, color)
      if (entity is PlayerEntity) {
        Canvas.print("@", xOff + entity.pos.x * tileWidth, yOff +  entity.pos.y * tileHeight, PAL[6])
      } else {
        var symbol = entity.has("symbol") ? entity["symbol"] : entity.name[0]
        Canvas.print(symbol, xOff + entity.pos.x * tileWidth, yOff + entity.pos.y * tileHeight, Display.fg)
      }
    }

  }

}
