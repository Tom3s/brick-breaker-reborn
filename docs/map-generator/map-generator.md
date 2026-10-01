# Map Generator Notes

## Types of generation methods

Main idea is to generate a texture and then convert said texture to a map

### Basic Noise

Different kinds of noise and use a mapping to set different grayscale values to blocks
- simple noise
- voronoi

### Basic shapes

Add simple shapes
- circles
- lines
- triangles
- polygons (?)

### Marching squares

Convert the generated noise to a map using the marching squares algorithm
- results in less blocky maps

## Passes

- Main texture (colors) generation
- Assign colors to blocks
- merge blocks
- mirror horizontally/vertically
- slice
- combine more textures

## Beta levels

- ball powerups first, then other powerups

### Level 1

- only normal blocks
- sparse, large, connected blocks (kinda like now)
- all blocks have 1 hp
- only ball powerups
  - ice, fire, bomb
  - ball multiply

### Level 2

- sparse, large, connected blocks (kinda like now)
- half/half normal and ice blocks (to showcase fire ball)
- only ball powerups
  - ice, fire, bomb
  - ball multiply

### Level 3

- sparse, mid-size, connected blocks
- only normal blocks
- blocks have more health
- all powerups

### Level 4

- dense, mid-size connected blocks
- patches of ices
  - voronoi gen
- skewed blocks
- blocks have more health
- all powerups

### Level 5

- dense, mid-size singular blocks
  - bayer dither
- patches of metal/ice
  - circle shape
- skewed blocks
- blocks have more health
- all powerups

### Level 6

- patches of metal/ice only
  - circle shape
- skewed blocks
- blocks have more health
- all powerups

### Level 7

- 3 layer perlin noise: normal, ice, metal
  - connected blocks
  - blocks have more health
- grid-like blocks
- all powerups

### Level 8

- boss :3