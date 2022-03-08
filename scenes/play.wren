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
import "core/display" for Display
import "core/config" for Config
import "core/world" for World, Zone
import "core/director" for EnergyStrategy
import "core/map" for TileMap, Tile
import "core/tilesheet" for Tilesheet

import "extra/events" for GameEndEvent
import "./events" for LogEvent
import "./actions" for MoveAction, SmokeAction
import "./entities/player" for PlayerEntity
import "./palette" for PAL
import "./inputs" for InputAction
import "./log" for Log

// import "./bulkLoader" for SleepAnimation, WorldRenderer, StatusBar, Tooltip

import "./views/renderer" for WorldRenderer
import "./views/tooltip" for Tooltip

import "./generator" for StaticGenerator
import "core/graph" for DijkstraMap

class TestReducer is Reducer {
  call(x, y) { reduce(x, y) }
}
class ActionReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "action") {
      state["data"] = action["data"]
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
    }
    return state
  }
}

class LogReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "logOpen") {
      state = action["mode"] == "open"
    }
    return state
  }
}

class RangeSelectorState is State {
  construct new(ctx, view, data, range) {
    init(ctx, view, data, range, 0)
  }
  construct new(ctx, view, data, range, splash) {
    init(ctx, view, data, range, splash)
  }
  init(ctx, view, data, range, splash) {
    _ctx = ctx
    _data = data
    _view = view
    _range = range + 1
    _splash = splash + 1
    _center = null
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
        var visible = GridWalk.checkLoS(_ctx.active.map, pos, point)
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
    _center = player.pos
    _tileList = getRangeFromPoint(_center, _range)
    _selection = getRangeFromPoint(_center, _splash)
    _view.top.store.dispatch({ "type": "selection", "tiles": _selection, "range": _tileList })
  }

  onExit() {
    _view.top.store.dispatch({ "type": "selection", "tiles": [], "range": [] })
  }

  update() {
    if (!_center) {
      return
    }
    // TODO: handle mouse or keyboard input
    var destination = null
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
    } else if (InputAction.confirm.firing) {
      _view.top.store.dispatch({ "type": "action", "data": _data, "selection": _selection })
      return PlayState.new(_ctx, _view)
    }
    if (destination && _tileList.contains(destination)) {
      _center = destination
      _selection = getRangeFromPoint(_center, _splash)
      _view.top.store.dispatch({
        "type": "selection",
        "tiles": _selection,
        "range": _tileList,
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

  update() {
    var player = _ctx.active.getEntityByTag("player")
    var drone = _ctx.active.getEntityByTag("drone")
    if (player) {
      var current = player
      if (!player["active"] && drone) {
        current = drone
      }


      if (current) {
        if (_view.store.state["action"]["data"]) {
          var action = _view.store.state["action"]
          System.print(action)
          if (action["data"]["id"] == "smokebomb") {
            current.action = SmokeAction.new(action["selection"])
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
          } else if (InputAction.next.firing) {
            // Get info about item
            var item = {
              "id": "smokebomb",
              "range": 4,
              "splash": 4
            }

            return RangeSelectorState.new(_ctx, _view, item, item["range"], item["splash"])
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
      "selection": SelectionReducer.new(),
      "action": ActionReducer.new()
    })
    _store = Store.create({
      "logOpen": false,
      "action": {},
      "selection": {
        "tiles": [],
        "range": []
      }
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
