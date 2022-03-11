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

var SEARCH = AStar

class Curiosity is Behaviour {
  construct new(self) {
    super(self)
  }
  notify(event) {}

  isOccupied(dest) {
    return ctx.getEntitiesAtTile(dest.x, dest.y).where {|entity| entity != self && !(entity is PlayerEntity) }.count > 0
  }

  evaluate() {
    // Get noticed events
    // D
    if (self["focus"] == self.pos) {
      System.print("POI reached")
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

  isOccupied(dest) {
    return ctx.getEntitiesAtTile(dest.x, dest.y).where {|entity| entity != self && !(entity is PlayerEntity) }.count > 0
  }

  evaluate() {
    if (ctx.map[self.pos]["blockSight"]) {
      var available = NSEW.values.where{|dir| !isOccupied(self.pos + dir)}.toList
      var dir = RNG.sample(available)
      if (dir != null) {
        return MoveAction.new(dir, true, Action.none)
      }
      return Action.none
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
    /*
    if (self["state"] == "alert") {
      return null
    }
    */

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
    var veryClose = dist < 4
    var aware = self["awareness"]
    self["los"] = visible

    // System.print("%(self): %(visible) - %(aware)")

    // while patrolling - if player is far away, awareness grows slowly



    if (self["state"] == "patrol") {
      if (visible) {
        if (near) {
          self["awareness"] = self["awareness"] + (close ? 2 : 1)
          System.print("seeing")
          if (self["awareness"] >= 6) {
            System.print("%(self) went on alert")
            self["state"] = "alert"
          }
        }
        System.print("out of range %(aware)")
      } else if (self["awareness"] > 3 && self["senses"]["lastSawPlayer"] < 2){
        self["state"] = "investigate"
        self["focus"] = self["senses"]["player"]
        System.print("%(self) begins investigating...")
      } else if (self["awareness"] > 0) {
        self["awareness"] = M.max(0, (self["awareness"] - 1))
        self["focus"] = null
        if (self["awareness"] == 0) {
          System.print("%(self): 'Probably nothing.'")
        }
      } else {
        self["focus"] = null
      }
    } else if (self["state"] == "investigate") {
      if (visible && near) {
        self["awareness"] = 6
        self["state"] = "alert"
      } else if (self["focus"]) {

      } else if (!visible) {
        self["awareness"] = M.max(0, (self["awareness"] - 1))
        if (self["awareness"] == 0) {
          self["state"] = "patrol"
          self["awareness"] = 3
          System.print("%(self) relaxes")
        }
      }
    } else if (self["state"] == "alert") {
      if (!visible) {
        self["awareness"] = M.max(0, (self["awareness"] - 1))
        if (self["awareness"] == 0) {
          self["awareness"] = 4
          self["state"] = "investigate"
        }
      } else if (near) {
        self["awareness"] = 6
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
        return Action.none
      }
      return MoveAction.new(path[1] - self.pos, true)
    }
    return null
  }
}
class SeekPlayer is Behaviour {
  construct new(self) {
    super(self)
  }

  notify(event) {}
  evaluate() {
    // TODO: Make this behaviour generic by indicating a point of interest
    // rather than homing on the player
    var player = ctx.getEntityByTag("player")
    if (player) {
      var search = player["dijkstra"]
      var path = DijkstraMap.reconstruct(search[0], player.pos, self.pos)
      if (path == null || path.count <= 1) {
        return Action.none
      }
      return MoveAction.new(path[1] - self.pos, true)
    }
    return Action.none
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

  isOccupied(dest) {
    return ctx.getEntitiesAtTile(dest.x, dest.y).where {|entity| entity != self && !(entity is PlayerEntity) }.count > 0
  }

  evaluate() {
    if (_points.count == 0) {
      return null
    }
    if (self.pos == _points[_index]) {
      _index = (_index + 1) % _points.count
      _search = null
    }
    _graph = EnemyWeightedZone.new(ctx)
    _search = SEARCH.search(_graph, self.pos, _points[_index])
    var path = SEARCH.reconstruct(_search[0], self.pos, _points[_index])
    if (path == null || path.count <= 1) {
      _search = null
      return Action.none
    }

    if (isOccupied(path[1])) {
      _attempts = _attempts + 1
      if (_attempts < 2) {
        return null
      } else {
        _attempts = 0
        // scan for empty space?
        var available = NSEW.values.where{|dir| !isOccupied(self.pos + dir)}.toList
        var dir = RNG.sample(available)
        if (dir != null) {
          _search = null
          return MoveAction.new(dir, true, Action.none)
        }
        return null
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
