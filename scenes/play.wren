import "graphics" for Canvas
import "input" for Keyboard
import "math" for Vec
import "./util" for GridWalk

import "core/elegant" for Elegant
import "core/dataobject" for Store, Reducer
import "core/entity" for StackEntity
import "core/action" for Action
import "extra/actions" for RestAction
import "core/scene" for Scene, View, State
import "core/config" for Config
import "core/display" for Display
import "./palette" for PAL
import "core/world" for World, Zone
import "core/director" for EnergyStrategy
import "core/map" for TileMap, Tile
import "core/tilesheet" for Tilesheet

import "extra/events" for GameEndEvent
import "./events" for LogEvent, QueryEvent
import "./actions" for MoveAction, SmokeAction, UseItemAction, SwapAction, EscapeAction
import "./entities/player" for PlayerEntity
import "./inputs" for InputAction
import "./log" for Log

// import "./bulkLoader" for SleepAnimation, WorldRenderer, StatusBar, Tooltip

import "./views/renderer" for WorldRenderer
import "./views/tooltip" for Tooltip

import "./generator" for StaticGenerator, RoomGenerator
import "core/graph" for DijkstraMap

class TestReducer is Reducer {
  call(x, y) { reduce(x, y) }
}
class ModeReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "mode") {
      state  = action["mode"]
    }
    return state
  }
}
class ItemReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "item") {
      state["data"] = action["data"]
    }
    return state
  }
}
class ActionReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "action") {
      state["data"] = action["data"]
      state["center"] = action["center"]
      state["selection"] = action["selection"]
    }
    return state
  }
}
class SelectionReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "selection") {
      state["tiles"] = action["tiles"]
      state["range"] = action["range"]
      state["center"] = action["center"]
      state["valid"] = action["valid"]
    }
    return state
  }
}

class WindowReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "window") {
      if (action["mode"] == "open") {
        state[action["id"]] = true
      } else {
        state[action["id"]] = false
      }
    }
    return state
  }
}

class QueryState is State {
  construct new(ctx, view, data) {
    _ctx = ctx
    _view = view
    _data = data
  }

  onEnter() {
    System.print("awaiting input...")
  }

  onExit() {
    System.print("Input received.")
  }

  update() {
    if (_data["type"] == "escape") {
      if (InputAction.confirm.firing) {
        _view.top.store.dispatch({ "type": "action", "data": _data })
        return PlayState.new(_ctx, _view)
      }
    } else {
      Fiber.abort("Invalid query data type")
    }
    return this
  }
}

class RangeSelectorState is State {
  construct new(ctx, view, data, range) {
    init(ctx, view, data, range, 0, true)
  }
  construct new(ctx, view, data, range, splash, useCenter) {
    init(ctx, view, data, range, splash, useCenter)
  }
  init(ctx, view, data, range, splash, useCenter) {
    _ctx = ctx
    _data = data
    _view = view
    _range = range + 1
    _splash = splash + 1
    _center = null
    _origin = null
    _useCenter = useCenter
  }

  getRangeFromPoint(point, range) {
    var tileList = []
    for (dy in -range...range) {
      for (dx in -range...range) {
        var d = Vec.new(dx, dy)
        var pos = point + d
        if (d.manhattan >= range) {
          continue
        }
        var visible = GridWalk.checkReach(_ctx.active.map, pos, point)
        if (!visible) {
          continue
        }

        tileList.add(pos)
      }
    }
    return tileList
  }

  onEnter() {
    var player = _ctx.active.getEntityByTag("player")
    _center = _origin = player.pos
    _tileList = getRangeFromPoint(_center, _range)
    _selection = getRangeFromPoint(_center, _splash)
    _view.top.store.dispatch({ "type": "selection", "tiles": _selection, "range": _tileList, "center": _center })
    _view.top.store.dispatch({ "type": "mode", "mode": "select" })
  }

  onExit() {
    _view.top.store.dispatch({ "type": "selection", "tiles": [], "range": [], "center": null })
  }

  update() {
    if (!_center) {
      return
    }
    // TODO: handle mouse or keyboard input
    var destination = _center
    if (InputAction.right.firing) {
      destination = _center + Vec.new(1, 0)
    } else if (InputAction.left.firing) {
      destination = _center + Vec.new(-1, 0)
    } else if (InputAction.up.firing) {
      destination = _center + Vec.new(0, -1)
    } else if (InputAction.down.firing) {
      destination = _center + Vec.new(0, 1)
    } else if (InputAction.cancel.firing) {
      return PlayState.new(_ctx, _view)
    }

    var valid = _useCenter || destination != _origin
    if (InputAction.confirm.firing) {
      if (valid) {
        _view.top.store.dispatch({ "type": "action", "data": _data, "selection": _selection, "center": _center })
        return PlayState.new(_ctx, _view)
      }
    }
    if (destination && _tileList.contains(destination)) {
      _center = destination
      if (!valid) {
        _selection = [_center]
      } else {
        _selection = getRangeFromPoint(_center, _splash)
      }
      _view.top.store.dispatch({
        "type": "selection",
        "tiles": _selection,
        "range": _tileList,
        "center": _center,
        "valid": valid
      })
    }
    return this
  }
}

class PlayState is State {
  construct new(ctx, view) {
    _ctx = ctx
    _view = view
  }

  onEnter() {
    _view.top.store.dispatch({ "type": "mode", "mode": "play" })
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
        if (_view.store.state["item"]["data"]) {
          var item = _view.store.state["item"]["data"]
          _view.store.dispatch({ "type": "item", "data": null })
          if (player["active"]) {
            // Get info about item
            return RangeSelectorState.new(_ctx, _view, item, item["range"], item["splash"], item.containsKey("useCenter") ? item["useCenter"] : true)
          }
        }
        if (_view.store.state["action"]["data"]) {
          var action = _view.store.state["action"]
          System.print(action)
          if (_view.store.state["action"]["data"]["type"] == "escape") {
            current.action = EscapeAction.new()
          } else {
            current.action = UseItemAction.new(action["data"]["id"], action)
          }
          _view.store.dispatch({ "type": "action", "data": null, "selection": null })
        } else {
          if (InputAction.right.firing) {
            current.action = MoveAction.new(Vec.new(1, 0))
          } else if (InputAction.left.firing) {
            current.action = MoveAction.new(Vec.new(-1, 0))
          } else if (InputAction.up.firing) {
            current.action = MoveAction.new(Vec.new(0, -1))
          } else if (InputAction.down.firing) {
            current.action = MoveAction.new(Vec.new(0, 1))
          } else if (drone && InputAction.swap.firing) {
            current.action = SwapAction.new()
          } else if (InputAction.rest.firing) {
            current.action = RestAction.new()
          }
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
    _log.add("Mission commenced.")
    var reducer = Store.combineReducers({
      "window": WindowReducer.new(),
      "selection": SelectionReducer.new(),
      "action": ActionReducer.new(),
      "item": ItemReducer.new(),
      "mode": ModeReducer.new()
    })
    _store = Store.create({
      "window": {},
      "action": {},
      "item": {},
      "mode": "play",
      "selection": {
        "tiles": [],
        "range": []
      }
    }, reducer)

    _world = RoomGenerator.generate()
    // _world = StaticGenerator.generate()
    _state = PlayState.new(_world, this)

    addViewChild(WorldRenderer.new(this, _world.active, 0, 9))
    addViewChild(StatusBar.new(this, _world.active))
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
        if (event is QueryEvent) {
          changeState(QueryState.new(_world, this, event.data))
        }
        if (event is LogEvent) {
          System.print(event.text)
          _log.add(event.text)
        }
        if (event is GameEndEvent) {
          var message = event.won ? "Mission Successful!" : "Mission Bailed"
          var player = _world.active.getEntityByTag("player", true)
          if (player && player.alive) {
            addViewChild(ScoreWindow.new(this, _world, message))
          } else {
            addViewChild(GameEndWindow.new(this, _world, message))
          }
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

import "./views/window" for GameEndWindow, ScoreWindow
import "./views/statusbar" for StatusBar
