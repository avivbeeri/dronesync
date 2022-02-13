import "math" for Vec
import "core/action" for Action, ActionResult
import "./extra/events" for MoveEvent

class MoveAction is Action {
  construct new(dir, alwaysSucceed, alt) {
    super()
    _dir = dir
    _succeed = alwaysSucceed
    _alt = alt
  }
  construct new(dir, alwaysSucceed) {
    super()
    _dir = dir
    _succeed = alwaysSucceed
  }

  construct new(dir) {
    super()
    _dir = dir
    _succeed = false
  }

  getOccupying(pos) {
    return ctx.getEntitiesAtTile(pos.x, pos.y).where {|entity| entity != source }
  }

  perform() {
    var old = source.pos * 1
    source.vel = _dir
    source.pos.x = source.pos.x + source.vel.x
    source.pos.y = source.pos.y + source.vel.y

    var result

    if (source.pos != old) {
      var solid = ctx.isSolidAt(source.pos)
      if (!solid) {
        var occupying = getOccupying(source.pos)
        if (occupying.count > 0) {
          solid = solid || occupying.any {|entity| entity.has("solid") }
        }
      }
      if (solid) {
        source.pos = old
        if (ctx.map[source.pos]["kind"] == "plant") {
          result = ActionResult.alternate(WaterAction.new(_dir))
        }
        if (_alt) {
          result = ActionResult.alternate(_alt)
        }
      }
      if (ctx.map[source.pos]["kind"] == "door") {
        result = ActionResult.alternate(SleepAction.new())
      }
      if (ctx.map[source.pos]["kind"] == "well") {
        result = ActionResult.alternate(RefillAction.new())
      }
    }

    if (!result) {
      if (source.pos != old) {
        ctx.events.add(MoveEvent.new(source))
        result = ActionResult.success
      } else if (_succeed) {
        result = ActionResult.alternate(Action.none)
      } else {
        result = ActionResult.failure
      }
    }

    if (source.vel.length > 0) {
      source.vel = Vec.new()
    }
    return result
  }
}

class SleepAction is Action {
  construct new() {
    super()
  }

  perform() {
    for (tile in ctx.map.tiles.values) {
      if (tile["kind"] == "plant") {
        if (tile["watered"]) {
          tile["stage"] = tile["stage"] + 1
        }
        tile["watered"] = false
        tile["age"] = tile["age"] + 1
      }
    }
    return ActionResult.success
  }
}

class SowAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }

  perform() {
    var result = ActionResult.success
    var tile = ctx.map[source.pos + _dir]
    if (tile["kind"] != "plant") {
      tile["solid"] = false
      tile["kind"] = "plant"
      tile["watered"] = false
      tile["stage"] = 0
      tile["age"] = 0
      System.print("sowing...")
    } else {
      result = ActionResult.failure
    }

    return result
  }
}
class HarvestAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }

  perform() {
    var result = ActionResult.success
    var tile = ctx.map[source.pos + _dir]
    if (tile["kind"] == "plant" && tile["stage"] >= 3) {
      tile["solid"] = false
      tile["kind"] = "floor"
      tile["watered"] = null
      tile["stage"] = null
      tile["age"] = null
      // TODO: Emit an event for handling that we picked up something
    } else {
      result = ActionResult.failure
    }

    return result
  }
}

class RefillAction is Action {
  construct new() {
    super()
  }
  perform() {
    var tile = ctx.map[source.pos]
    if (tile["kind"] == "well") {
      source["water"] = 20
      return ActionResult.success
    }
    return ActionResult.failure
  }
}
class WaterAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }

  perform() {
    var result = ActionResult.success
    if (source["water"] <= 0) {
      result = ActionResult.failure
    } else {
      var tile = ctx.map[source.pos + _dir]
      if (tile["kind"] == "plant") {
        if (tile["stage"] >= 3) {
          result = ActionResult.alternate(HarvestAction.new(_dir))
        } else if (!tile["watered"]) {
          tile["watered"] = true
          // Kindness to the player
          source["water"] = source["water"] - 1
        }
      } else {
        result = ActionResult.failure
      }
    }

    return result
  }
}
