#version 420

// original https://www.shadertoy.com/view/wdsyDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265;

void main(void) {

    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

    for (int i=0; i<3; i++) {
        p = abs(p)/dot(p,p);
        p -= vec2(sin(time*0.1347), cos(time*0.1473));
    }
    
    vec4 s1 = vec4(1.0, 1.0, 7.0, 2.0);
    vec4 s2 = vec4(4.0, 4.0, 2.0, 4.6);

    float tx = sin(time)*0.2347; 
    float ty = cos(time)*0.2473; 

    vec4 s = mix(s1, s2, vec4(tx,tx,ty,ty));

    float amp = 
        s.x * sin(PI*s.z*p.x) * sin(PI*s.w*p.y) + 
        s.y * sin(PI*s.w*p.x) * sin(PI*s.z*p.y);

    glFragColor = vec4(1.0 - smoothstep(abs(amp), 0.0, 0.1));
}
