#version 420

// original https://www.shadertoy.com/view/3dtSWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define N 6.

// https://vogerdesign.com/collections/latest-ui-kits/products/dials-light-set-vol-1

const float r1 = 0.66;
const float r2 = 1./r1;

vec4 check(vec2 uv) {
    return vec4(vec3(.12+0.06*mod(floor(5.0*uv.x)+floor(5.0*uv.y),2.0)), 1.);
}

vec4 over( in vec4 a, in vec4 b ) {
    return a + b*(1.0-a.w);
}

vec4 mAlpha( vec4 c ) {
    return vec4(c.xyz * c.w, c.w);
}

vec4 dAlpha( vec4 c ) {
    return vec4(c.xyz / c.w, 1.0);
}

float nCap(vec2 uv, float angle) {
    float a = atan(uv.y, uv.x)+angle;
    float b = a/PI*N/2.-PI*r1*2.0;
    float f = fract(b);
    float l = length(uv);
    float d = sin(f*PI*r2) * step(f, r1);
    return (1.-d*0.1)*.5-l;
}

float line( in vec2 p, in vec2 a, in vec2 b ) {
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/-resolution.y*2.0;
    
    float av = sin(time*1.5)*PI*.9; // angle value
    
    float a = atan(uv.y, uv.x);
    float l = length(uv);
    float sCap = nCap(uv, av); // n-gon shape
    float dCap = nCap(uv+vec2(.0,-.3), av); // shadow
    float capA = smoothstep(0.001, 0.01, sCap); // fill
    float capB = smoothstep(.0, .02, 0.01-abs(sCap-.01)); // edge
    vec3 color = vec3(.96,.96, 1.);
    mat2 m = mat2(cos(av), sin(av), -sin(av), cos(av));
    
    vec4 col;
    
    float g = -1. + smoothstep(.5, -.5, uv.y) * 2.;
    col = mAlpha(check(uv));
    col = over(mAlpha(vec4(vec3(0), smoothstep(0.01, 0.08, dCap)*.7)), col); // cap shadow
    col = over(mAlpha(vec4(vec3(.50+g*.2), smoothstep(0.02, 0.01, l-0.47))), col); // cap round
    col = over(mAlpha(vec4(vec3(0), smoothstep(0.005, 0.002, abs(l-0.48))*.1)), col); // cap round edge
    col = over(mAlpha(vec4(color*(.70+g*.2)+capB*g*.3, capA)), col); // cap + edge
    col = over(mAlpha(vec4(color*(.30+sin(a*2.0)*0.15+sin(a*5.0)*0.03)+g*.04, smoothstep(0.02, 0.01, l-0.36))), col); // cap metal
    col = over(mAlpha(vec4(vec3(.5+g), smoothstep(0.008, 0.001, abs(l-0.368))*.5)), col); // cap metal edge
    col = over(mAlpha(vec4(vec3(1.), smoothstep(0.02, 0., line(uv, vec2(.0, -.16)*m, vec2(.0, -.34)*m))*.8)), col); // line value

    glFragColor = dAlpha(col);
}
