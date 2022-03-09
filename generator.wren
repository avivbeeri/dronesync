import "math" for Vec
import "json" for JSON
import "io" for FileSystem
import "core/rng" for RNG
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
import "./roomGenerator" for GrowthRoomGenerator

class RoomGenerator {
  static generate() {
    return RoomGenerator.init().generate()
  }

  construct init() {}
  createWorld() {
    var strategy = EnergyStrategy.new()
    var map = TileMap.init()
    map.default = { "OOB": true, "solid": true }

    var world = World.new(strategy)
    world["objective"] = false
    world.pushZone(Zone.new(map))
    world.active.postUpdate.add(RemoveDefeated)
    world.active.postUpdate.add(CompressLightMap)
    world.active.postUpdate.add(GameEndCheck)
    var zone = world.active
    return world
  }
  newTile(room, solid) {
    return Tile.new({
      "room": room,
      "solid": solid,
      "blockSight": solid,
      "visible": "unknown",
      "kind": solid ? "wall" : "floor",
      "activeEffects": []
    })
  }
  generate() {
    var world = createWorld()
    var zone = world.active
    var generated = GrowthRoomGenerator.generate()
    var rooms = generated[0]
    var doors = generated[1]

    var candidates = []
    for (room in rooms) {
      if (room.neighbours.count == 1) {
        candidates.add(room)
      }
    }
    var start = RNG.sample(candidates)

    var player = zone.addEntity("player", PlayerEntity.new())
    player.pos = Vec.new(start.x + 1, start.y + 1)

    var enemyCount = 0
    for (room in rooms) {
      var wx = room.x
      var wy = room.y
      var width = wx + room.z
      var height = wy + room.w
      for (y in wy...height) {
        for (x in wx...width) {
          if (x == wx || x == width - 1 || y == wy || y == height - 1) {
            zone.map[x, y] = newTile(room, true)
          } else {
            zone.map[x, y] = newTile(room, false)
          }
        }
      }
    }
    for (door in doors) {
      // room?
      zone.map[door.x, door.y] = newTile(null, false)
    }

    var guardStart = getRandomWorldPosition(rooms)
    var guardEnd = getRandomWorldPosition(rooms)
    var guard = zone.addEntity(Guard.new({
      "patrol": [
        guardStart,
        guardEnd
      ]
    }))
    guard.pos = guardStart * 1
    /*
    guard.pos.x = start.x + start.z - 3
    guard.pos.y = start.y + start.w - 3
    */

    var drone = zone.addEntity("drone", DroneEntity.new())
    drone.pos.x = player.pos.x + 1
    drone.pos.y = player.pos.y


    var lightMaps = [
      UpdateVision.update(zone),
      UpdateVision.update(zone, drone, 4)
    ]
    CompressLightMap.update(zone)
    return world
  }

  getRandomWorldPosition(rooms) {
    var targetRoom = RNG.sample(rooms)
    var wx = targetRoom.x
    var wy = targetRoom.y
    var width = wx + targetRoom.z
    var height = wy + targetRoom.w

    var tile = null
    tile = Vec.new(RNG.int(wx + 1, width - 2), RNG.int(wy + 1, height - 2))
    return tile
  }
}

class StaticGenerator {
  static createWorld() {
    var strategy = EnergyStrategy.new()
    var map = TileMap.init()
    map.default = { "OOB": true, "solid": true }

    var world = World.new(strategy)
    world["objective"] = false
    world.pushZone(Zone.new(map))
    world.active.postUpdate.add(RemoveDefeated)
    world.active.postUpdate.add(CompressLightMap)
    world.active.postUpdate.add(GameEndCheck)
    var zone = world.active

    var player = zone.addEntity("player", PlayerEntity.new())
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
            "blockSight": solid,
            "visible": "unknown",
            "kind": solid ? "wall" : "floor",
            "activeEffects": []
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
            "blockSight": true,
            "kind": "wall",
            "activeEffects": []
          })
        }
      }
      map[2, 2] = Tile.new({
        "solid": false,
        "visible": "unknown",
        "activeEffects": [],
        "kind": "exit"
      })
      map[mapWidth - 2, mapHeight - 2] = Tile.new({
        "solid": true,
        "visible": "unknown",
        "blockSight": false,
        "activeEffects": [],
        "kind": "goal"
      })

      player.pos.x = 2
      player.pos.y = 6
    }
    return world
  }

}
