import "graphics" for Canvas
import "core/scene" for Scene
import "core/display" for Display
import "dome" for Window


class PlantScene is Scene {
  construct new(args) {
    super(args)
    var scale = 6
    Window.resize(Canvas.width * scale, Canvas.height * scale)
  }

  draw() {
    Canvas.cls(Display.bg)
  }
}
