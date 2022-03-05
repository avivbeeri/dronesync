import "math" for Vec
import "entities/creature" for Creature
import "entities/behaviour" for Wait, Stunnable, Patrol, Seek

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
    this["awareness"] = 0
    push(Stunnable)
//    push(Seek)
    push(Patrol.new(this, [ Vec.new(10, 20), Vec.new(10, 10) ]))
    push(Wait)
  }
}

