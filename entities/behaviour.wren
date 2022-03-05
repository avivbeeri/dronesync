import "math" for Vec

import "core/action" for Action
import "actions" for MoveAction
import "core/behaviour" for Behaviour
import "core/graph" for WeightedZone, BFS, AStar, DijkstraMap, DijkstraSearch
import "core/dir" for Directions, NSEW

import "core/rng" for RNG

var SEARCH = AStar

class Seek is Behaviour {
  construct new(self) {
    super(self)
  }
  notify(event) {}
  evaluate() {
    var map = ctx.map
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
    return ctx.getEntitiesAtTile(dest.x, dest.y).where {|entity| entity != self }.count > 0
  }

  evaluate() {
    if (self.pos == _points[_index]) {
      _index = (_index + 1) % _points.count
      _search = null
    }
    if (!_search) {
      _graph = WeightedZone.new(ctx)
      _search = SEARCH.search(_graph, self.pos, _points[_index])
    }
    var path = SEARCH.reconstruct(_search[0], self.pos, _points[_index])
    /*
    var dir = (_points[_index] - self.pos).unit
    if (dir.length < 1) {
      return null
    }
    */
    if (path == null || path.count <= 1) {
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
      return Action.none
    }
    return null
  }
}
