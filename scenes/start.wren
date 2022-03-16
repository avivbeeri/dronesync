import "graphics" for Canvas, Font
import "dome" for Window
import "input" for Keyboard
import "json" for JSON
import "io" for FileSystem
import "math" for Vec, M

import "core/scene" for Scene
import "core/display" for Display
import "core/config" for Config

import "./palette" for PAL
import "./scenes/play" for PlayScene
import "./views/window" for Window as Pane

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

    addViewChild(Pane.new(this, null, Vec.new(Canvas.width - 32, Canvas.height - 32)))
    _progress = 0
  }

  update() {
    if (Keyboard.allPressed.count > 0) {
      _progress = 1
    }
    if (_progress >= 100) {
      game.push(PlayScene)
    }
    if (_progress > 0) {
      _progress = _progress + 1
    }

    super.update()
  }

  draw() {
    Canvas.cls(Display.bg)
    super.draw()
    var title = "Ghost:\nDroneSync"
    var thick = 4
    var y = 48
    for (dy in -thick..thick) {
      for (dx in -(1+thick)..(thick+1)) {
        Display.print(title,{
          "color": PAL[12],
          "align": "center",
          "position": Vec.new(dx, y + dy),
          "overflow": true,
          "font": "futile",
        })
      }
    }
    Display.print(title,{
      "color": PAL[6],
      "align": "center",
      "position": Vec.new(0, y),
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
    if (_progress == 0) {
      Display.printCentered("Press any", Canvas.height - 40, Display.fg)
      Display.printCentered("key", Canvas.height - 32, Display.fg)
    }

    y = Canvas.height - 80
    var lines = [
      "Connection established.",
      "Mission parameters acquired.",
      "Commencing..."
    ]
    var log = lines.take((_progress / 25).ceil)
    y = Canvas.height - 80 - 8 * log.count

    for (line in log) {
      Canvas.print(line, 32, y, Display.fg)
      y = y + 8
    }

    y = Canvas.height - 64

    var chunkWidth = ((Canvas.width - 64))
    var width = _progress * chunkWidth / 100
    Canvas.rectfill(32, y, Canvas.width - 64, 16, PAL[3])
    Canvas.rectfill(32, y, width, 16, PAL[2])
  }
}
