import "entities/creature" for Creature

class PlayerEntity is Creature {
  construct new(config) {
    super()
    init(config)
  }

  construct new() {
    super()
    init({})
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

