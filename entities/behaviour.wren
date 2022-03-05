import "core/action" for Action
import "core/behaviour" for Behaviour

class Wait is Behaviour {
  construct new(self) {
    super(self)
  }
  notify(event) {}
  evaluate() {
    return Action.none
  }
}
