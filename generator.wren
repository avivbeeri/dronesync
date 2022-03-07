import "json" for JSON
import "io" for FileSystem
import "core/entity" for StackEntity
import "core/display" for Display
import "core/config" for Config
import "core/world" for World, Zone
import "core/director" for EnergyStrategy
import "core/map" for TileMap, Tile
import "./logic" for RemoveDefeated, GameEndCheck, UpdateVision, CompressLightMap
import "./entities/player" for PlayerEntity
import "./entities/drone" for DroneEntity
import "./entities/guard" for Guard

class StaticGenerator {
  static createWorld() {
    var strategy = EnergyStrategy.new()
    var map = TileMap.init()
    map.default = { "OOB": true }

    var world = World.new(strategy)
    world["objective"] = false
    world.pushZone(Zone.new(map))
    world.active.postUpdate.add(RemoveDefeated)
    world.active.postUpdate.add(CompressLightMap)
    world.active.postUpdate.add(GameEndCheck)
    var zone = world.active
    var player = PlayerEntity.new()
    zone.addEntity("player", player)
    var guard
    /*
    guard = zone.addEntity(Guard.new())
    guard.pos.x = 1
    guard.pos.y = 1
    */
    guard = zone.addEntity(Guard.new())
    guard.pos.x = 18
    guard.pos.y = 1
    guard = zone.addEntity(Guard.new())
    guard.pos.x = 18
    guard.pos.y = 18

    var drone = zone.addEntity("drone", DroneEntity.new())
    drone.pos.x = 15
    drone.pos.y = 15
/*
    // Is there a save.json?
    var save = Fiber.new {
      var path = FileSystem.prefPath("avivbeeri", "dronesync")
      var result = FileSystem.load("%(path)save.json")
      return JSON.decode(result)
    }.try()
      }
      */
      var save = null
    if (save is Map) {
      for (key in save["map"].keys) {
        zone.map.tiles[Num.fromString(key)] = Tile.new(save["map"][key])
      }
      player.pos.x = save["player"]["x"]
      player.pos.y = save["player"]["y"]
      for (key in save["player"].keys) {
        if (key != "x" && key != "y") {
          player.data[key] = save["player"][key]
        }
      }
    } else {
      // else do the generate
      var mapHeight = Config["map"]["height"]
      var mapWidth = Config["map"]["width"]
      for (y in 0...mapHeight) {
        for (x in 0...mapWidth) {
          var solid = x == 0 || y == 0 || x == mapWidth - 1 || y == mapHeight - 1
          map[x, y] = Tile.new({
            "solid": solid,
            "visible": "unknown",
            "kind": solid ? "wall" : "floor"
          })
        }
      }

      var size = 3
      var startX = (mapWidth - size) / 2
      var startY = (mapHeight - size) / 2
      for (dy in 0...size) {
        for (dx in 0...size) {
          map[startX + dx, startY + dy] = Tile.new({
            "solid": true,
            "kind": "wall"
          })
        }
      }
      map[2, 2] = Tile.new({
        "solid": false,
        "visible": "unknown",
        "kind": "exit"
      })
      map[mapWidth - 2, mapHeight - 2] = Tile.new({
        "solid": true,
        "visible": "unknown",
        "kind": "goal"
      })

      player.pos.x = 2
      player.pos.y = 6
    }


    UpdateVision.update(zone)
    return world
  }

}
