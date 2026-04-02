#version 420

// original https://www.shadertoy.com/view/7dGfWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float rootTwo = 1.4142135623;

// Create a grid.
const float gridSize = 20.;

// To draw a line we basically figure out how far away we are from the projection of our current
// point to the line, and then depending on our desired line thickness we can draw.
float L(vec2 p, vec2 a,vec2 b) {               
    vec2 pa = p-a;
    vec2 ba = b-a;
    // Normalised projection clamped between zero and one.
    float proj = clamp(dot(pa,ba)/dot(ba,ba), 0., 1. );
    // Distance from point and line.
    return length(pa - ba*proj);
}

vec3 spider(vec2 C, vec2 grid, vec2 gv) {
    vec3 col = vec3(0.);
    
    // Grid points near the spider.
    if (distance(grid, C*gridSize) <= 1.9*rootTwo) {
        col += smoothstep(3.*gridSize/resolution.y, 0., length(gv));
    }
    // Spider legs.
    // Totally redundant but I wanted to see how to smoothstep between arbitrary different colours.
    vec3 legCol = vec3(1.);
    vec2 anchor = floor(C*gridSize), offset;
    float d, line;
    for (int y=-2; y<=2; y++) {
        for (int x=-2; x<=2; x++) {
            offset = vec2(x, y);
            d = distance(anchor+offset, C*gridSize);
            if (d >= 1. && d <= 2.) {
                line = L(grid, anchor+offset, C*gridSize);
                col += mix(vec3(0.), legCol, smoothstep(1.4*gridSize/resolution.y, 0., line));
            }
        }
    }
    return col;
}

void main(void)
{
    // Centre of the screen is (0,0).
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) / resolution.y;
    vec3 col = vec3(0.);
    
    vec2 grid = uv*gridSize;
    // Coordinates inside each grid square.
    vec2 gv = fract(grid);
    
    // Centre of moving spider.
    vec2 C = .3*cos(.5*time+vec2(3,2)) + .15*sin(1.4*time+vec2(1,0));
    col += spider(C, grid, gv);
    // His friend (or maybe his enemy). 
    C = .3*sin(.5*time+vec2(3,2)) + .15*cos(1.4*time+vec2(1,0));
    col += spider(C, grid, gv);

    glFragColor = vec4(col,1.0);
}
