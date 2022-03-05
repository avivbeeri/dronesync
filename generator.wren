import "json" for JSON
import "io" for FileSystem
import "core/entity" for StackEntity
import "core/display" for Display
import "core/config" for Config
import "core/world" for World, Zone
import "core/director" for EnergyStrategy
import "core/map" for TileMap, Tile
import "./logic" for RemoveDefeated
import "./entities/player" for PlayerEntity
import "./entities/guard" for Guard

class StaticGenerator {
  static createWorld() {
    var strategy = EnergyStrategy.new()
    var map = TileMap.init()

    var world = World.new(strategy)
    world.pushZone(Zone.new(map))
    world.active.postUpdate.add(RemoveDefeated)
    var zone = world.active
    var player = PlayerEntity.new()
    zone.addEntity("player", player)
    var guard = zone.addEntity(Guard.new())
    guard.pos.x = 1
    guard.pos.y = 1
    guard = zone.addEntity(Guard.new())
    guard.pos.x = 18
    guard.pos.y = 1
    guard = zone.addEntity(Guard.new())
    guard.pos.x = 18
    guard.pos.y = 18

    // Is there a save.json?
    var save = Fiber.new {
      var path = FileSystem.prefPath("avivbeeri", "dronesync")
      var result = FileSystem.load("%(path)save.json")
      return JSON.decode(result)
    }.try()
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
            "kind": solid ? "wall" : "floor"
          })
        }
      }

      player.pos.x = 10
      player.pos.y = 15
      player["water"] = 18
    }

    return world
  }

}
