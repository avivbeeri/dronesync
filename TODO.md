TODO for DroneSync
===============

# Day 7:

## Guard Points-of-interest system
  Scan for the player. If we moved away from them, awareness is much lower.
  Make a queue of events that occur in the world
    * Movement
    * vision
    * noise?
  Priority queue of points to investigate, as well as suspicion levels.
  Take highest priority, pathfind to the point of it happening or last point seen.
  Re-evaluate and resolve.
  If there are no priority points, then return to patrol paths.


# Nice to Have

## Map Generation
  An extra room type or two would make the game play more varied.

  * Bridge - A room split in half, with a narrow bridge between. Guards patrol _across_ this room.
  * 

  Features in the rooms: Loot drops, extra exits?

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

## Day 7
* Stunned guards can be walked over
* Enhanced AI with investigation phase
* Coin to throw, makes noise
* Enemies investigate noise
* coins generate in level
