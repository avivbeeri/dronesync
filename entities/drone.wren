import "entities/creature" for Creature
import "core/action" for Action
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
  }

  action { _action }
  action=(v) { _action = v }

  update() {
    return Action.none
    /*
    var action = _action
    _action = null
    return action
    */
  }

  endTurn() {
    super.endTurn()
    this["lightMap"] = UpdateVision.update(ctx, this, 4)
  }
}

