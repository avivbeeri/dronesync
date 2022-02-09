import "graphics" for Canvas
import "dome" for Window
import "input" for Keyboard
import "math" for Vec

import "core/action" for Action
import "core/scene" for Scene
import "core/display" for Display
import "core/world" for World, Zone
import "core/director" for ActionStrategy
import "core/map" for TileMap, Tile
import "core/entity" for Entity

import "./actions" for MoveAction, SleepAction, SowAction

class PlayerEntity is Entity {
  construct new() {
    super()
  }

  action { _action }
  action=(v) { _action = v }

  update() { _action }
}


class PlantScene is Scene {
  construct new(args) {
    super(args)
    var scale = 6
    Window.resize(Canvas.width * scale, Canvas.height * scale)
    var strategy = ActionStrategy.new()
    var map = TileMap.init()
    for (y in 0...6) {
      for (x in 0...9) {
        map[x, y] = Tile.new({
          "solid": x == y,
          "kind": x == y ? "wall" : "floor"
        })
      }
    }
    map[4, 2] = Tile.new({
      "kind": "plant",
      "solid": true,
      "watered": false,
      "stage": 1
    })
    _world = World.new(strategy)
    _world.pushZone(Zone.new(map))
    var zone = _world.active
    var player = PlayerEntity.new()
    zone.addEntity("player", player)
  }

  update() {
    var player = _world.active.getEntityByTag("player")
    if (Keyboard["right"].justPressed) {
      player.action = MoveAction.new(Vec.new(1, 0))
    } else if (Keyboard["left"].justPressed) {
      player.action = MoveAction.new(Vec.new(-1, 0))
    } else if (Keyboard["up"].justPressed) {
      player.action = MoveAction.new(Vec.new(0, -1))
    } else if (Keyboard["down"].justPressed) {
      player.action = MoveAction.new(Vec.new(0, 1))
    } else if (Keyboard["return"].justPressed) {
      player.action = SowAction.new(Vec.new(0, 0))
    } else if (Keyboard["space"].justPressed) {
      player.action = SleepAction.new()
    } else {
      player.action = Action.none
    }
    _world.update()
  }

  draw() {
    var xOffset = 2
    Canvas.cls(Display.bg)
    for (y in 0...6) {
      for (x in 0...9) {
        var tile = _world.active.map[x, y]
        if (tile["kind"] == "wall") {
          Canvas.rectfill(xOffset + x * 8  + 1, y * 8 + 1, 6, 6, Display.fg)
        }
        if (tile["kind"] == "plant") {
          var bg = Display.bg
          var fg = Display.fg
          if (tile["watered"]) {
            var temp = bg
            bg = fg
            fg = temp
          }
          Canvas.rectfill(xOffset + x * 8, y * 8, 8, 8, bg)
          Canvas.circle(xOffset + x * 8  + 4, y * 8 + 4, tile["stage"], fg)
        }
      }
    }
    for (entity in _world.active.entities) {
      Canvas.rectfill(xOffset + entity.pos.x * 8, entity.pos.y * 8, 8, 8, Display.bg)
      Canvas.print(entity.name[0], xOffset + entity.pos.x * 8, entity.pos.y * 8, Display.fg)
    }
  }
}
