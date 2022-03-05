import "math" for Vec
import "entities/creature" for Creature
import "entities/behaviour" for Wait, Stunnable, Patrol, Seek
import "extra/combat" for Attack

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
    this["melee"] = Attack.direct(this)
    this["targetGroup"].add("enemy")
    push(Stunnable)
//    push(Seek)
    push(Patrol.new(this, [ Vec.new(10, 4), Vec.new(10, 16) ]))
    push(Wait)
  }
}

