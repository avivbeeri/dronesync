import "entities/creature" for Creature
import "entities/behaviour" for Wait

class Guard is Creature {
  construct new(config) {
    super()
    init(config)
  }

  construct new() {
    super()
    init({})
  }

  init(config) {
    super.init(config)
    this["symbol"] = "g"
    push(Wait)
  }
}

