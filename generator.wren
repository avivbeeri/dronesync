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
import "core/graph" for BFSNeutral, Graph
import "./logic" for RemoveDefeated, GameEndCheck, UpdateVision, CompressLightMap
import "./entities/player" for PlayerEntity
import "./entities/drone" for DroneEntity
import "./entities/guard" for Guard
import "./roomGenerator" for GrowthRoomGenerator

class RoomGraph is Graph {
  construct new(rooms) {
    _rooms = {}
    for (room in rooms) {
      _rooms[room.id] = room
    }
  }
  [location] {
    return _rooms[location]
  }
  neighbours(location) {
    var room = _rooms[location]
    return room.neighbours.map {|room|
      return room.id
    }.toList
  }
}

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

  getCriticalPath(rooms, start) {
    var graph = RoomGraph.new(rooms)
    var search = BFSNeutral.search(graph, start.id)
    var maxId = -1
    var endPath
    var dist = 0
    for (room in rooms) {
      if (room.id == start.id) {
        continue
      }
      var path = BFSNeutral.reconstruct(search[0], start.id, room.id)
      if (path.count > dist) {
        dist = path.count
        maxId = room.id
        endPath = path
      }
    }

    var end = graph[maxId]

    // NOTE: endPath is in room IDs
    return endPath.map {|id| graph[id] }.toList
    // Pick end node
    // further point from the start ?
    // or min-distance?

    // Compute critical path to end point

    // Maybe do stuff with extra rooms
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
    zone.map[player.pos] = Tile.new({
      "solid": false,
      "visible": "unknown",
      "activeEffects": [],
      "kind": "exit"
    })

    for (room in rooms) {
      if (room == start) {
        continue
      }

      for (i in 0...RNG.int(3)) {
        var target = room
        if (RNG.float(1) < 0.5) {
          target = RNG.sample(room.neighbours)
        }
        var guardStart = getRandomRoomPosition(room)
        var guardEnd = getRandomRoomPosition(target)
        var guard = zone.addEntity(Guard.new({
          "patrol": [
            guardStart,
            guardEnd
          ]
        }))
        guard.pos = guardStart * 1
      }
    }

    var drone = zone.addEntity("drone", DroneEntity.new())
    drone.pos.x = player.pos.x + 1
    drone.pos.y = player.pos.y

    var path = getCriticalPath(rooms, start)
    var console = getRandomRoomPosition(path[-1])
    zone.map[console] = Tile.new({
      "solid": true,
      "visible": "unknown",
      "blockSight": false,
      "activeEffects": [],
      "kind": "goal"
    })


    var lightMaps = [
      UpdateVision.update(zone),
      UpdateVision.update(zone, drone, 4)
    ]
    CompressLightMap.update(zone)
    return world
  }

  getRandomRoomPosition(targetRoom) {
    var wx = targetRoom.x
    var wy = targetRoom.y
    var width = wx + targetRoom.z
    var height = wy + targetRoom.w

    var tile = null
    tile = Vec.new(RNG.int(wx + 1, width - 2), RNG.int(wy + 1, height - 2))
    return tile

  }
  getRandomWorldPosition(rooms) {
    var targetRoom = RNG.sample(rooms)
    return getRandomRoomPosition(targetRoom)
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
