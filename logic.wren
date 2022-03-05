import "json" for JSON
import "io" for FileSystem

import "core/dataobject" for DataObject
/*
import "./events" for GameEndEvent

class SaveHook {
  static update(zone) {
    for (event in zone.events) {
      if (event is SleepEvent) {
        // do sleep
        var path = FileSystem.prefPath("avivbeeri", "garden")
        // For debug only
        // path = "."

        var player = zone.getEntityByTag("player")


        var data = {}
        var playerData = DataObject.new(player.data)
        playerData["x"] = player.pos.x
        playerData["y"] = player.pos.y
        data["player"] = playerData.data
        data["map"] = {

        }
        for (tileKey in zone.map.tiles.keys) {
          data["map"][tileKey.toString] = zone.map.tiles[tileKey].data
        }
        JSON.save("%(path)save.json", data)
      }
    }
  }
}
*/

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
