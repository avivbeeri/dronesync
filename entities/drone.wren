import "core/action" for Action
import "actions" for SwapAction
import "entities/creature" for Creature
import "extra/combat" for Attack
import "core/graph" for WeightedZone, BFS, AStar, DijkstraMap
import "logic" for UpdateVision

class DroneEntity is Creature {
  construct new(config) {
    super(config)
  }

  construct new() {
    super()
  }

  init(config) {
    super.init(config)
    this["active"] = true
  }

  action { _action }
  action=(v) { _action = v }

  update() {
    _player = ctx.getEntityByTag("player")
    if (!_player["active"]) {
      var action = _action
      _action = null
      return action
    } else {
      return Action.none
    }
  }

  endTurn() {
    super.endTurn()
    if ((pos - _player.pos).length > 16) {
      this["lightMap"] = UpdateVision.update(ctx, this, 1)
      if (!_player["active"]) {
        System.print("Out of range")
        SwapAction.new(true).bind(this).perform()
      }
    } else {
      this["lightMap"] = UpdateVision.update(ctx, this, 4)
    }
  }
}

