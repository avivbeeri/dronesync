import "graphics" for Canvas, Font
import "dome" for Window
import "input" for Keyboard
import "json" for JSON
import "io" for FileSystem
import "math" for Vec

import "core/scene" for Scene
import "core/display" for Display
import "core/config" for Config

import "./scenes/play" for PlayScene

class StartScene is Scene {
  construct new(args) {
    super(args)
    var scale = 2
    Window.resize(Canvas.width * scale, Canvas.height * scale)
    if (Config["map"]["font"]) {
      Font.load("terminal", Config["map"]["font"], Config["map"]["fontSize"])
      Font["terminal"].antialias = false
      Canvas.font = "terminal"
    }
  }

  update() {
    if (Keyboard.allPressed.count > 0) {
      game.push(PlayScene)
    }
  }

  draw() {
    Canvas.cls(Display.bg)
    var title = "Ghost:\nDroneSync"
    var thick = 2
    for (dy in -thick..thick) {
      for (dx in -(1+thick)..(thick+1)) {
        Display.print(title,{
          "color": Display.fg,
          "align": "center",
          "position": Vec.new(dx, 4 + dy),
          "overflow": true,
          "font": "futile",
        })
      }
    }
    Display.print(title,{
      "color": Display.bg,
      "align": "center",
      "position": Vec.new(0, 4),
      "overflow": true,
      "font": "futile",
    })

    Display.print("v" + Config["version"], {
      "font": "m3x6",
      "align": "right",
      "color": Display.fg,
      "position": Vec.new(0, Canvas.height - 8),
      "overflow": true,
    })
    Display.printCentered("Press any", Canvas.height - 24, Display.fg)
    Display.printCentered("key", Canvas.height - 16, Display.fg)
  }
}
