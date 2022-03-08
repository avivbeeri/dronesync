import "math" for Vec

class GridWalk {
  static checkLoS(map, p0, p1) {
    var line = GridWalk.getLine(p0, p1)
    var visible = true
    var previous = null
    for (point in line) {
      // Prevent tunnelling
      if (previous && (previous - point).manhattan > 1) {
        if (map[previous.x, point.y]["blockSight"] &&
            map[point.x, previous.y]["blockSight"]) {
          visible = false
          break
        }
      }
      if (map[point]["blockSight"]) {
        visible = false
        break
      }
    }
    return visible
  }

  static getLine(p0, p1) { getLine_Interpolate(p0, p1) }
  static getLine_Bresenham_low(p0, p1) {
    var points = []

    var dx = p1.x - p0.x
    var dy = p1.y - p0.y
    var yi = 1
    if (dy < 0) {
      yi = -1
      dy = -dy
    }

    var d = (2 * dy) - dx
    var y = p0.y
    for (x in p0.x..p1.x) {
      points.add(Vec.new(x, y))
      if (d > 0) {
        y = y + yi
        d = d + (2 * (dy - dx))
      } else {
        d = d + 2 * dy
      }
    }
    return points
  }
  static getLine_Bresenham_high(p0, p1) {
    var points = []

    var dx = p1.x - p0.x
    var dy = p1.y - p0.y
    var xi = 1
    if (dx < 0) {
      xi = -1
      dx = -dx
    }

    var d = (2 * dx) - dy
    var x = p0.x
    for (y in p0.y..p1.y) {
      points.add(Vec.new(x, y))
      if (d > 0) {
        x = x + xi
        d = d + (2 * (dx - dy))
      } else {
        d = d + 2 * dx
      }
    }
    return points
  }

  static getLine_Bresenham(p0, p1) {
    if ( (p1.y - p0.y).abs < (p1.x - p0.x).abs) {
      if (p0.x > p1.x) {
        return getLine_Bresenham_low(p1, p0)
      } else {
        return getLine_Bresenham_low(p0, p1)
      }
    } else {
      if (p0.y > p1.y) {
        return getLine_Bresenham_high(p1, p0)
      } else {
        return getLine_Bresenham_high(p0, p1)
      }
    }

  }


  static getLine_Interpolate(p0, p1) {
    var dx = p1.x - p0.x
    var dy = p1.y - p0.y
    var nx = dx.abs
    var ny = dy.abs

    var signX = dx > 0 ? 1 : -1
    var signY = dy > 0 ? 1 : -1

    var p = p0 * 1
    var points = [ p * 1 ]

    var ix = 0
    var iy = 0
    while (ix < nx || iy < ny) {
      if ((0.5 + ix) / nx < (0.5 + iy) / ny) {

        p.x = p.x + signX
        ix = ix + 1
      } else {
        p.y = p.y + signY
        iy = iy + 1
      }
      points.add(p * 1)
    }
    return points
  }
}
