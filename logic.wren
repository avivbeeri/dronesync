import "json" for JSON
import "io" for FileSystem
import "math" for Vec

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

class ShadowLine {
  construct new() {
    _shadows = []
  }
  shadows { _shadows }

  isInShadow(projection) {
    for (shadow in _shadows) {
      if (shadow.contains(projection)) {
        return true
      }
    }

    return false
  }

  add(shadow) {
    // Figure out where to slot the new shadow in the list.
    var index = _shadows.count
    for (i in 0..._shadows.count) {
      // Stop when we hit the insertion point.
      if (_shadows[i].start >= shadow.start) {
        index = i
        break
      }
    }

    // The new shadow is going here. See if it overlaps the
    // previous or next.
    var overlappingPrevious
    if (index > 0 && _shadows[index - 1].end > shadow.start) {
      overlappingPrevious = _shadows[index - 1]
    }

    var overlappingNext
    if (index < _shadows.count &&
        _shadows[index].start < shadow.end) {
      overlappingNext = _shadows[index]
    }

    // Insert and unify with overlapping shadows.
    if (overlappingNext != null) {
      if (overlappingPrevious != null) {
        // Overlaps both, so unify one and delete the other.
        overlappingPrevious.end = overlappingNext.end
        _shadows.removeAt(index)
      } else {
        // Overlaps the next one, so unify it with that.
        overlappingNext.start = shadow.start
      }
    } else {
      if (overlappingPrevious != null) {
        // Overlaps the previous one, so unify it with that.
        overlappingPrevious.end = shadow.end
      } else {
        // Does not overlap anything, so insert.
        _shadows.insert(index, shadow)
      }
    }
  }

  isFullShadow {
    return _shadows.count == 1 &&
        _shadows[0].start == 0 &&
        _shadows[0].end == 1
  }
}

class Shadow {
  construct new(start, end) {
    _start = start
    _end = end
  }

  start { _start }
  start=(v) { _start = v }
  end=(v) { _end = v }
  end { _end }

 /// Returns `true` if [other] is completely covered by this shadow.
  contains(other) {
    return start <= other.start && end >= other.end
  }

  /// Creates a [Shadow] that corresponds to the projected
  /// silhouette of the tile at [row], [col].
  static projectTile(row, col) {
    var topLeft = col / (row + 2)
    var bottomRight = (col + 1) / (row + 1)
    return Shadow.new(topLeft, bottomRight)
  }
}

class UpdateVision {
  static transformOctant(row, col, octant) {
    if (octant == 0) {
      return Vec.new(col, -row)
    } else if (octant == 1) {
      return Vec.new(row, -col)
    } else if (octant == 2) {
      return Vec.new(row, col)
    } else if (octant == 3) {
      return Vec.new(col, row)
    } else if (octant == 4) {
      return Vec.new(-col, row)
    } else if (octant == 5) {
      return Vec.new(-row, col)
    } else if (octant == 6) {
      return Vec.new(-row, -col)
    } else if (octant == 7) {
      return Vec.new(-col, -row)
    }
  }


  static update(ctx) {
    var player = ctx.getEntityByTag("player")
    var tiles = ctx.map
    var start = player.pos
    var distance = -1
    tiles[start]["visible"] = "visible"

    for (octant in 0...8) {
      // refresh octant
      var line = ShadowLine.new()
      var fullShadow = false
      var row = 1
      while (distance == -1 || row < distance) {
        var pos = start + transformOctant(row, 0, octant)
        if (tiles[pos]["OOB"]) {
          break
        }
        for (col in 0..row) {
          var pos = start + transformOctant(row, col, octant)
          if (tiles[pos]["OOB"]) {
            break
          }
          var unknown = tiles[pos]["visible"] == "unknown"
          if (fullShadow) {
            tiles[pos]["visible"] = (unknown ? "unknown" : "hidden")
          } else {
            var projection = Shadow.projectTile(row, col)
            var visible = !line.isInShadow(projection)
            tiles[pos]["visible"] = visible ? "visible" : (unknown ? "unknown" : "hidden")
            if (visible && tiles[pos]["solid"]) {

              line.add(projection)
              fullShadow = line.isFullShadow
            }
          }
        }
        row = row + 1
      }
    }
  }
}
