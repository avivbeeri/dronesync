import "graphics" for Font
import "core/main" for ParcelMain

// import "plugin" for Plugin
// Plugin.load("synth")

import "./scenes/play" for PlayScene
import "./scenes/start" for StartScene

Font.load("futile", "res/FutilePro.ttf", 16)
Font.load("m3x6", "res/m3x6.ttf", 16)
var Game = ParcelMain.new(StartScene)

