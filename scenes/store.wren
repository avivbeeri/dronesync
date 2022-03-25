import "core/dataobject" for Store, Reducer

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

class QueryReducer is TestReducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "query") {
      state["result"] = action["result"]
      state["config"] = action["config"]
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

var StoreFactory = Fn.new {
  var reducer = Store.combineReducers({
    "window": WindowReducer.new(),
    "selection": SelectionReducer.new(),
    "action": ActionReducer.new(),
    "item": ItemReducer.new(),
    "mode": ModeReducer.new(),
    "query": QueryReducer.new()
  })
  return Store.create({
    "window": {},
    "query": {},
    "action": {},
    "item": {},
    "mode": "play",
    "selection": {
    "tiles": [],
    "range": []
    }
  }, reducer)
}
