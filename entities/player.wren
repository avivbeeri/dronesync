import "items" for ItemFactory
import "core/action" for Action
import "entities/creature" for Creature
import "extra/combat" for Attack
import "core/graph" for WeightedZone, BFS, AStar, DijkstraMap
import "logic" for UpdateVision, UpdateMapEffects

class PlayerEntity is Creature {
  construct new(config) {
    super(config)
  }

  construct new() {
    super()
  }

  init(config) {
    super.init(config)
    name = "you"
    this["targetGroup"].add("enemy")
    this["melee"] = Attack.stun(this)
    this["active"] = true
    this["inventory"] = [
      ItemFactory.get("drone"),
      ItemFactory.get("coin", 1),
      ItemFactory.get("smokebomb", 3)
    ]
  }

  action { _action }
  action=(v) { _action = v }

  update() {
    if (!this["dijkstra"]) {
      var graph = WeightedZone.new(ctx)
      this["dijkstra"] = DijkstraMap.search(graph, pos)
    }

    if (this["active"]) {
      var action = _action
      _action = null
      return action
    } else {
      return Action.none
    }
  }

  endTurn() {
    super.endTurn()
    ctx.parent["time"] = ctx.parent["time"] + 1
    var graph = WeightedZone.new(ctx)
    UpdateMapEffects.update(ctx)
    this["dijkstra"] = DijkstraMap.search(graph, pos)
    this["lightMap"] = UpdateVision.update(ctx)
  }
}

