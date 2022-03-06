import "graphics" for Font
import "core/main" for ParcelMain

// import "plugin" for Plugin
// Plugin.load("synth")

Font.load("futile", "res/FutilePro.ttf", 32)
import "./scenes/play" for PlayScene
import "./scenes/start" for StartScene

var Game = ParcelMain.new(StartScene)

