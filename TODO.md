TODO for DroneSync
===============

# Day 5:


* procedural map generation
  - Create layout
  - populate with guards
  - add objective(s)
  - lock-key systems

Items:
  - Noise maker?
  - jammer? (only makes sense if guards can talk to each other
  - 
  - ???

* Enhanced The guard detection AI 
  - Directional awareness
  - Points-of-interest

* Drone mechanics
  - Range of operation
  - Awareness
* Contraption interactions


# Completed:
## Day 1:
* Player exists
* Enemy guards exist
* patrol behaviour works
* (tangent) had to fix the pathfinding systems
* Combat between enemy and player 
  - (Guards need to stop stunning each other, and hit the player properly)
* Entrance/Exit tile.
* Target/Goal.
* Death/Capture fail state
* UI
  - Mission Success/Fail State

## Day 2
* field of view
* enemy Alert behaviour
* UI
  - Log (partial)
  - health display
  - Awareness (sort of. Would prefer a no-color solution)

## Day 3
* Change FoV from using "solid", and use "blocksSight"
* UI
  - Windows should be draggable
* Drone
  - Entity
  - Control
  - Switching

## Day 4
* Fixed LoS issues
* Fixed Path finding
* Text display underflow fixed
* Smoke grenades
  - DONE: Select a target square for use (based on range)
  - DONE: cause a lingering environmental effect which blocks vision

## Day 5
* Smoke grenades
    * DONE Select an item to use (based on capability and inventory)
    * DONE: Ensure AI responds accordingly to smoke
