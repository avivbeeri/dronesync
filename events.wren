import "extra/combat" for AttackResult
import "core/event" for Event
class GoalEvent is Event {
  construct new() {
    super()
  }
}
class EscapeEvent is Event {
  construct new() {
    super()
  }
}
class QueryEvent is Event {
  construct new(source, data) {
    super()
    _data = data
    _source = source
  }
  data { _data }
  source { _source }
}
class LogEvent is Event {
  construct new(text) {
    super()
    _text = text
  }
  text { _text }
}
class AttackEvent is Event {

  construct new(source, target, attack) {
    super()
    _target = target
    _source = source
    _attack = attack
    _result = true
  }
  construct new(source, target, attack, result) {
    super()
    _target = target
    _source = source
    _attack = attack
    _result = result
  }

  source { _source }
  target { _target }
  attack { _attack }
  result { _result }

  fail() {
    _result = AttackResult.blocked
  }
}
