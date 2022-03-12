import "core/inputGroup" for InputGroup
import "input" for Keyboard, Mouse

var UP_KEY = InputGroup.new([
  Keyboard["up"], Keyboard["w"], Keyboard["k"]
])
var DOWN_KEY = InputGroup.new([
  Keyboard["down"], Keyboard["s"], Keyboard["j"]
])
var LEFT_KEY = InputGroup.new([
  Keyboard["left"], Keyboard["a"], Keyboard["h"]
])
var RIGHT_KEY = InputGroup.new([
  Keyboard["right"], Keyboard["d"], Keyboard["l"]
])

var CANCEL_KEY = InputGroup.new([
  Keyboard["backspace"], Keyboard["escape"]
])

var CONFIRM_KEY = InputGroup.new([
  Keyboard["z"], Keyboard["x"], Keyboard["e"], Keyboard["return"], Keyboard["space"]
])

var INVENTORY_KEY = InputGroup.new([
  Keyboard["i"]
])
var REST_KEY = InputGroup.new([
  Keyboard["r"], Keyboard["space"]
])
var NEXT_KEY = InputGroup.new([
  Keyboard["tab"]
])
var SWAP_KEY = InputGroup.new([
  Keyboard["left shift"], Keyboard["right shift"], Keyboard["tab"]
])

var DIR_KEYS = [ UP_KEY, DOWN_KEY, LEFT_KEY, RIGHT_KEY ]
// Set frequency for smoother tile movement
DIR_KEYS.each {|key| key.frequency = 8 }

class InputAction {
  // Grouped keys
  static directions { DIR_KEYS }

  // Singular actions
  static up { UP_KEY }
  static down { DOWN_KEY }
  static left { LEFT_KEY }
  static right { RIGHT_KEY }
  static rest { REST_KEY }
  static next { NEXT_KEY }
  static inventory { INVENTORY_KEY }
  static confirm { CONFIRM_KEY }
  static swap { SWAP_KEY }
  static cancel { CANCEL_KEY }
}
