import "core/entity" for Entity

class PlayerEntity is Entity {
  construct new() {
    super()
    priority = 12
  }

  action { _action }
  action=(v) { _action = v }

  speed { 6 }

  update() {
    var action = _action
    _action = null
    return action
  }
}



