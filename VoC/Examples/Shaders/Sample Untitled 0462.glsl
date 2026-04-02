#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main() {

    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    vec3 col = vec3(0.);
    
    vec3 p = vec3(0);
    vec3 ro = vec3(0, 0, time * 8.);
    vec3 rd = vec3(uv, 1);
    float t = 0.;
    for (int i = 0; i < 64; i++) {
        p = ro + rd * t;
        float z = p.z;
        p = mod(p, 4.) - 2.;
        t += .5 * min(min(length(p.xy) - .8 - .1 * cos(z * .5 + time), length(p.yz) - .1), length(p.xz) - .1);
    }
            
    // little code to make fog
    float f = 1. - exp(-t * .2); // smooth transition and plateu from 0 - 1
    float s = max(dot(rd, vec3(0, .6, 0)), 0.); // is the camera (rd) looking at the light / sun 
    col = mix(col, mix(vec3(1, .5, 0), vec3(0, 1, 1), s), f); // mix the main color with the scene color based on fog amt
    
    glFragColor = vec4(col, 1.);

}
