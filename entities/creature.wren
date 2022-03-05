import "core/entity" for StackEntity
import "extra/stats" for StatGroup

class Creature is StackEntity {
  construct new(config) {
    super()
    init(config)
  }

  construct new() {
    super()
    init({})
  }

  init(config) {
    this["awareness"] = 0
    this["inventory"] = []
    this["stunTimer"] = 0
    this["stats"] = StatGroup.new({
      "atk": 1,
      "def": 0,
      "hp": 2,
      "hpMax": 2,
      "speed": 6
    })
    if (config != null && config.containsKey("stats")) {
      for (id in config["stats"].keys) {
        this["stats"].set(id, config["stats"][id])
      }
    }
  }
  speed { this["stats"].get("speed") }

  endTurn() {
    super.endTurn()
    if (this["stunTimer"] > 0) {
      this["stunTimer"] = this["stunTimer"] - 1
      System.print(this["stunTimer"])
    }
  }
}

