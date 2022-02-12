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

import "./actions" for MoveAction, SleepAction, SowAction, WaterAction

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
    var mapHeight = 12
    var mapWidth = 20
    for (y in 0...mapHeight) {
      for (x in 0...mapWidth) {
        var solid = x == 0 || y == 0 || x == mapWidth - 1 || y == mapHeight - 1
        map[x, y] = Tile.new({
          "solid": solid,
          "kind": solid ? "wall" : "floor"
        })
      }
    }
    map[4, 2] = Tile.new({
      "kind": "plant",
      "solid": false,
      "watered": false,
      "stage": 0,
      "age": 0
    })
    _world = World.new(strategy)
    _world.pushZone(Zone.new(map))
    var zone = _world.active
    var player = PlayerEntity.new()
    player.pos.x = 1
    player.pos.y = 1
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
      player.action = WaterAction.new(Vec.new(0, 0))
      // player.action = SleepAction.new()
    } else {
      player.action = Action.none
    }
    _world.update()
  }

  draw() {
    var xOffset = 2
    Canvas.cls(Display.bg)
    var player = _world.active.getEntityByTag("player")
    Canvas.offset(38 - player.pos.x * 8 - xOffset, 20 - player.pos.y * 8)
    for (dy in -3..3) {
      for (dx in -5..5) {
        var x = player.pos.x + dx
        var y = player.pos.y + dy
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
          // Canvas.circle(xOffset + x * 8  + 4, y * 8 + 4, tile["stage"], fg)
          Canvas.print(tile["stage"], xOffset + x * 8, y * 8, fg)
        }
      }
    }
    for (entity in _world.active.entities) {
      Canvas.rectfill(xOffset + entity.pos.x * 8, entity.pos.y * 8, 8, 8, Display.bg)
      Canvas.print(entity.name[0], xOffset + entity.pos.x * 8, entity.pos.y * 8, Display.fg)
    }
  }
}
