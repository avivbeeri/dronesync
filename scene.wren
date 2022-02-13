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
    _toolSelected = 1
    for (y in -mapHeight...mapHeight) {
      for (x in -mapWidth...mapWidth) {
        var solid = x == -mapWidth || y == -mapHeight || x == mapWidth - 1 || y == mapHeight - 1
        map[x, y] = Tile.new({
          "solid": solid,
          "kind": solid ? "wall" : "floor"
        })
      }
    }
    var houseWidth = 3
    for (x in 0...houseWidth) {
      var door = x == (houseWidth / 2).floor
      map[x, 0] = Tile.new({
        "solid": !door,
        "kind": !door ? "house" : "door"
      })
      if (door) {
        map[x, -1] = Tile.new({
          "solid": true,
          "kind": "roof"
        })
      }
    }
    map[-2, -1] = Tile.new({
      "solid": true,
      "kind": "roof"
    })
    map[-2, 0] = Tile.new({
      "solid": false,
      "kind": "well"
    })

    /*
    map[4, 2] = Tile.new({
      "kind": "plant",
      "solid": false,
      "watered": false,
      "stage": 0,
      "age": 0
    })
    */
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
    if (Keyboard["1"].justPressed) {
      _toolSelected = 1
    } else if (Keyboard["2"].justPressed) {
      _toolSelected = 2
    } else if (Keyboard["3"].justPressed) {
      _toolSelected = 3
    }
    if (Keyboard["right"].justPressed) {
      player.action = MoveAction.new(Vec.new(1, 0))
    } else if (Keyboard["left"].justPressed) {
      player.action = MoveAction.new(Vec.new(-1, 0))
    } else if (Keyboard["up"].justPressed) {
      player.action = MoveAction.new(Vec.new(0, -1))
    } else if (Keyboard["down"].justPressed) {
      player.action = MoveAction.new(Vec.new(0, 1))
    } else if (Keyboard["space"].justPressed) {
      if (_toolSelected == 1) {
        player.action = SowAction.new(Vec.new(0, 0))
      } else if (_toolSelected == 2) {
        player.action = WaterAction.new(Vec.new(0, 0))
      }
    } else {
      player.action = Action.none
    }
    _world.update()
  }

  draw() {
    Canvas.cls(Display.bg)
    var player = _world.active.getEntityByTag("player")
    var xOff = (Canvas.width - 8 - 12) / 2 + 1
    Canvas.offset(xOff - player.pos.x * 8, 20 - player.pos.y * 8)
    for (dy in -3..3) {
      for (dx in -5..5) {
        var x = player.pos.x + dx
        var y = player.pos.y + dy
        var tile = _world.active.map[x, y]
        if (tile["kind"] == "wall") {
          Canvas.rectfill(x * 8  + 1, y * 8 + 1, 6, 6, Display.fg)
        }
        if (tile["kind"] == "house") {
          Canvas.print("±", x * 8, y * 8, Display.fg)
        }
        if (tile["kind"] == "door") {
          Canvas.print(" ", x * 8, y * 8, Display.fg)
        }
        if (tile["kind"] == "roof") {
          Canvas.print("^", x * 8, y * 8 + 4, Display.fg)
        }
        if (tile["kind"] == "well") {
          Canvas.print("H", x * 8, y * 8, Display.fg)
        }
        if (tile["kind"] == "plant") {
          var bg = Display.bg
          var fg = Display.fg
          if (tile["watered"]) {
            var temp = bg
            bg = fg
            fg = temp
          }
          Canvas.rectfill(x * 8, y * 8, 8, 8, bg)
          // Canvas.circle(x * 8  + 4, y * 8 + 4, tile["stage"], fg)
          Canvas.print(tile["stage"], x * 8, y * 8, fg)
        }
      }
    }
    for (entity in _world.active.entities) {
      Canvas.rectfill(entity.pos.x * 8, entity.pos.y * 8, 8, 8, Display.bg)
      Canvas.print(entity.name[0], entity.pos.x * 8, entity.pos.y * 8, Display.fg)
    }

    Canvas.offset()
    var border = 12
    Canvas.rectfill(Canvas.width - border, 0, border, Canvas.height, Display.fg)
    Canvas.line(Canvas.width - border, 0, Canvas.width - border, Canvas.height, Display.bg)
    Canvas.print("S", Canvas.width - 8, 2, Display.bg)
    Canvas.print("W", Canvas.width - 8, 2 + 9, Display.bg)

    Canvas.rectfill(Canvas.width - border + 2, 1 + (_toolSelected - 1) * 9, 1, 9, Display.bg)
  }
}
