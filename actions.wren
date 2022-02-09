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
      if (ctx.map[source.pos]["kind"] == "plant") {
        result = ActionResult.alternate(WaterAction.new(_dir))
      }
      if (solid) {
        source.pos = old
        if (_alt) {
          result = ActionResult.alternate(_alt)
        }
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
    for (y in 0...6) {
      for (x in 0...9) {
        var tile = ctx.map[x, y]
        if (tile["kind"] == "plant") {
          tile["watered"] = false
        }
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
      tile["solid"] = true
      tile["kind"] = "plant"
      tile["watered"] = false
      tile["stage"] = 1
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
    if (tile["kind"] == "plant" && tile["stage"] > 3) {
      tile["solid"] = false
      tile["kind"] = "floor"
      tile["watered"] = null
      tile["stage"] = null
      // TODO: Emit an event for handling that we picked up something
    } else {
      result = ActionResult.failure
    }

    return result
  }
}

class WaterAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }

  perform() {
    var result = ActionResult.success
    var tile = ctx.map[source.pos + _dir]
    if (tile["kind"] == "plant") {
      if (tile["stage"] > 3) {
        result = ActionResult.alternate(HarvestAction.new(_dir))
      } else if (!tile["watered"]) {
        tile["stage"] = tile["stage"] + 1
        tile["watered"] = true
      }
    } else {
      result = ActionResult.failure
    }

    return result
  }
}
