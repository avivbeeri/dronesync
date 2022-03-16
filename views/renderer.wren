import "graphics" for Canvas, Color
import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config
import "./palette" for PAL
import "./entities/player" for PlayerEntity
import "./entities/drone" for DroneEntity
import "util" for GridWalk

var DEBUG = false

#!inject
class WorldRenderer is View {
  construct new(parent, ctx, x, y) {
    super(parent)
    _ctx = ctx
    _x = x
    _y = y
    _selection = []
    _range = []
    _center = null
    _valid = true
    parent.top.store.subscribe {
      var state = parent.top.store.state["selection"]
      _selection = state["tiles"]
      _center = state["center"]
      _range = state["range"]
      _valid = state["valid"]
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
          var symbol = "."
          var offset = -2
          var color = PAL[2]
          if (tile["item"]) {
            if (tile["item"] == "coin") {
              symbol = String.fromCodePoint(0x00B0)
              offset = 3
              color = PAL[15]
            } else if (tile["item"] == "smokebomb") {
              symbol = String.fromCodePoint(0x00F8)
              offset = 0
              color = PAL[15]
            }
          }
          if (!tile["activeEffects"].isEmpty) {
            var effect = tile["activeEffects"][0]
            if (effect["id"] == "smoke") {
              color = PAL[8]
              symbol = null
            }
          }
          color = seen ? color : PAL[3]
          if (symbol) {
            Canvas.print(symbol, x * tileWidth, y * tileHeight + offset, color)
          } else {
            Canvas.rectfill(x * tileWidth, y * tileHeight, tileWidth, tileHeight, color)
          }
        }
        if (tile["kind"] == "wall") {
          Canvas.print("#", x * tileWidth, y * tileHeight, seen ? Display.fg : PAL[3])
        }
        if (tile["kind"] == "crate") {
          Canvas.rectfill(x * tileWidth, y * tileHeight, tileWidth, tileHeight, seen ? PAL[13] : PAL[3])
          Canvas.print(tile["symbol"], x * tileWidth, y * tileHeight, seen ? PAL[12] : PAL[3])
        }
        if (tile["kind"] == "goal") {
          var color = seen ? PAL[15] : PAL[3]
          if (_ctx.parent["objective"]) {
            color = seen ? PAL[9] : PAL[3]
          }
          Canvas.print("$", x * tileWidth, y * tileHeight, color)
        }
        if (tile["kind"] == "exit") {
          Canvas.print(">", x * tileWidth, y * tileHeight, seen ? Display.fg : PAL[3])
        }
        if (tile["kind"] == "door") {
          var color = Display.fg
          if (tile["locked"] || tile["level"] > 0) {
            color = PAL[7]
          }
          color = PAL[15]
          Canvas.rectfill(x * tileWidth, y * tileHeight, tileWidth - 1, tileHeight - 1, seen ? color : PAL[3])
          Canvas.print("+", x * tileWidth, y * tileHeight, PAL[0])
        }
      }
    }
    for (tile in _range) {
      // Canvas.rectfill(tile.x * tileWidth, tile.y * tileHeight, tileWidth, tileHeight, PAL[2])
      Canvas.rect(tile.x * tileWidth - 1, tile.y * tileHeight - 1, tileWidth+1, tileHeight+1, PAL[2])
    }
    if (_valid) {
      for (tile in _selection) {
        Canvas.rectfill(tile.x * tileWidth, tile.y * tileHeight, tileWidth - 1, tileHeight - 1, PAL[6])
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

      // TODO: figure out what background color to use here
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
        } else if (entity["state"] == "investigate" || entity["state"] == "investigate-noise") {
          color = PAL[14]
        } else if (entity["awareness"] > 0)  {
          color = PAL[5]
        }
        Canvas.print(symbol, entity.pos.x * tileWidth, entity.pos.y * tileHeight, color)

        if (DEBUG) {
          // Debug rendering
          if (entity["los"]) {
            var points = GridWalk.getLine_Bresenham(entity.pos, player.pos)
            for (point in points) {
              if (_ctx.map[point]["blockSight"]) {
                break
              }
              Canvas.print("*", point.x * tileWidth, point.y * tileHeight, Color.yellow)
            }
            points = GridWalk.getLine_Interpolate(entity.pos, player.pos)
            for (point in points) {
              if (_ctx.map[point]["blockSight"]) {
                break
              }
              Canvas.print("*", point.x * tileWidth, point.y * tileHeight, Color.green)
            }
            Canvas.rectfill(entity.pos.x * tileWidth, entity.pos.y * tileHeight, tileWidth - 1, tileHeight - 1, Display.bg)
            Canvas.print(symbol, entity.pos.x * tileWidth, entity.pos.y * tileHeight, entity["los"] ? Color.orange : Display.fg)
          }
        }
      }
    }
    if (_center) {
      var tile = _center
      if (_valid) {
        Canvas.rectfill(tile.x * tileWidth, tile.y * tileHeight, tileWidth - 1, tileHeight - 1, PAL[2])
      } else {
        Canvas.rectfill(tile.x * tileWidth + 1, tile.y * tileHeight + 1, tileWidth - 3, tileHeight - 3, PAL[6])
      }
    }

    var entity = _ctx.getEntityByTag("player")
    if (entity) {
      var tile = _ctx.map[entity.pos]
      var color = Display.bg

      // TODO: figure out what background color to use here
      Canvas.rectfill(entity.pos.x * tileWidth, entity.pos.y * tileHeight, tileWidth - 1, tileHeight - 1, color)

      if (entity is PlayerEntity) {
        Canvas.print("@", entity.pos.x * tileWidth,  entity.pos.y * tileHeight, player["active"] ? PAL[7] : PAL[8])
      }
    }


    Canvas.offset()
  }

}
