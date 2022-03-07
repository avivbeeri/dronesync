import "graphics" for Canvas
import "input" for Keyboard
import "math" for Vec

import "core/dataobject" for Store, Reducer
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

import "extra/events" for GameEndEvent
import "./events" for LogEvent
import "./actions" for MoveAction
import "./entities/player" for PlayerEntity
import "./palette" for PAL
import "./inputs" for InputAction
import "./log" for Log

// import "./bulkLoader" for SleepAnimation, WorldRenderer, StatusBar, Tooltip

import "./views/renderer" for WorldRenderer
import "./views/tooltip" for Tooltip

import "./generator" for StaticGenerator

class LogReducer is Reducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "open") {
      state["logOpen"] = true
    }
    if (action["type"] == "close") {
      state["logOpen"] = false
    }
    return state
  }
}

class PlayScene is Scene {
  construct new(args) {
    super()
    _log = Log.new()
    _store = Store.create({
      "logOpen": false
    }, LogReducer.new())
    _store.subscribe {
      System.print(_store.state)
    }

    _world = StaticGenerator.createWorld()

    addViewChild(WorldRenderer.new(this, _world.active, 0, 21))
    addViewChild(StatusBar.new(this, _world.active))
    addViewChild(Tooltip.new(this, "BEGIN!"))
  }

  store { _store }
  log { _log }

  update() {
    super.update()

    var player = _world.active.getEntityByTag("player")
    var drone = _world.active.getEntityByTag("drone")
    if (player) {
      var current = player
      if (!player["active"] && drone) {
        current = drone
      }

      if (current) {
        if (InputAction.right.firing) {
          current.action = MoveAction.new(Vec.new(1, 0))
        } else if (InputAction.left.firing) {
          current.action = MoveAction.new(Vec.new(-1, 0))
        } else if (InputAction.up.firing) {
          current.action = MoveAction.new(Vec.new(0, -1))
        } else if (InputAction.down.firing) {
          current.action = MoveAction.new(Vec.new(0, 1))
        } else if (drone && InputAction.swap.firing) {
          player["active"] = !player["active"]
          var aIndex = _world.active.entities.indexOf(player)
          var bIndex = _world.active.entities.indexOf(drone)
          _world.active.entities.swap(aIndex, bIndex)
          drone.priority = 12
          player.priority = 12
          return
        } else if (InputAction.rest.firing) {
          current.action = RestAction.new()
        }
      }
    }
    if (!_world.gameover) {
      _world.update()

      for (event in _world.active.events) {
        if (event is LogEvent) {
          System.print(event.text)
          _log.add(event.text)
        }
        if (event is GameEndEvent) {
          var message = event.won ? "Mission Successful!" : "Mission Bailed"
          addViewChild(GameEndWindow.new(this, _world.active, message))
        }
      }
    }
  }

  draw() {
    Canvas.cls(Display.bg)
    super.draw()
  }
}

import "./views/window" for GameEndWindow
import "./views/statusbar" for StatusBar
