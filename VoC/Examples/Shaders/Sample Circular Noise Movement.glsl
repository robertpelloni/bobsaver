#version 420

// original https://www.shadertoy.com/view/ttjGDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

// Value Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

float circle(vec2 st, vec2 center, float radius) {
    return smoothstep(1., 1.-0.025, distance(st, center) / radius);
}

float ring(vec2 st, vec2 center, float radius) {
    return circle(st, center, radius) - circle(st, center, radius - 0.020);
}

void main(void) {
    vec2 st = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    vec3 color = vec3(0.0);
    
    float r = 0.67,
        a = atan(st.y, st.x),
        noiseA = a + time;
    
    vec2 nPos = vec2(cos(noiseA), sin(noiseA));
    
    float n = noise(nPos),
        n2 = noise(vec2(cos(noiseA), sin(noiseA)) + time);
    
    r += sin(a*10.) * n*.18;
    r += sin(a*30.) * n2*.08;
    
    float pct = ring(st, vec2(0.), r); 
    color = vec3(0.3, 0.9, 0.9) * pct + vec3(0.3, 0.9, 0.5) * pct * n * 2.;
    glFragColor = vec4(color,1.0);
}
