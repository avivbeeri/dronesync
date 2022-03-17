import "math" for Vec, M
import "core/elegant" for Elegant
import "core/action" for Action
import "actions" for MoveAction, WakeAction
import "core/behaviour" for Behaviour
import "core/graph" for WeightedZone, BFS, AStar, DijkstraMap, DijkstraSearch
import "core/dir" for Directions, NSEW

import "core/rng" for RNG
import "entities/player" for PlayerEntity
import "util" for GridWalk
import "./events" for LogEvent

var SEARCH = AStar

class Common {
  static isOccupied(self, dest) {
    return self.ctx.getEntitiesAtTile(dest.x, dest.y).where {|entity| entity != self && !(entity is PlayerEntity) }.count > 0
  }
  static moveRandom(self) { moveRandom(self, true) }
  static moveRandom(self, allowSolid) {
    var available = NSEW.values.where{|dir| !Common.isOccupied(self, self.pos + dir)}.toList
    var directions = RNG.shuffle(available)
    var dir = null
    for (d in directions) {
      dir = d
      var tile = self.ctx.map[self.pos + d]
      if (allowSolid || !tile["solid"]) {
        break
      }
      dir = null
    }
    if (dir != null) {
      return MoveAction.new(dir, true, Action.none)
    }
  }
}

class Curiosity is Behaviour {
  construct new(self) {
    super(self)
  }
  notify(event) {}

  evaluate() {
    // Get noticed events
    // D
    if (self["senses"]["noise"] && self["state"] != "alert") {
      self["awareness"] = 3
      self["focus"] = self["senses"]["noise"]
      self["state"] = "investigate-noise"
      self["senses"]["noise"] = null
      ctx.events.add(LogEvent.new("%(self) is investigating..."))
    } else if (self["state"] != "alert") {
      self["senses"]["noise"] = null
    }
    if (self["focus"] == self.pos) {
      self["focus"] = null
    }

    return null
  }

}

// Defining this lets us define our own priorities
class EnemyWeightedZone is WeightedZone {
  construct new(zone) {
    super(zone)
    _zone = zone
  }

  cost(a, b) {
    var pos = Elegant.unpair(b)
    var entities = _zone.getEntitiesAtTile(pos).toList

    var hasOther = !entities.isEmpty && entities.any {|entity| !entity is PlayerEntity }
    var hasPlayer = !entities.isEmpty && entities.any {|entity| entity is PlayerEntity }
    var ok = entities.isEmpty || (hasPlayer && !hasOther)
    return ok ? 1 : 10
  }
}

class State is Behaviour {
  construct new(self, key, stateMap) {
    super(self)
    _map = stateMap
    _key = key
    for (entry in _map.keys) {
      if (_map[entry] is Class) {
        _map[entry] = _map[entry].new(self)
      }
    }
  }
  notify(event) {}
  evaluate() {
    if (!_map.containsKey(self[_key])) {
      return null
    }
    return _map[self[_key]].evaluate()
  }
}

class Confusion is Behaviour {
  construct new(self) {
    super(self)
  }
  notify(event) {}

  evaluate() {
    if (ctx.map[self.pos]["blockSight"]) {
      return Common.moveRandom(self)
    }
  }

}

class Awareness is Behaviour {
  construct new(self) {
    super(self)
    self["senses"]["lastSawPlayer"] = 1
  }
  notify(event) {}
  evaluate() {
    // Is our square visible?
    // Can we see the player?
    var player = ctx.getEntityByTag("player")
    var visible = GridWalk.checkLoS(ctx.map, self.pos, player.pos)
    if (visible) {
      self["senses"]["player"] = player.pos * 1
      self["senses"]["lastSawPlayer"] = 0
    } else {
      self["senses"]["lastSawPlayer"] = (self["senses"]["lastSawPlayer"] + 1)
    }
    var dist = (self.pos - player.pos).length.round
    var near = dist < 20
    var close = dist < 8
    var veryClose = dist < 3
    var aware = self["awareness"]
    self["los"] = visible

    // while patrolling - if player is far away, awareness grows slowly
    if (self["state"] == "patrol") {
      if (visible) {
        if (near) {
          self["awareness"] = self["awareness"] + (close ? 2 : 1)
          if (self["awareness"] >= 6) {
            self["state"] = "alert"
            self["focus"] = self["senses"]["player"]
            ctx.parent["alerts"] = ctx.parent["alerts"] + 1

            ctx.events.add(LogEvent.new("%(self) was alerted to your presence!"))
          }
        }
      } else if (self["awareness"] > 3 && self["senses"]["lastSawPlayer"] < 2){
        self["state"] = "investigate"
        self["focus"] = self["senses"]["player"]
        ctx.events.add(LogEvent.new("%(self) is investigating..."))
      } else if (self["awareness"] > 0) {
        self["awareness"] = M.max(0, (self["awareness"] - 1))
        self["focus"] = null
        if (self["awareness"] == 0) {
        }
      } else {
        self["focus"] = null
      }
    } else if (self["state"] == "investigate-noise") {
      if (!self["focus"]) {
        self["awareness"] = M.max(0, (self["awareness"] - 1))
        self["focus"] = null
        if (self["awareness"] == 0) {
          self["state"] = "patrol"
          self["awareness"] = 3
        }
      }
      if (visible && veryClose) {
        self["state"] = "alert"
        ctx.events.add(LogEvent.new("%(self) was alerted to your presence!"))
        ctx.parent["alerts"] = ctx.parent["alerts"] + 1
        self["focus"] = self["senses"]["player"]
      }
    } else if (self["state"] == "investigate") {
      if (visible && near) {
        self["state"] = "alert"
        ctx.events.add(LogEvent.new("%(self) was alerted to your presence!"))
        ctx.parent["alerts"] = ctx.parent["alerts"] + 1
        self["awareness"] = 8
        self["focus"] = self["senses"]["player"]
      } else if (self["focus"]) {
      } else if (!visible) {
        self["awareness"] = M.max(0, (self["awareness"] - 1))
        if (self["awareness"] == 0) {
          self["state"] = "patrol"
          self["awareness"] = 3
        }
      }
    } else if (self["state"] == "alert") {
      if (!visible && !self["focus"]) {
        self["awareness"] = 8
        self["focus"] = self["senses"]["player"]
        self["state"] = "investigate"
        ctx.events.add(LogEvent.new("%(self) is suspicious"))
      } else if (near) {
        self["focus"] = self["senses"]["player"]
      }
    }

    return null
  }
}

class SeekFocus is Behaviour {
  construct new(self) {
    super(self)
  }

  getFocus() {
    if (self["focus"]) {
      return self["focus"]
    }
  }

  notify(event) {}
  evaluate() {
    _graph = EnemyWeightedZone.new(ctx)
    var focus = getFocus()
    if (focus) {
      _search = SEARCH.search(_graph, self.pos, focus)
      var path = SEARCH.reconstruct(_search[0], self.pos, focus)
      if (path == null || path.count <= 1) {
        _search = null
        return Action.none
      }
      return MoveAction.new(path[1] - self.pos, true)
    }
    _search = null
    return Common.moveRandom(self)
  }
}
class SeekPlayer is SeekFocus {
  construct new(self) {
    super(self)
  }

  getFocus() {
    var player = ctx.getEntityByTag("player")
    var visible = GridWalk.checkLoS(ctx.map, self.pos, player.pos)
    if (visible) {
      return player.pos
    }
    return super.getFocus()
  }
}

class Patrol is Behaviour {
  construct new(self, points) {
    super(self)
    _points = points
    _index = 0
    _attempts = 0
  }
  notify(event) {}

  evaluate() {
    var player = ctx.getEntityByTag("player")
    if (_points.count == 0) {
      return null
    }
    if (self.pos == _points[_index]) {
      _index = (_index + 1) % _points.count
      _search = null
    }

    if (!_search || (self.pos - player.pos).length < 16) {
      _graph = EnemyWeightedZone.new(ctx)
      _search = SEARCH.search(_graph, self.pos, _points[_index])
    }
    var path = SEARCH.reconstruct(_search[0], self.pos, _points[_index])
    if (path == null || path.count <= 1) {
      _search = null
      return null
    }

    if (Common.isOccupied(self, path[1])) {
      _attempts = _attempts + 1
      if (_attempts < 2) {
        return null
      } else {
        _search = null
        _attempts = 0
        // scan for empty space?
        return Common.moveRandom(self, false)
      }
    }
    _attempts = 0
    return MoveAction.new(path[1] - self.pos, true)
  }
}

class Wait is Behaviour {
  construct new(self) {
    super(self)
  }
  notify(event) {}
  evaluate() {
    return Action.none
  }
}


class Stunnable is Behaviour {
  construct new(self) {
    super(self)
  }
  notify(event) {}
  evaluate() {
    if (self["stunTimer"] > 0) {
      return WakeAction.new()
    }
    return null
  }
}
