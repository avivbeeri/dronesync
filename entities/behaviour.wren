import "math" for Vec

import "core/action" for Action
import "actions" for MoveAction
import "core/behaviour" for Behaviour
import "core/graph" for WeightedZone, BFS, AStar, DijkstraMap, DijkstraSearch

var SEARCH = DijkstraSearch

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
  }
  notify(event) {}
  evaluate() {
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
