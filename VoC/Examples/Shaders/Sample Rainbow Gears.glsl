#version 420

// original https://www.shadertoy.com/view/Wd3GWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;
    
    // shift over time
    uv += time*0.1;
    
    // Divide into grid
    float gridSize = 3.;
    
    // grid uv is fractional part of uv
    vec2 gv = fract(uv*gridSize)-0.5;
    // grid id is integer part of uv
    vec2 id = floor(uv*gridSize);
    
    // start with black and add color where appropriate
    vec3 col = vec3(0);
    
    // loop over neighboring grid areas to draw overlapping/intermeshing gears
    for (int x = -1; x <= 1; x++) {
        for ( int y = -1; y <= 1; y++) {
            vec2 offs = vec2(x, y);
            // Distance to center of grid
            float cd = length(gv+offs);
            // angle relative to center of grid
            float a = atan(gv.y+offs.y, gv.x+offs.x);
           
            // Alternate rotation direction by grid id
            float dir;
            if ( mod(id.x+id.y + offs.x+offs.y, 2.) == 0. ) {
                dir = 1.;
            } else {
                dir = -1.;
            }
            
            // gear shape - radius as a function of angle, direction, and time
            float ra = 0.5+0.1*clamp(sin(10.*a+dir*5.*time), -.4, .5);
            float mask = 0.9 * smoothstep(ra, ra-0.01, cd);
            
            // remove center
            mask -= smoothstep(0.31, 0.3, cd);
            
            // get color for grid - not sure why this needs to be minus offs??
            vec3 icol = (0.5 + 0.5*cos((id.xyx-offs.xyx)/2.+vec3(0,2,4)));
            // add color with mask
            col += mask * icol;
        }
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
