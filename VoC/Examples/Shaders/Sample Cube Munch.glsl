#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ssSGzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Shader version of @aemkei's "alien art"
// Original: https://twitter.com/aemkei/status/1378106731386040322
// Modified by @gaeel - https://www.shadertoy.com/view/ssjGWW
// Modified again by @cacheflowe :)
// Press the ⏮ button under the preview window to restart from the beginning

void main(void) {
    // normalized p for quadrants
    // & uv for equations
    vec2 p = gl_FragCoord.xy / resolution.xy;
    float zoom = 2.;
    vec2 uv = gl_FragCoord.xy/zoom;
    
    // Get "pixel" coordinates for equations
    int x = int(uv.x);
    int y = int(uv.y);
    
    // Try some different equations from original tweet
    int b = x|y;                                                              // sierpinski:  (x|y) % time
    if(p.x > 0.5) b = x^y;                                                    // diagonals:   (x^y) % time
    if(p.y > 0.5 && p.x > 0.5) b = int(mod(mod(uv.x,uv.y), uv.y));            // sheets:      ((x%y) % y) % time
    if(p.y > 0.5 && p.x < 0.5) b = int(mod((uv.x * uv.y), 1024.));            // round noise: ((x*y) % 1024) % time
    
    // final output
    float bf = float(b);                               // convert to float
    bf = mod(bf, (1000. + time) * 0.005);             // start time at a larger number
    vec3 col = 1. - vec3(bf);                          // invert
    //if(mouse*resolution.xy.z > 0.5) {                               // hold mouse to threshold results
    //    float density = 0.85;
    //    col = (bf < density) ? vec3(1.) : vec3(0.);
    //    glFragColor = vec4(col,1.0);
    //} else {                                           // color cycle for fun
        col = vec3(0.5 + 0.5 * sin(col.r * 3.), 0.5 + 0.5 * sin(col.g * 4.), 0.5 + 0.5 * sin(col.b * 5.));
        glFragColor = vec4(col * (1. - bf/2.),1.0);
    //}
}
