import "json" for JSON
import "io" for FileSystem

import "extra/events" for GameEndEvent
import "./events" for EscapeEvent
import "core/dataobject" for DataObject

class RemoveDefeated {
  static update(ctx) {
    ctx.entities
    .where {|entity| entity.has("stats") && entity["stats"].get("hp") <= 0 }
    .each {|entity|
      entity.alive = false
      /*
      if (entity.has("loot") && !entity["loot"].isEmpty) {
        System.print("dropping loot")
        System.print(entity["loot"])
        var loot = RNG.sample(entity["loot"])
        var lootEntity = ctx.addEntity(Collectible.new(loot))
        lootEntity.pos = entity.pos
      }
      */
    }
  }
}

class GameEndCheck {
  static update(ctx) {
    var player = ctx.getEntityByTag("player")
    if (!player || !player.alive) {
      ctx.events.add(GameEndEvent.new(false))
      ctx.parent.gameover = true
      return
    }
    var escaped = ctx.events.count > 0 && ctx.events.any {|event| event is EscapeEvent }
    if (escaped) {
      // TODO: Evaluate mission success
      ctx.events.add(GameEndEvent.new(ctx.parent["objective"]))
      ctx.parent.gameover = true
      return
    }
  }
}
