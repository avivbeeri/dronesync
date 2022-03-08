import "graphics" for Canvas
import "input" for Keyboard
import "math" for Vec

import "core/dataobject" for Store, Reducer
import "core/entity" for StackEntity
import "core/action" for Action
import "extra/actions" for RestAction
import "core/scene" for Scene, View, State
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
class TestReducer is Reducer {
  call(x, y) { reduce(x, y) }

}
class SelectionReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "selection") {
      state = action["tiles"]
    }
    return state
  }
}

class LogReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    System.print(state)
    System.print(action)
    if (action["type"] == "logOpen") {
      state = action["mode"] == "open"
    }
    return state
  }
}

class RangeSelectorState is State {
  construct new(ctx, view, range) {
    _ctx = ctx
    _view = view
    _range = range + 1
  }

  onEnter() {
    var player = _ctx.active.getEntityByTag("player")
    _selection = player.pos
    _tileList = []
    for (dy in -_range..._range) {
      for (dx in -_range..._range) {
        if (Vec.new(dx, dy).manhattan >= _range) {
        // if ((dx.abs + dy.abs) > _range) {
          continue
        }
        _tileList.add(player.pos + Vec.new(dx, dy))
      }
    }
    _view.top.store.dispatch({ "type": "selection", "tiles": [ _selection ] })
  }

  onExit() {
    _view.top.store.dispatch({ "type": "selection", "tiles": [] })
  }

  update() {
    // TODO: handle mouse or keyboard input
    var destination = null
    if (InputAction.right.firing) {
      destination = _selection + Vec.new(1, 0)
    } else if (InputAction.left.firing) {
      destination = _selection + Vec.new(-1, 0)
    } else if (InputAction.up.firing) {
      destination = _selection + Vec.new(0, -1)
    } else if (InputAction.down.firing) {
      destination = _selection + Vec.new(0, 1)
    } else if (InputAction.cancel.firing) {
      return PlayState.new(_ctx, _view)
    }
    if (destination && _tileList.contains(destination)) {
      _selection = destination
      _view.top.store.dispatch({ "type": "selection", "tiles": [ _selection ] })
    }
    return this
  }
}

class PlayState is State {
  construct new(ctx, view) {
    _ctx = ctx
    _view = view
  }

  update() {
    var player = _ctx.active.getEntityByTag("player")
    var drone = _ctx.active.getEntityByTag("drone")
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
        } else if (InputAction.next.firing) {
          return RangeSelectorState.new(_ctx, _view, 3)
        } else if (drone && InputAction.swap.firing) {
          player["active"] = !player["active"]
          var aIndex = _ctx.active.entities.indexOf(player)
          var bIndex = _ctx.active.entities.indexOf(drone)
          _ctx.active.entities.swap(aIndex, bIndex)
          drone.priority = 12
          player.priority = 12
          return this
        } else if (InputAction.rest.firing) {
          current.action = RestAction.new()
        }
      }
    }
    return this

  }

}

class PlayScene is Scene {
  construct new(args) {
    super()
    _log = Log.new()
    var logReducer = LogReducer.new()
    var reducer = Store.combineReducers({
      "logOpen": logReducer,
      "selection": SelectionReducer.new()
    })
    _store = Store.create({
      "logOpen": false,
      "selection": []
    }, reducer)

    _world = StaticGenerator.createWorld()
    _state = PlayState.new(_world, this)

    addViewChild(WorldRenderer.new(this, _world.active, 0, 21))
    addViewChild(StatusBar.new(this, _world.active))
    addViewChild(Tooltip.new(this, "BEGIN!"))
  }

  store { _store }
  log { _log }

  update() {
    super.update()

    var state = _state.update()
    if (state != _state) {
      changeState(state)
    }
    /*
    if (!state.tickWorld) {
      return
    }
    */

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

  changeState(newState) {
    _state.onExit()
    _state = newState
    _state.onEnter()
  }

  draw() {
    Canvas.cls(Display.bg)
    super.draw()
  }
}

import "./views/window" for GameEndWindow
import "./views/statusbar" for StatusBar
