import "graphics" for Canvas
import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config
import "./palette" for PAL
import "./entities/player" for PlayerEntity
import "./entities/drone" for DroneEntity

#!inject
class WorldRenderer is View {
  construct new(parent, ctx, x, y) {
    super(parent)
    _ctx = ctx
    _x = x
    _y = y
    _selection = []
    parent.top.store.subscribe {
      _selection = parent.top.store.state["selection"]
    }
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

    Canvas.offset(_x + (Canvas.width - (tileWidth*mapWidth)) / 2, _y + (Canvas.height - (tileHeight * mapHeight)) / 2)

    var player = _ctx.getEntityByTag("player", true)
    // var xOff = (Canvas.width - 8 - 12) / 2 + 1
    // Canvas.offset(xOff - player.pos.x * 8, 20 - player.pos.y * 8)
    for (y in 0...mapHeight) {
      for (x in 0...mapWidth) {
        var tile = _ctx.map[x, y]
        if (tile["visible"] == "unknown") {
          continue
        }
        var seen = tile["visible"] == "visible"
        if (tile["kind"] == "floor") {
          Canvas.print(".", x * tileWidth, y * tileHeight, seen ? PAL[2] : PAL[3])
        }
        if (tile["kind"] == "wall") {
          Canvas.print("#", x * tileWidth, y * tileHeight, seen ? Display.fg : PAL[3])
        }
        if (tile["kind"] == "goal") {
          var color = seen ? Display.fg : PAL[3]
          if (_ctx.parent["objective"]) {
            color = seen ? PAL[9] : PAL[3]
          }
          Canvas.print("$", x * tileWidth, y * tileHeight, color)
        }
        if (tile["kind"] == "exit") {
          Canvas.print(">", x * tileWidth, y * tileHeight, seen ? Display.fg : PAL[3])
        }
        if (tile["kind"] == "door") {
          Canvas.rectfill(x * tileWidth, y * tileHeight, tileWidth, tileHeight, Display.bg)
          Canvas.print("1", x * tileWidth, y * tileHeight, seen ? Display.fg : PAL[3])
        }
      }
    }
    for (entity in _ctx.entities) {
      // TODO: handle larger entities
      var tile = _ctx.map[entity.pos]
      if (tile["visible"] != "visible") {
        continue
      }
      var color = Display.bg
      if (entity.has("stunTimer") && entity["stunTimer"] > 0) {
        color = PAL[4]
      }
      Canvas.rectfill(entity.pos.x * tileWidth, entity.pos.y * tileHeight, tileWidth - 1, tileHeight - 1, color)
      if (entity is PlayerEntity) {
        Canvas.print("@", entity.pos.x * tileWidth,  entity.pos.y * tileHeight, player["active"] ? PAL[7] : PAL[8])
      } else if (entity is DroneEntity) {
        var color = PAL[7]
        if (player) {
          color = !player["active"] ? PAL[7] : PAL[8]
        }
        Canvas.print("D", entity.pos.x * tileWidth,  entity.pos.y * tileHeight, color)
      } else {
        var symbol = entity.has("symbol") ? entity["symbol"] : entity.name[0]
        var color = Display.fg
        if (entity["state"] == "alert") {
          color = PAL[6]
        } else if (entity["awareness"] > 0)  {
          color = PAL[5]
        }
        Canvas.print(symbol, entity.pos.x * tileWidth, entity.pos.y * tileHeight, color)
      }
    }

    for (tile in _selection) {
      Canvas.rect(tile.x * tileWidth, tile.y * tileHeight, tileWidth, tileHeight, PAL[10])
    }

    Canvas.offset()
  }

}
