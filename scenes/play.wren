import "graphics" for Canvas
import "dome" for Window
import "input" for Keyboard
import "math" for Vec
import "json" for JSON
import "io" for FileSystem

import "core/entity" for StackEntity
import "core/action" for Action
import "extra/actions" for RestAction
import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config
import "core/world" for World, Zone
import "core/director" for EnergyStrategy
import "core/map" for TileMap, Tile
import "core/tilesheet" for Tilesheet

import "./events" for SleepEvent, RefillEvent, EmptyEvent
import "./actions" for MoveAction, SleepAction, SowAction, WaterAction, HarvestAction
import "./logic" for SaveHook
import "./entities" for PlayerEntity
import "./palette" for PAL
import "./inputs" for InputAction

import "./animations" for SleepAnimation
import "./scenes/renderer" for WorldRenderer
import "./scenes/statusbar" for StatusBar

class PlayScene is Scene {
  construct new(args) {
    super(args)
    var strategy = EnergyStrategy.new()
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
      var mapHeight = Config["map"]["height"]
      var mapWidth = Config["map"]["width"]
      for (y in 0...mapHeight) {
        for (x in 0...mapWidth) {
          var solid = x == 0 || y == 0 || x == mapWidth - 1 || y == mapHeight - 1
          map[x, y] = Tile.new({
            "solid": solid,
            "kind": solid ? "wall" : "floor"
          })
        }
      }

      player.pos.x = 1
      player.pos.y = 1
      player["water"] = 18
    }

    var dummy = zone.addEntity("dummy", StackEntity.new())
    dummy.pos.x = 2
    dummy.pos.y = 2
    addViewChild(WorldRenderer.new(this, _world.active, 0, 21))
    addViewChild(StatusBar.new(this, _world.active))
  }

  // TODO: Push this into a seperate View child object
  showbar(text) {
    _barTimer = 3 * 60
    _barText = text
  }

  update() {
    super.update()
    _barTimer = _barTimer - 1

    var player = _world.active.getEntityByTag("player")

    if (InputAction.right.firing) {
      player.action = MoveAction.new(Vec.new(1, 0))
    } else if (InputAction.left.firing) {
      player.action = MoveAction.new(Vec.new(-1, 0))
    } else if (InputAction.up.firing) {
      player.action = MoveAction.new(Vec.new(0, -1))
    } else if (InputAction.down.firing) {
      player.action = MoveAction.new(Vec.new(0, 1))
    } else if (InputAction.rest.firing) {
      player.action = RestAction.new()
    }

    _world.update()
    for (event in _world.active.events) {
    }
  }

  draw() {
    Canvas.cls(Display.bg)
    super.draw()

    // Canvas.offset()
    // TODO: push into child view
    if (_barTimer > 0) {
      Canvas.rectfill(0, Canvas.height - 8, Canvas.width, 8, Display.fg)
      Canvas.print(_barText, 0, Canvas.height - 6, Display.bg, "m3x6")
    }

  }
}
