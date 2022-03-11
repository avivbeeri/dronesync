import "math" for Vec
import "util" for GridWalk
import "entities/creature" for Creature
import "entities/behaviour" for
  Awareness,
  Confusion,
  Curiosity,
  Patrol,
  SeekPlayer,
  SeekFocus,
  State,
  Stunnable,
  Wait
import "extra/combat" for Attack

class Guard is Creature {
  construct new(config) {
    super(config)
  }

  construct new() {
    super()
  }

  init(config) {
    super.init(config)

    this["symbol"] = "g"
    this["awareness"] = 0
    this["melee"] = Attack.direct(this)
    this["targetGroup"].add("enemy")
    this["state"] = "patrol"
    this["senses"] = {}

    push(Stunnable)
    push(Curiosity)
    push(Awareness)
    push(Confusion)
    push(State.new(this, "state", {
      "alert": SeekFocus,
      "investigate": SeekFocus,
      "investigate-noise": SeekFocus,
      "patrol": Patrol.new(this, config["patrol"] || [])
    }))
    push(Wait)
  }

  endTurn() {
    super.endTurn()
    // Recompute awareness
    /*
    var player = ctx.getEntityByTag("player")
    var visible = GridWalk.checkLoS(ctx.map, pos, player.pos)
    if (visible && (player.pos - this.pos).length < 20 && this["awareness"] == 0) {
      this["awareness"] = 1
    }
    */
  }
}

