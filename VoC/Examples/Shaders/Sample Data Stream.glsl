#version 420

// original https://www.shadertoy.com/view/tdBXDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define f gl_FragCoord.xy;
#define r resolution.xy
#define PI 3.1415926538
#define TWO_PI 6.2831853076

float random (in float x) {
    return fract(sin(x)*1e4);
}

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

float sstep(float v,float t) {
    return smoothstep(t-0.01,t+0.01,v);
}

float borders(float v,float w) {
    return sstep(v,1.-w);
}

float patt(in vec2 st) {
    vec2 sti = floor(st);
    vec2 stf = fract(st);
    float ra = random(sti) > 0.5 ? 1.0 : 0.0;
    vec2 st2 = fract(stf);
    return  borders(st2.y,0.8) *ra;
}

void main(void)
{

    float t = time+30942.122342;
    
    float lns = 64.0;
    float cols = 2.0;
    vec3 c;
    float speed = 0.2;
    
    vec2 st = gl_FragCoord.xy/r.xy;
    st.x *= cols;
    st.y *= lns; 

    
    for(int i = 0; i < 3; i++) {

        float fi = float(i+1);
        fi *= random(fi) * 2.0 - 1.0;

        float line = floor(st.y);
        float dir = random(line) * 2.0 - 1.0;

        vec2 st2 = st + vec2(t*speed*dir*fi,0.);

        c[i] = patt(st2);
        
    }
    
    glFragColor = vec4(c,1.0);
}
