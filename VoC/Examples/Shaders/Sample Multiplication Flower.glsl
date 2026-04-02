#version 420

// original https://www.shadertoy.com/view/lllSDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define s(k) .7*sin(i/32.*(k)+vec2(1.6,0))

void main(void) {
    glFragColor=vec4(0.0);
    for (float i=1.; i<=200.; i++) {
        vec2 a=s(1.), b=s(time/5.+2.)-a;
        a += 2.*gl_FragCoord.xy/resolution.xy -vec2(1.,1);
        glFragColor += clamp( .23 - 33.*length( a + b*fract(-dot(a,b)/dot(b,b)) ), 0., .33);
    }
}
