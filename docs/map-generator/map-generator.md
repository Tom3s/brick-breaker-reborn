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