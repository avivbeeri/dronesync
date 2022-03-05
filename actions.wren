import "math" for Vec, M
import "core/action" for Action, ActionResult
import "./extra/events" for MoveEvent
import "./events" for LogEvent, AttackEvent
import "./extra/combat" for Attack, AttackType, AttackResult

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
      var target = false
      if (!solid) {
        var occupying = getOccupying(source.pos)
        if (occupying.count > 0) {
          solid = solid || occupying.any {|entity| entity.has("solid") }
          target = occupying.any {|entity| entity.has("stats") }
        }
      }
      if (solid || target) {
        source.pos = old
        if (_alt) {
          result = ActionResult.alternate(_alt)
        }
      }
      if (!_alt && target) {
        if (source.has("stats")) { // TODO: consider narrowing condition
          result = ActionResult.alternate(AttackAction.new(source.pos + _dir, Attack.melee(source)))
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

class AttackAction is Action {
  construct new(location, attack) {
    super()
    _location = location
    _attack = attack
  }

  location { _location }

  perform() {
    var location = _location
    var occupying = ctx.getEntitiesAtTile(location.x, location.y).where {|entity| entity.has("stats") }

    if (occupying.count == 0) {
      return ActionResult.failure
    }
    occupying.each {|target|
      // Attack is based on attack type - weapon

      // Some targets might be immune to an attack, so we
      // allow it to be cancelled
      /*
      var attackEvent = AttackEvent.new(source, target, _attack, attackResult)
      attackEvent = target.notify(attackEvent)
      */

      if (_attack.attackType == AttackType.melee && target["awareness"] < 10) {
        // Attack succeeds and target is stunned
        target["stunTimer"] = 5
        ctx.events.add(LogEvent.new("%(source) stunned %(target)"))
      } else {
        var currentHP = target["stats"].base("hp")
        var defence = target["stats"].get("def")
        var damage = M.max(0, _attack.damage - defence)

        var attackResult = AttackResult.success
        if (_attack.damage <= 0) {
          attackResult = AttackResult.inert
        } else if (damage == 0) {
          attackResult = AttackResult.blocked
        }

        var attackEvent = AttackEvent.new(source, target, _attack, attackResult)
        attackEvent = target.notify(attackEvent)

        if (!attackEvent.cancelled) {
          ctx.events.add(LogEvent.new("%(source) attacked %(target)"))
          ctx.events.add(attackEvent)
          target["stats"].decrease("hp", damage)
          ctx.events.add(LogEvent.new("%(source) did %(damage) damage."))
          if (target["stats"].get("hp") <= 0) {
            ctx.events.add(LogEvent.new("%(target) was defeated."))
          }
        }
      }
    }
    return ActionResult.success
  }
}
