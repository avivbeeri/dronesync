
class GridWalk {

  static getLine(p0, p1) {
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
