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
    this["inventory"] = []
    this["stats"] = StatGroup.new({
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
}

