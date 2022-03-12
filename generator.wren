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
import "core/graph" for BFSNeutral, Graph, AStar, SquareGrid
import "./logic" for RemoveDefeated, GameEndCheck, UpdateVision, CompressLightMap, LightEverything
import "./entities/player" for PlayerEntity
import "./entities/drone" for DroneEntity
import "./entities/guard" for Guard
import "./roomGenerator" for GrowthRoomGenerator

var SPAWN_DIST = [ 0, 0, 1, 1, 1, 1, 2 ]
// var CRATES = (0...9).map {|i| String.fromCodePoint(9622 + i) }.toList
var CRATES = [ " ", String.fromCodePoint(0x2588)]

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
    map.default = { "OOB": true, "solid": true, "blockSight": true }

    var world = World.new(strategy)
    world["objective"] = false
    world["time"] = 0
    world["alerts"] = 0
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
      generateRoom(zone, room, start)
    }
    for (door in doors) {
      // room?
      // zone.map[door.x, door.y] = newTile(null, false)
      zone.map[door.x, door.y] = Tile.new({
        "solid": false,
        "blockSight": true,
        "visible": "unknown",
        "activeEffects": [],
        "kind": "door",
        "level": 0,
        "locked": false
      })
    }

    var pos = getRandomRoomPosition(zone, start)
    zone.map[pos] = Tile.new({
      "solid": false,
      "visible": "unknown",
      "activeEffects": [],
      "kind": "exit"
    })
    player.pos.x = pos.x
    player.pos.y = pos.y

    for (room in rooms) {
      spawnGuardsInRoom(zone, room, start)
    }

/*
    var drone = zone.addEntity("drone", DroneEntity.new({ "stats": { "speed": 12 } }))
    drone.pos.x = player.pos.x + 1
    drone.pos.y = player.pos.y
    */

    var path = getCriticalPath(rooms, start)
    var console = getRandomRoomPosition(zone, path[-1])
    zone.map[console] = Tile.new({
      "solid": false,
      "visible": "unknown",
      "blockSight": false,
      "activeEffects": [],
      "kind": "goal"
    })

    var graph = SquareGrid.new(zone.map)
    var scoreSearch = AStar.search(graph, player.pos, console)
    path = AStar.reconstruct(scoreSearch[0], player.pos, console)
    world["minDistance"] = path.count
    System.print(path.count)
    zone.map[console]["solid"] = true


    var lightMaps = [
      UpdateVision.update(zone),
    ]
    CompressLightMap.update(zone)
    return world
  }
  placeHorizontal(y, start, length, place) {
    for (x in start...(start + length)) {
      place.call(x, y)
    }
  }
  placeVertical(x, start, length, place) {
    for (y in start...(start + length)) {
      place.call(x, y)
    }
  }

  generateRoom(zone, room, start) {
    var wx = room.x
    var wy = room.y
    var width = wx + room.z
    var height = wy + room.w
    var type = RNG.sample(["empty", "cargo", "island", "island"])
    // Generate room walls
    for (y in wy...height) {
      for (x in wx...width) {
        if (x == wx || x == width - 1 || y == wy || y == height - 1) {
          zone.map[x, y] = newTile(room, true)
        } else {
          zone.map[x, y] = newTile(room, false)
        }
      }
    }

    if (type == "empty") {
      for (y in wy...height) {
        for (x in wx...width) {
          if (x > wx && x < width - 1 && y > wy && y < height - 1) {
            zone.map[x, y] = newTile(room, false)
          }
        }
      }
    }
    if (type == "bridge") {

    }
    if (type == "island") {
      var dimX = RNG.int(4, (room.z - 2)) - 1
      var dimY = RNG.int(4, (room.w - 2)) - 1
      var setX = ((room.z - dimX) / 2).floor
      var setY = ((room.w - dimY) / 2).floor

      if (RNG.float() < 0.5) {
        placeVertical(wx + setX, wy + setY, dimY) {|x, y|
          zone.map[x, y] = newTile(room, true)
        }
        placeVertical(wx + room.z - setX - 1, wy + setY, dimY) {|x, y|
          zone.map[x, y] = newTile(room, true)
        }
      } else {
        placeHorizontal(wy + setY, wx + setX, dimX) {|x, y|
          zone.map[x, y] = newTile(room, true)
        }
        placeHorizontal(wy + room.w - setY - 1, wx + setX, dimX) {|x, y|
          zone.map[x, y] = newTile(room, true)
        }
      }
    }
    if (type == "cargo") {
      var modW = ((room.z - 2) % 4)
      var modH = ((room.w - 2) % 4)
      var crateW = ((room.z - 2) / 4).floor
      var crateH = ((room.w - 2) / 4).floor

      for (j in 0...crateH) {
        var offY = RNG.int(modH + 1)
        for (i in 0...crateW) {
          var offX = RNG.int(modW + 1)
          for (dy in 0...2) {
            for (dx in 0...2) {
              var x = 2 + wx + i * 4 + dx + offX
              var y = 2 + wy + j * 4 + dy + offY
              zone.map[x, y] = newTile(room, true)
              zone.map[x, y]["kind"] = "crate"
              zone.map[x, y]["symbol"] = RNG.sample(CRATES)
            }
          }
        }
      }
      // test accessibilities
    }
    if (RNG.float() < 0.6) {
      zone.map[getRandomRoomPosition(zone, room)]["item"] = RNG.float() < 0.9 ? "coin" : "smokebomb"
    }
  }
  spawnGuardsInRoom(zone, room, start) {
    var spawnTotal = RNG.sample(SPAWN_DIST)
    for (i in 0...spawnTotal) {
      if (room == start) {
        break
      }
      var target = room
      if (RNG.float(1) < 0.5) {
        target = RNG.sample(room.neighbours)
        if (target == start) {
          target = room
        }
      }

      var guardStart = getRandomRoomPosition(zone, room)
      var guardEnd = null
      while (guardEnd == null || (guardStart - guardEnd).manhattan < 3) {
        guardEnd = getRandomRoomPosition(zone, target)
      }
      var guard = zone.addEntity(Guard.new({
        "patrol": [
          guardStart,
          guardEnd
        ]
      }))
      guard.pos = guardStart * 1
    }
  }

  getRandomRoomPosition(zone, targetRoom) { getRandomRoomPosition(zone, targetRoom, false) }
  getRandomRoomPosition(zone, targetRoom, allowSolid) {
    var wx = targetRoom.x
    var wy = targetRoom.y
    var width = wx + targetRoom.z
    var height = wy + targetRoom.w
    if (allowSolid) {
      return Vec.new(RNG.int(wx + 1, width - 2), RNG.int(wy + 1, height - 2))
    } else {
      var roomTiles = []
      for (y in wy...height) {
        for (x in wx...width) {
          if (zone.map[x, y]["solid"]) {
            continue
          }
          roomTiles.add(Vec.new(x, y))
        }
      }
      return RNG.sample(roomTiles)
    }
  }

  getRandomWorldPosition(rooms) {
    var targetRoom = RNG.sample(rooms)
    return getRandomRoomPosition(targetRoom)
  }
}

class StaticGenerator {
  static generate() {
    var strategy = EnergyStrategy.new()
    var map = TileMap.init()
    map.default = { "OOB": true, "solid": true, "blockSight": true }

    var world = World.new(strategy)
    world["objective"] = false
    world.pushZone(Zone.new(map))
    world.active.postUpdate.add(RemoveDefeated)
    world.active.postUpdate.add(GameEndCheck)
    var zone = world.active

    var player = zone.addEntity("player", PlayerEntity.new())
    var guard



    // else do the generate
    var mapHeight = 8
    var mapWidth = 24
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


    guard = zone.addEntity(Guard.new({ "patrol": [ Vec.new(mapWidth - 2, (mapHeight / 2). floor) ] }))
    guard.pos.x = mapWidth - 2
    guard.pos.y = (mapHeight / 2).floor

    for (y in 4..6) {
      map[18, y] = Tile.new({
        "solid": true,
        "blockSight": true,
        "kind": "wall",
        "activeEffects": []
      })
    for (y in 3..5) {
      map[16, y] = Tile.new({
        "solid": true,
        "blockSight": true,
        "kind": "wall",
        "activeEffects": []
      })
    }
    }

    player.pos.x = 1
    player.pos.y = (mapHeight / 2).floor
    LightEverything.update(zone)
    return world
  }

}
