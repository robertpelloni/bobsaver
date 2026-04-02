#version 420

// original https://neort.io/art/bq321hs3p9fefb927790

// Uses parts of 'Rainy City' by ndxbxrme.
// https://www.shadertoy.com/view/wtt3WB

precision highp float;

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define TAU 6.28318530718
#define PI 3.141592
#define Octaves 8
#define OCTAVES 4

float circ(vec2 p) {
    float r = length(p);
    r = 0.2 * log(r);
    return abs(mod(r*5.0,TAU)-3.14)*2.0+2.2;
}

float random (vec2 st){
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float boxnoise(vec2 st){
    vec2 p = floor(st);
    return random(p);
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

float city (vec2 uv, float offset, float height,float width)
{
    vec2 grid = vec2(width, 1.);
    uv.x += offset;
    float n1 = fbm((vec2(ivec2(uv * grid)) + .5));
    uv.x *= n1 * 6.;
    vec2 id = vec2(ivec2(uv * grid)) + .5;
    float n = fbm(id);
    float buildingHeight = n * height;
    buildingHeight = (n1 > .3) ? buildingHeight + fract(uv * grid).x * n1 * .0 : buildingHeight;
    return (uv.y < buildingHeight) ? 1.0 : 0.;
}

void main(void) {
    vec2 p = gl_FragCoord.xy / resolution.xy-0.5;
    p.x *= resolution.x/resolution.y;

    p*=12.0;
    
    float time = time * 0.25;

    vec2 pixuv = vec2((gl_FragCoord.xy / resolution.xy-0.5).x * 1.0, (gl_FragCoord.xy / resolution.xy-0.5).y * 1.0);

    
    vec2 p2 = mod(pixuv*TAU, TAU)-250.0;
    vec2 s = vec2(p2);
    float c = 1.0;
    float inten = 0.005;
    
    for (int n = 0; n < Octaves; n++) 
        {
            float t = time * (1.0 - (3.0 / float(n+1)));
            s = p + vec2(cos(t - s.x) + sin(t + s.y), sin(t - s.y) + cos(t + s.x));
            c += 1.0/length(vec2(p2.x / (sin(s.x+t)/inten),p2.y / (cos(s.y+t)/inten)));
        }
        c /= float(Octaves);
        c = 1.17-pow(c, 1.4);
    
    float colr = pow(abs(c),8.0);
  
    p /= exp(mod((0.5)*6.0,PI)); 
    colr *= pow(abs((0.3-circ(p+vec2(0,-0.2)))),3.0);
    

    vec3 col = vec3(1.0,1.0,1.5)/colr;
    col=pow(col,vec3(1.0,0.9,0.85));
    col -= city((gl_FragCoord.xy / resolution.xy), 1.5, 0.7, 30.0) * .08;
    col += city((gl_FragCoord.xy / resolution.xy), 1.0, 0.65, 20.0) * .02;

    glFragColor = vec4(col, 1.0);
}
