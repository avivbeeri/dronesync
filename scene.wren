import "graphics" for Canvas
import "dome" for Window
import "input" for Keyboard
import "math" for Vec
import "json" for JSON
import "io" for FileSystem

import "core/action" for Action
import "core/scene" for Scene, View
import "core/display" for Display
import "core/world" for World, Zone
import "core/director" for ActionStrategy
import "core/map" for TileMap, Tile
import "core/tilesheet" for Tilesheet

import "./events" for SleepEvent, RefillEvent, EmptyEvent
import "./actions" for MoveAction, SleepAction, SowAction, WaterAction, HarvestAction
import "./logic" for SaveHook
import "./entities" for PlayerEntity

class SleepAnimation is View {
  construct new() {
    _t = 2 * 60
  }

  update() {
    _t = _t - 1
    if (_t <= 0) {
      parent.removeViewChild(this)
    }
  }

  draw() {
    Canvas.cls(Display.fg)
    Canvas.print("Sleeping...", 0, 8, Display.bg, "m3x6")
    Canvas.print("Game was saved.", 0, Canvas.height - 7, Display.bg, "m3x6")
  }
}

class PlantScene is Scene {
  construct new(args) {
    super(args)
    var strategy = ActionStrategy.new()
    var map = TileMap.init()
    _sheet = Tilesheet.new("res/sprites.png", 8, 1)
    _world = World.new(strategy)
    _world.pushZone(Zone.new(map))
    _world.active.postUpdate.add(SaveHook)
    var zone = _world.active
    var player = PlayerEntity.new()
    zone.addEntity("player", player)

    _barTimer = 0
    _toolSelected = 1

    // Is there a save.json?
    var save = Fiber.new {
      var path = FileSystem.prefPath("avivbeeri", "dronesync")
      var result = FileSystem.load("%(path)save.json")
      return JSON.decode(result)
    }.try()
    if (save is Map) {
      for (key in save["map"].keys) {
        zone.map.tiles[Num.fromString(key)] = Tile.new(save["map"][key])
      }
      player.pos.x = save["player"]["x"]
      player.pos.y = save["player"]["y"]
      for (key in save["player"].keys) {
        if (key != "x" && key != "y") {
          player.data[key] = save["player"][key]
        }
      }
    } else {
      // else do the generate
      var mapHeight = 10
      var mapWidth = 10
      for (y in -5...mapHeight) {
        for (x in -mapWidth...mapWidth) {
          var solid = x == -mapWidth || y == -5 || x == mapWidth - 1 || y == mapHeight - 1
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
        map[x, -1] = Tile.new({
          "solid": true,
          "kind": "roof"
        })
      }
      map[-2, -1] = Tile.new({
        "solid": true,
        "kind": "roof"
      })
      map[-2, 0] = Tile.new({
        "solid": false,
        "kind": "well"
      })

      player.pos.x = 1
      player.pos.y = 1
      player["water"] = 18
    }
  }

  showbar(text) {
    _barTimer = 3 * 60
    _barText = text
  }

  update() {
    super.update()
    _barTimer = _barTimer - 1
    var player = _world.active.getEntityByTag("player")
    if (Keyboard["1"].justPressed) {
      _toolSelected = 1
      showbar("Sow Seeds")
    } else if (Keyboard["2"].justPressed) {
      _toolSelected = 2
      showbar("Watering Can")
    } else if (Keyboard["3"].justPressed) {
      _toolSelected = 3
      showbar("Trowel")
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
      } else if (_toolSelected == 3) {
        player.action = HarvestAction.new(Vec.new(0, 0))
      }
    } else {
      player.action = Action.none
    }
    _world.update()
    for (event in _world.active.events) {
      if (event is SleepEvent) {
        addViewChild(SleepAnimation.new())
      }
      if (event is RefillEvent) {
        showbar("Refilled!")
      }
      if (event is EmptyEvent) {
        showbar("Empty!")
      }
    }
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
          // Canvas.rectfill(x * 8  + 1, y * 8 + 1, 6, 6, Display.fg)
          _sheet.draw(9, x * 8, y * 8, Display.fg, Display.bg)
        }
        if (tile["kind"] == "house") {
          // Canvas.print("±", x * 8, y * 8, Display.fg)
          _sheet.draw(7, x * 8, y * 8, Display.fg, Display.bg)
        }
        if (tile["kind"] == "door") {
         // Canvas.print(" ", x * 8, y * 8, Display.fg)
          _sheet.draw(8, x * 8, y * 8, Display.fg, Display.bg)
        }
        if (tile["kind"] == "roof") {
          // Canvas.print("^", x * 8, y * 8 + 4, Display.fg)
          _sheet.draw(6, x * 8, y * 8, Display.fg, Display.bg)
        }
        if (tile["kind"] == "well") {
          // Canvas.print("H", x * 8, y * 8, Display.fg)
          _sheet.draw(5, x * 8, y * 8, Display.fg, Display.bg)
        }
        if (tile["kind"] == "dead") {
          //Canvas.print("=", x * 8, y * 8, Display.fg)
          _sheet.draw(4, x * 8, y * 8, Display.fg, Display.bg)
        }
        if (tile["kind"] == "plant") {
          var bg = Display.bg
          var fg = Display.fg
          if (tile["watered"]) {
            var temp = bg
            bg = fg
            fg = temp
          }
          // Canvas.rectfill(x * 8, y * 8, 7, 8, bg)
          // Canvas.circle(x * 8  + 4, y * 8 + 4, tile["stage"], fg)
          // Canvas.print(tile["stage"], x * 8, y * 8, fg)
          _sheet.draw(tile["stage"], x * 8, y * 8, fg, bg, false)
        }
      }
    }
    for (entity in _world.active.entities) {
      Canvas.rectfill(entity.pos.x * 8, entity.pos.y * 8, 8, 8, Display.bg)
      // Canvas.print(entity.name[0], entity.pos.x * 8, entity.pos.y * 8, Display.fg)
      _sheet.draw(10, entity.pos.x * 8, entity.pos.y * 8, Display.fg, Display.bg)

    }

    Canvas.offset()
    var border = 12
    Canvas.rectfill(Canvas.width - border, 0, border, Canvas.height, Display.fg)
    Canvas.line(Canvas.width - border, 0, Canvas.width - border, Canvas.height, Display.bg)
    _sheet.draw(11, Canvas.width - 8, 2, Display.bg, Display.fg)
    _sheet.draw(12, Canvas.width - 8, 2 + 9, Display.bg, Display.fg)
    _sheet.draw(13, Canvas.width - 8, 2 + 18, Display.bg, Display.fg)

    if (_barTimer > 0) {
      Canvas.rectfill(0, Canvas.height - 8, Canvas.width, 8, Display.fg)
      Canvas.print(_barText, 0, Canvas.height - 6, Display.bg, "m3x6")
    }

    Canvas.rectfill(Canvas.width - border + 2, 1 + (_toolSelected - 1) * 9, 1, 9, Display.bg)
    Canvas.rectfill(Canvas.width - border + 4, Canvas.height - player["water"], border - 5, player["water"], Display.bg)
    super.draw()
  }
}
