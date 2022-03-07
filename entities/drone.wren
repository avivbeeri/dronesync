import "core/action" for Action
import "entities/creature" for Creature
import "extra/combat" for Attack
import "core/graph" for WeightedZone, BFS, AStar, DijkstraMap
import "logic" for UpdateVision

class DroneEntity is Creature {
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
    this["active"] = true
  }

  action { _action }
  action=(v) { _action = v }

  update() {
    var player = ctx.getEntityByTag("player")
    if (!player["active"]) {
      var action = _action
      _action = null
      return action
    } else {
      return Action.none
    }
  }

  endTurn() {
    super.endTurn()
    this["lightMap"] = UpdateVision.update(ctx, this, 4)
  }
}

