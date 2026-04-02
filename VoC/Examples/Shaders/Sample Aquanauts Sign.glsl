#version 420

// original https://neort.io/art/bq0qmnc3p9fefb926920

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define OCTAVES 5

vec2 random2(vec2 st){
    st = vec2(dot(st, vec2(127.1, 311.7)),
    dot(st, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

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

    for (int i = 0; i < OCTAVES; i++)
    {
        v += a * noise(st);
        st = st * 2.0;
        a *= 0.5;
    }

    return v;
}

float cellular(vec2 st, float num, float s, float b,float con){
    vec2 q = vec2(0.0, 0.0);
    q.x = fbm(st + vec2(0.0, 0.0));
    q.y = fbm(st + vec2(1.0, 1.0));
    q *= num; 
               
    vec2 ist = floor(q);
    vec2 fst = fract(q);

    float distance = 5.0;
     
    for (int y = -1; y <= 1; y++)
    for (int x = -1; x <= 1; x++)
    {
        vec2 neighbor = vec2(x, y);
        vec2 p = 0.5 + 0.5 * sin((time  + 6.2831 * random2(ist + neighbor)) * s);
        vec2 diff = neighbor + p - fst;
        distance = min(distance, length(diff));
    }

    return pow(distance * b,con);
}

void main(void) {
    vec2 st = gl_FragCoord.xy / resolution;
    vec3 color = vec3(0.0);
    float num = 15.0;
    float s = 0.5;
    float b = 1.1 ;
    float con = 4.0;
    
    color.r = float(cellular(st,num,s,b,con));
    color.g = float(cellular(st - vec2(0.004,0),num,s,b,con));
    color.b = float(cellular(st - vec2(0.006,0),num,s,b,con));
    
    color *= 1.0 - st.y;
    vec3 f = mix(vec3(0.1, 0.4, 0.9) * 1.5, vec3(0.1, 0.2, 0.5) * .2, st.y);
 
    f += color;

    glFragColor = vec4(f,1.0);
}
