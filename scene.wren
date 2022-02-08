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

import "./actions" for MoveAction

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
          "solid": x == y
        })
      }
    }
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
    } else {
      player.action = Action.none
    }
    _world.update()
  }

  draw() {
    Canvas.cls(Display.bg)
    for (y in 0...6) {
      for (x in 0...9) {
        var tile = _world.active.map[x, y]
        if (tile["solid"]) {
          Canvas.rectfill(x * 8, y * 8, 8, 8, Display.fg)
        }
      }
    }
    for (entity in _world.active.entities) {
      Canvas.rectfill(entity.pos.x * 8, entity.pos.y * 8, 8, 8, Display.bg)
      Canvas.print(entity.name[0], entity.pos.x * 8, entity.pos.y * 8, Display.fg)
    }
  }
}
