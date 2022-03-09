import "math" for Vec, M
import "./core/rng" for RNG
import "./core/map" for Room
import "core/config" for Config

var MAX_ROOM_COUNT = 10

class GrowthRoomGenerator {
  static generate() {
    return GrowthRoomGenerator.init().generate()
  }

  construct init() {}
  generate() {
    // Level dimensions in tiles
    // 1-2) General constraints
    var maxRoomSize = 20
    var minRoomSize = 6
    var minRooms = 4
    var totalRooms = RNG.int(minRooms, MAX_ROOM_COUNT) + 1

    var mapHeight = Config["map"]["height"]
    var mapWidth = Config["map"]["width"]

    var doors = []

    // 3) A single room in the world (Library)
    var rooms = [ Room.new((mapWidth / 2).round, (mapHeight / 2).round, 7, 7) ]
    var door = null

    var attempts = 0
    while(rooms.count < totalRooms && attempts < 20) {
      attempts = attempts + 1

      // 4) Pass begins: Pick a base for this pass at random from existing rooms.
      var base = RNG.sample(rooms)
      // 5) Select a wall to grow from
      var dir = RNG.int(0, 4) // 0->4, left->up->right->down
      // 6)Make a new room
      var newRoom = Room.new(
        0, 0,
        RNG.int(minRoomSize, maxRoomSize),
        RNG.int(minRoomSize, maxRoomSize)
      )

      // 7) Place the room on the wall of the base
      if (dir == 0) {
        // left
        var offset = RNG.int(3 - newRoom.w, base.w - 3)
        newRoom.x = base.x - newRoom.z + 1
        newRoom.y = base.y + offset
        // 8-9) Check room for valid space compared to other rooms.
        if (!isSafeToPlace(rooms, base, newRoom)) {
          continue
        }


        // 10) Place a door in the overlapping range
        var doorTop = M.max(newRoom.y, base.y)
        var doorBottom = M.min(newRoom.y + newRoom.w, base.y + base.w)
        var doorRange = RNG.int(doorTop + 1, doorBottom - 1)
        door = Vec.new(base.x, doorRange)
      } else if (dir == 1) {
        // up
        var offset = RNG.int(3 - newRoom.z, base.z - 3)
        newRoom.x = base.x + offset
        newRoom.y = base.y - newRoom.w + 1
        // 8-9) Check room for valid space compared to other rooms.
        if (!isSafeToPlace(rooms, base, newRoom)) {
          continue
        }

        // 10) Place a door in the overlapping range
        var doorLeft = M.max(newRoom.x, base.x)
        var doorRight = M.min(newRoom.x + newRoom.z, base.x + base.z)
        var doorRange = RNG.int(doorLeft + 1, doorRight - 1)
        door = Vec.new(doorRange, base.y)
      } else if (dir == 2) {
        // right
        var offset = RNG.int(3 - newRoom.w, base.w - 3)
        newRoom.x = base.x + base.z - 1
        newRoom.y = base.y + offset
        // 8-9) Check room for valid space compared to other rooms.
        if (!isSafeToPlace(rooms, base, newRoom)) {
          continue
        }

        // 10) Place a door in the overlapping range
        var doorTop = M.max(newRoom.y, base.y)
        var doorBottom = M.min(newRoom.y + newRoom.w, base.y + base.w)
        var doorRange = RNG.int(doorTop + 1, doorBottom - 1)
        door = Vec.new(newRoom.x, doorRange)
      } else if (dir == 3){
        // up
        var offset = RNG.int(3 - newRoom.z, base.z - 3)
        newRoom.x = base.x + offset
        newRoom.y = base.y + base.w - 1
        // 8-9) Check room for valid space compared to other rooms.
        if (!isSafeToPlace(rooms, base, newRoom)) {
          continue
        }

        // 10) Place a door in the overlapping range
        var doorLeft = M.max(newRoom.x, base.x)
        var doorRight = M.min(newRoom.x + newRoom.z, base.x + base.z)
        var doorRange = RNG.int(doorLeft + 1, doorRight - 1)
        door = Vec.new(doorRange, newRoom.y)
      } else {
        // Safety assert
        Fiber.abort("Tried to grow from bad direction")
      }
      rooms.add(newRoom)
      newRoom.neighbours.add(base)
      base.neighbours.add(newRoom)

      doors.add(door)
      newRoom.doors.add(door)
      base.doors.add(door)
      attempts = 0
    }

    return [ rooms, doors ]
  }

  overlap(r1, r2) {
    return r1.x < r2.x + r2.z &&
           r1.x + r1.z > r2.x &&
           r1.y < r2.y + r2.w &&
           r1.y + r1.w > r2.y
  }

  isSafeToPlace(rooms, base, newRoom) {
    var mapHeight = Config["map"]["height"]
    var mapWidth = Config["map"]["width"]
    if (newRoom.x < 0 || newRoom.x + newRoom.z >= mapWidth || newRoom.y < 0 || newRoom.y + newRoom.w >= mapHeight) {
      return false
    }
    for (room in rooms) {
      if (room == base) {
        // Colliding with the base is intentional. ignore this hit.
        continue
      }
      if (overlap(newRoom, room)) {
        return false
      }
    }
    return true
  }
}
