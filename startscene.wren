import "graphics" for Canvas, Font
import "dome" for Window
import "input" for Keyboard
import "json" for JSON
import "io" for FileSystem
import "math" for Vec

import "core/scene" for Scene
import "core/display" for Display

import "./scene" for PlantScene

class StartScene is Scene {
  construct new(args) {
    super(args)
    var scale = 6
    Window.resize(Canvas.width * scale, Canvas.height * scale)
  }

  update() {
    if (Keyboard.allPressed.count > 0) {
      game.push(PlantScene)
    }
  }

  draw() {
    Canvas.cls(Display.bg)
    for (dy in -1..1) {
      for (dx in -2..1) {
        Display.print("Garden",{
          "color": Display.fg,
          "align": "center",
          "position": Vec.new(dx, 4 + dy),
          "overflow": true,
          "font": "futile",
        })
      }
    }
        Display.print("Garden",{
          "color": Display.bg,
          "align": "center",
          "position": Vec.new(0, 4),
          "overflow": true,
          "font": "futile",
        })
    Display.printCentered("Press any", Canvas.height - 24, Display.fg)
    Display.printCentered("key", Canvas.height - 16, Display.fg)
  }
}
