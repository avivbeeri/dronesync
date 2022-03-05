import "entities/creature" for Creature
import "extra/combat" for Attack
import "core/graph" for WeightedZone, BFS, AStar, DijkstraMap

class PlayerEntity is Creature {
  construct new(config) {
    super()
    init(config)
  }

  construct new() {
    super()
    init({})
  }

  init(config) {
    super.init(config)
    this["targetGroup"].add("enemy")
    this["melee"] = Attack.stun(this)
  }

  action { _action }
  action=(v) { _action = v }

  update() {
    var action = _action
    _action = null
    return action
  }

  endTurn() {
    super.endTurn()
    var graph = WeightedZone.new(ctx)
    this["dijkstra"] = DijkstraMap.search(graph, pos)
  }
}

