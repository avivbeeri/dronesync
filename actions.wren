import "math" for Vec, M
import "core/action" for Action, ActionResult, MultiAction
import "core/rng" for RNG
import "core/dir" for NSEW
import "core/dataobject" for DataObject
import "util" for Find
import "items" for ItemFactory
import "./extra/events" for MoveEvent
import "./events" for LogEvent, AttackEvent, EscapeEvent, GoalEvent, QueryEvent
import "./extra/combat" for Attack, AttackType, AttackResult
import "./entities/player" for PlayerEntity

class QueryAction is Action {
  construct new(pos) {
    super()
    _pos = pos
  }
  perform() {
    if (ctx.map[_pos]["query"]) {
      ctx.events.add(QueryEvent.new(source, ctx.map[_pos]["query"]))
    }
    return ActionResult.failure
  }
}

class PickupAction is Action {
  construct new(pos) {
    super()
    _pos = pos
  }
  perform() {
    if (!source.has("inventory")) {
      return ActionResult.success
    }
    var entities = ctx.getEntitiesAtTile(_pos)
    for (target in entities) {
      if (source is PlayerEntity && target is DroneEntity) {
        source["inventory"][0]["quantity"] = 1
        ctx.events.add(LogEvent.new("%(source) picked up the drone"))
        ctx.removeEntity(target)
      }
    }
    var loot = ctx.map[source.pos]["item"]
    if (loot) {
      ctx.map[source.pos]["item"] = null

      var item = Find.inList(source["inventory"]) {|entry| entry["id"] == loot }
      if (item) {
        item["quantity"] = item["quantity"] + 1
      } else {
        item = factory(loot)
        source["inventory"].add(item)
      }
      var displayName = item["displayName"]
      ctx.events.add(LogEvent.new("%(source) picked up a %(displayName)"))
    }
    return ActionResult.success
  }
  factory(id) {
    return ItemFactory.get(id)
  }
}

class SpawnAction is Action {
  construct new(spawnable, pos) {
    super()
    _spawnable = spawnable
    _pos = pos
    _tag = null
  }
  construct new(spawnable, pos, tag) {
    super()
    _spawnable = spawnable
    _pos = pos
    _tag = tag
  }

  factory(id) {
    return DroneEntity.new({ "stats": { "speed": 12 } })
  }

  perform() {
    var entity = factory(_spawnable)
    if (_tag) {
      ctx.addEntity(_tag, entity)
    } else {
      ctx.addEntity(null, entity)
    }
    entity.pos.x = _pos.x
    entity.pos.y = _pos.y
    ctx.events.add(LogEvent.new("%(source) deployed the %(entity)"))
    return ActionResult.success
  }

}

class SwapAction is Action {
  construct new() {
    super()
    _force = false
  }
  construct new(force) {
    super()
    _force = force
  }
  perform() {
    var player = ctx.getEntityByTag("player")
    var drone = ctx.getEntityByTag("drone")
    if ((player.pos - drone.pos).length > drone["range"] && !_force) {
      return ActionResult.failure
    }

    var primary = player["active"] ? player : drone
    player["active"] = !player["active"]
    var aIndex = ctx.entities.indexOf(player)
    var bIndex = ctx.entities.indexOf(drone)
    ctx.entities.swap(aIndex, bIndex)
    drone.priority = primary.priority
    player.priority = primary.priority

    var name = player["active"] ? "disabled" : "enabled"
    ctx.events.add(LogEvent.new("Drone control is %(name)"))
    // We fail here because this doesn't advance
    return ActionResult.failure
  }

}

class ObjectiveAction is Action {
  construct new() {
    super()
  }
  perform() {
    if (ctx.parent["objective"]) {
      return ActionResult.failure
    }
    ctx.events.add(LogEvent.new("%(source) completed the objective!"))
    ctx.events.add(GoalEvent.new())
    ctx.parent["objective"] = true
    return ActionResult.success
  }
}
class NoiseAction is Action {
  construct new(pos, range) {
    super()
    _pos = pos
    _range = range
  }
  perform() {
    for (entity in ctx.entities) {
      if (entity.has("senses") && (_pos - entity.pos).length <= _range) {
        entity["senses"]["noise"] = _pos
      }
    }
    ctx.events.add(LogEvent.new("%(source) caused a noise to occur."))

    return ActionResult.success
  }
}
class EscapeAction is Action {
  construct new() {
    super()
  }
  perform() {
    ctx.events.add(LogEvent.new("%(source) escaped!"))
    ctx.events.add(EscapeEvent.new())
    return ActionResult.success
  }
}
class UseItemAction is Action {
  construct new(itemId, args) {
    super()
    _itemId = itemId
    _args = args
  }

  getItemAction(data) {
    if (_itemId == "coin") {
      return NoiseAction.new(_args["center"], 4)
    }
    if (_itemId == "smokebomb") {
      return SmokeAction.new(_args["selection"])
    }
    if (_itemId == "drone") {
      return MultiAction.new([
        SpawnAction.new("drone", _args["selection"][0], "drone"),
        SwapAction.new()
      ], true)
    }
    return null
  }

  perform() {
    var inventory = source["inventory"]
    if (!inventory) {
      return ActionResult.failure
    }
    var itemIndex = -1
    for (index in 0...inventory.count) {
      if (inventory[index]["id"] == _itemId) {
        itemIndex = index
        break
      }
    }
    if (itemIndex == -1) {
      return ActionResult.failure
    }
    var item = inventory[itemIndex]
    if (!item["quantity"] || item["quantity"] > 0) {
      // Execute item
      var itemAction = getItemAction(item)
      if (!itemAction) {
        Fiber.abort("Attempted to execute invalid action %(_itemId)")
      }
      itemAction.bind(source)
      var itemName = item["displayName"]
      ctx.events.add(LogEvent.new("%(source) used %(itemName)"))
      var result = itemAction.perform()
      if (result.succeeded) {
        if (item["quantity"] > 0) {
          item["quantity"] = item["quantity"] - 1
          if (item["quantity"] <= 0 && !item["eternal"]) {
            inventory.removeAt(itemIndex)
          }
        }
        if (result.alternate) {
          return result
        }
        return ActionResult.success
      }
    }
    return ActionResult.failure
  }
}

class WakeAction is Action {
  construct new() {
    super()
  }

  getOccupying(pos) {
    return ctx.getEntitiesAtTile(pos.x, pos.y).where {|entity| entity != source }
  }

  perform() {
    source["stunTimer"] = source["stunTimer"] - 1
    if (source["stunTimer"] == 0) {
      ctx.events.add(LogEvent.new("%(source) woke up!"))
      // Throw the player
      var player = ctx.getEntityByTag("player")
      if (player.pos == source.pos) {
        var dir = RNG.shuffle(DataObject.copyValue(NSEW.values.toList))
        for (d in dir) {
          var tile = ctx.map[player.pos + d]
          if (!tile["solid"]) {
            var targets = getOccupying(player.pos + d).where {|entity| entity.has("stats") && entity["stunTimer"] == 0 }.toList
            player.pos = player.pos + d
            for (target in targets) {
              target["stunTimer"] = 2
            }
            if (targets.count == 0) {
              ctx.events.add(LogEvent.new("%(source) threw you off them."))
            } else {
              ctx.events.add(LogEvent.new("%(source) threw you into %(targets)"))
            }

            break
          }
        }
      }
    }
    return ActionResult.success
  }
}

class SmokeAction is Action {
  construct new(tiles) {
    super()
    _tiles = tiles
  }
  perform() {
    ctx.events.add(LogEvent.new("%(source) detonated a smokebomb!"))
    // var entities = ctx.getEntitiesAtTile(pos.x, pos.y)
    for (pos in _tiles) {
      var tile = ctx.map[pos]
      var original = tile["blockSight"]
      tile["blockSight"] = true
      tile["visible"] = "hidden"
      tile["activeEffects"].add({
        "id": "smoke",
        "duration": 15,
        "onComplete": Fn.new {
          ctx.map[pos]["blockSight"] = original
        }
      })
    }
    return ActionResult.success
  }
}

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

    var occupying = []
    if (source.pos != old) {
      var solid = ctx.isSolidAt(source.pos)
      var target = false
      var collectible = false
      if (!solid) {
        occupying = getOccupying(source.pos)
        if (occupying.count > 0) {
          solid = solid || occupying.any {|entity| entity.has("solid") }
          target = occupying.any {|entity| entity.has("stats") && entity["stunTimer"] == 0 }
          collectible = occupying.any {|entity| entity.has("loot") }
          System.print(collectible)
        }
        if (source is PlayerEntity && ctx.map[source.pos]["query"]) {
          result = ActionResult.alternate(QueryAction.new(source.pos))
        } else if (source is PlayerEntity && ctx.map[source.pos]["kind"] == "exit") {
          result = ActionResult.alternate(EscapeAction.new())
        }
      }
      collectible = collectible || ctx.map[source.pos]["item"]

      if (solid || (target && !collectible)) {
        source.pos = old
        if (source is PlayerEntity && ctx.map[source.pos + source.vel]["kind"] == "goal") {
          result = ActionResult.alternate(ObjectiveAction.new())
        } else {
          if (_alt) {
            result = ActionResult.alternate(_alt)
          }
        }
      }
      if (!_alt) {
        if (!solid && collectible) {
          result = ActionResult.alternate(PickupAction.new(source.pos))
        } else if (target) {
          if (source.has("stats") && source.has("melee")) { // TODO: consider narrowing condition
            result = ActionResult.alternate(AttackAction.new(source.pos + _dir, source["melee"]))
          }
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

      var attackResult = AttackResult.success
      if (_attack.attackType == AttackType.stun) {
        if (target["awareness"] < 10) {
          // Attack succeeds and target is stunned
          target["stunTimer"] = target["awareness"] > 2 ? 5 : 10
          ctx.events.add(LogEvent.new("%(source) stunned %(target)"))
        } else {
          //
          attackResult = AttackResult.blocked
        }
      } else if (_attack.attackType == AttackType.direct) {
        var currentHP = target["stats"].base("hp")
        var defence = target["stats"].get("def")
        var damage = M.max(0, _attack.damage - defence)

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

import "./entities/drone" for DroneEntity
