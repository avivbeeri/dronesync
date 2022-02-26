import "core/entity" for Entity

class PlayerEntity is Entity {
  construct new() {
    super()
  }

  action { _action }
  action=(v) { _action = v }

  update() { _action }
}



