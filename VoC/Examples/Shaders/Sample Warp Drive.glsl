#version 420

// original https://neort.io/art/bq295cs3p9fefb926sf0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define tau 6.2831853
#define PI 3.141592
#define Octaves 4

float random (vec2 st){
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise (vec2 st){
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i + vec2(0.0, 0.0));
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 st){
    float v = 0.0;
    float a = 0.6;

    for (int i = 0; i < Octaves; i++)
    {
        v += a * noise(st);
        st = st * 2.0;
        a *= 0.5;
    }

    return v;
}

float circ(vec2 p) {
    float r = length(p);
    r = 0.5 * log(r);
    return abs(mod(r*4.,tau)-3.14)*2.5+0.8;
}

void main(void) {
    vec2 p = gl_FragCoord.xy / resolution.xy-0.5;
    p.x *= resolution.x/resolution.y;
    p*=5.0;
    
    float vignet = length(p);
    p /=1.0 - vignet * 1.0;
    
    
    vec2 q = vec2(0.0, 0.0);
    q.x = fbm(p + vec2(0.0, 0.0));
    q.y = fbm(p + vec2(1.0, 1.0));
    
    vec2 r = vec2(0.0, 0.0);
    r.x = fbm(p + (4.0 * q) + vec2(1.7, 9.2) + (0.65 * time));
    r.y = fbm(p + (4.0 * q) + vec2(8.3, 2.8) + (0.38 * time));
    
    float f = fbm(p + 4.0 * r);
    float sf = (f * f * f + (0.6 * f * f) + (0.5 * f) + (0.2 * f));
    
    p *= exp(mod((time*0.3)*5.0,PI));
    sf *= pow(abs((0.1-circ(p))),2.5);
    
    vec3 col = vec3(0.1,0.4,1.0)/sf;
    col=pow(col,vec3(1.0,0.7,0.5));
    

    glFragColor = vec4(col, 1.0);
}
