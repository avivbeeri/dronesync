import "math" for Vec
import "util" for GridWalk
import "entities/creature" for Creature
import "entities/behaviour" for
  Awareness,
  Confusion,
  Patrol,
  Seek,
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

    push(Stunnable)
    push(Awareness)
    push(Confusion)
    push(State.new(this, "state", {
      "alert": Seek,
      "patrol": Patrol.new(this, config["patrol"] || [])
    }))
    push(Wait)
  }

  endTurn() {
    super.endTurn()
    // Recompute awareness
    var player = ctx.getEntityByTag("player")
    var visible = GridWalk.checkLoS(ctx.map, pos, player.pos)
    if (visible && this["awareness"] == 0) {
      this["awareness"] = 1
    }
  }
}

