import "json" for JSON
import "io" for FileSystem

import "core/dataobject" for DataObject
import "./events" for SleepEvent

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
