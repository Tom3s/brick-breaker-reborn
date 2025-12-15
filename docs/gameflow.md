# Game Flow elements

## Last couple blocks

- a common problem with these type of game is hitting the last blocks
- a solution should be found to streamline breaking the last few blocks and keep player engagement
  
## Problems to solve

- hard to aim
- missing the block puts the player in a long wait until next try
- at shallow angle next try is even slower

### Idea #1

- when at the last `5` blocks or last `5%` a powerup event occurs
- this event will grant the player with something that helps to finish the level
- the ball could 'magnetically' drift towards the blocks, or towards a player desired position
- player can get a weapon that they can use regardless of ball position
- massively increase ball size maybe

### Idea #2

- player is given the option to 'nuke' the last few blocks, giving less points
- if player holds a key, they can move onto the next level without breaking all blocks


## Global lives

- similar to candy crush, player has lives that refill over time
- ingame lives (3 default, might depend on the level) are granted for each try
- retries of a level use up global lives
- will need to thoroughly test this, to not hinder player progress


## Performance indicators

- score and othe Performance indicators could be implemented to spice up xp collection/leveling

### Base Level Score

- each broken block gives a certain amount of score
- this will give a fixed base score for each level
  
### Collecting items during game

- picking up items, coins, or anything similar will give extra XP

### 3 star system (might be wrong idea)

- Player will get a 3 star rating if the screen is completed without losing lives
- lives are only lost if all balls are lost
- each star completion has its own associated extra XP
  - this shouldn't be linear (like 1250, 2500, 3750)
  - should be more engaging (1250, 5000, 15000)
  - IMPORTANT: recompleting a level with a higher star rating should only grant extra XP of the difference

### Recompleting levels

- if a player replays a level, they should still get XP, but its reduced
- smth like ~15% sounds like a fair trade
  - any higher, and farming is made trivial
  - any lower and the player might feel 'scammed of their time'
  - IMPORTANT this number is highly subject to change


## Level editor

- might implement a level editor later
- some type of editor will inevitably be made to streamline level creation
  
### challenge of the week

- a special hand crafted level could be selected each week with extra challenges
- could use gameplay modifiers for thes

## Gameplay modifiers

- some levels could have some gameplay modifiers for variation

### Idea dump

- ball size
- only certain block types
- only certain ball types
- ball quantity (ex. always start with 3 balls)
- ball speed