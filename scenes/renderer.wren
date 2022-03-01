import "graphics" for Canvas
import "core/scene" for Scene, View
import "core/display" for Display
import "./palette" for PAL
import "./entities" for PlayerEntity

class WorldRenderer is View {
  construct new(parent, ctx) {
    super(parent)
    _ctx = ctx
  }

  update() {

  }

  process(event) {
    super.process(event)
  }

  draw() {
    var mapHeight = 45
    var mapWidth = 80
    var player = _ctx.getEntityByTag("player")
    var tileWidth = 6
    var yOff = 2
    var xOff = 0
    var tileHeight = 7

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
      Canvas.rectfill(xOff + entity.pos.x * tileWidth, yOff + entity.pos.y * tileHeight, tileWidth - 1, tileHeight - 1, Display.bg)
      if (entity is PlayerEntity) {
        Canvas.print("@", xOff + entity.pos.x * tileWidth, yOff +  entity.pos.y * tileHeight, Display.fg)
      } else {
        Canvas.print(entity.name[0], xOff + entity.pos.x * tileWidth, yOff + entity.pos.y * tileHeight, Display.fg)
      }
    }

  }

}
