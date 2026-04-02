#version 420

// original https://www.shadertoy.com/view/wdcSWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 GRASS = vec3(0., .5, 0.);
const vec3 STRIPE = vec3(1., 1., 1.);
const vec3 WARN = vec3(1., 1., 0.);
const vec3 ROAD = vec3(.2, .2, .2);
const vec3 KERB = vec3(1., 0., 0.);
const float ROWS = 20.;

vec3 scanlineRoad(in vec2 p, in float row, in float scaling)
{
    row += floor(time * 20.);
   
    vec2 mirp = abs(p);
    mirp *= scaling;
   
    if (mirp.x < .02) { 
        return mix(STRIPE, ROAD, mod(floor(row * .5), 2.)); 
    }
    if (mirp.x < .53) { return ROAD; }
    if (mirp.x < .55) { 
        return mix(STRIPE, WARN, mod(floor(row * .333333), 2.)); 
    }
    if (mirp.x < .6) { return ROAD; }
    if (mirp.x < .64) {
        return mix(STRIPE, KERB, mod(row, 2.));
    }
    else { return GRASS; }
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * vec2(1., ROWS)) / resolution.xy;
    uv.y *= 4.;
    
    float row = floor(uv.y);
    // float row = pow(2.0, floor(uv.y + 1.0) * 0.07); // suggestion from jaszunio15 for a perspective tweak
    uv.y = fract(uv).y;
    uv.x -= 0.5;
    
    uv.x += sin(time + row * .1) * .1;
        
    // Time varying pixel color
    vec3 col = scanlineRoad(uv, row, row * .1 + 1.);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
