import "graphics" for Canvas
import "dome" for Window
import "input" for Keyboard
import "math" for Vec

import "core/entity" for StackEntity
import "core/action" for Action
import "extra/actions" for RestAction
import "core/scene" for Scene, View
import "core/display" for Display
import "core/config" for Config
import "core/world" for World, Zone
import "core/director" for EnergyStrategy
import "core/map" for TileMap, Tile
import "core/tilesheet" for Tilesheet

import "./events" for SleepEvent, RefillEvent, EmptyEvent
import "./actions" for MoveAction, SleepAction, SowAction, WaterAction, HarvestAction
import "./entities/player" for PlayerEntity
import "./palette" for PAL
import "./inputs" for InputAction

import "./bulkLoader" for SleepAnimation, WorldRenderer, StatusBar, Tooltip
// import "./bulkLoader" for BulkLoader

/*
import "./views/animations" for SleepAnimation
import "./views/renderer" for WorldRenderer
import "./views/statusbar" for StatusBar
import "./views/tooltip" for Tooltip
*/

import "./generator" for StaticGenerator

class PlayScene is Scene {
  construct new(args) {
    super(args)
    _world = StaticGenerator.createWorld()

    addViewChild(WorldRenderer.new(this, _world.active, 0, 21))
    addViewChild(StatusBar.new(this, _world.active))
    addViewChild(Tooltip.new(this, "BEGIN!"))
  }

  update() {
    super.update()

    var player = _world.active.getEntityByTag("player")

    if (InputAction.right.firing) {
      player.action = MoveAction.new(Vec.new(1, 0))
    } else if (InputAction.left.firing) {
      player.action = MoveAction.new(Vec.new(-1, 0))
    } else if (InputAction.up.firing) {
      player.action = MoveAction.new(Vec.new(0, -1))
    } else if (InputAction.down.firing) {
      player.action = MoveAction.new(Vec.new(0, 1))
    } else if (InputAction.rest.firing) {
      player.action = RestAction.new()
    }

    _world.update()

    for (event in _world.active.events) {
    }
  }

  draw() {
    Canvas.cls(Display.bg)
    super.draw()
  }
}
