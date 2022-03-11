TODO for DroneSync
===============

# Day 6:

* procedural map generation
  - Minimum enemy for challenge
  - lock-key systems
* Drone mechanics
  - Awareness

* Contraption interactions

* Enhanced The guard detection AI 
  - Performance optimization for the start of the game
  - Directional awareness
  - Points-of-interest
* Enhanced Enemy abilites
Items:
  - Optical Camo
  - Noise maker?
  - jammer? (only makes sense if guards can talk to each other
  - 
  - ???




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
* Procedural Map Generation
  - Create layout
  - add objective(s)
  - populate with guards

## Day 6
* Procedural Map Generation
  - "Interesting" rooms
* Drone
  - Range of operation
  - Pickup
