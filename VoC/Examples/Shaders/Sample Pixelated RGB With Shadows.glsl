#version 420

// original https://www.shadertoy.com/view/wscGWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){ return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); } // random noise

float getCellBright(vec2 id) {
    return sin((time+2.)*rand(id)*2.)*.5+.5; // returns 0. to 1.
}

void main(void) {
    float mx = max(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / mx;
    
    float time = time*.5;
    
    uv *= 30.; // grid size

    vec2 id = floor(uv); // id numbers for each "cell"
    vec2 gv = fract(uv)-.5; // uv within each cell, from -.5 to .5

    vec3 color = vec3(0.);
    
    float randBright = getCellBright(id);
    
    vec3 colorShift = vec3(rand(id)*.1); // subtle random color offset per "cell"
    
    color = 0.6 + 0.5*cos(time + (id.xyx*.1) + vec3(4,2,1) + colorShift); // RGB with color offset
    
    float shadow = 0.;
    shadow += smoothstep(.0, .7,  gv.x*min(0., (getCellBright(vec2(id.x-1., id.y)) - getCellBright(id)))); // left shadow
    shadow += smoothstep(.0, .7, -gv.y*min(0., (getCellBright(vec2(id.x, id.y+1.)) - getCellBright(id)))); // top shadow
    
    color -= shadow*.4;
    
    color *= 1. - (randBright*.2);
    
    glFragColor = vec4(color, 1.0);

}
