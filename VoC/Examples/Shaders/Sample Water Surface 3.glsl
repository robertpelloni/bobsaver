#version 420

// original https://neort.io/art/c6rpaes3p9f3hsje6ji0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define COLOR_N vec3(0.15, 0.34, 0.6)

#define pi acos(-1.0)
#define twoPi pi*2.0

vec2 random2d2d(vec2 p){
    return fract(sin(vec2(dot(p, vec2(333.12, 63.587)), dot(p, vec2(2122.66, 126.734)))) * 5222.346);
}

float random(vec3 v) { 
    return fract(sin(dot(v, vec3(12.9898, 78.233, 19.8321))) * 43758.5453);
}

float valueNoise(vec3 v) {
    vec3 i = floor(v);
    vec3 f = smoothstep(0.0, 1.0, fract(v));
    return  mix(
        mix(
            mix(random(i), random(i + vec3(1.0, 0.0, 0.0)), f.x),
            mix(random(i + vec3(0.0, 1.0, 0.0)), random(i + vec3(1.0, 1.0, 0.0)), f.x),
            f.y
        ),
        mix(
            mix(random(i + vec3(0.0, 0.0, 1.0)), random(i + vec3(1.0, 0.0, 1.0)), f.x),
            mix(random(i + vec3(0.0, 1.0, 1.0)), random(i + vec3(1.0, 1.0, 1.0)), f.x),
            f.y
        ),
        f.z
    );
}

float fbm(vec3 v) {
    float n = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        n += a * valueNoise(v);
        v *= 2.0;
        a *= 0.5;
    }
    return n;
}

vec3 lattice(vec2 uv, float size){
    vec3 color = vec3(0.0);
    float f = fbm(vec3(uv, time*0.222));
    uv.y += pow(f, 4.0) - 0.3 * pow(f, 4.0) + 0.8 * pow(f, 3.0);
    uv.x += pow(f, 3.0) - 0.22 * pow(f, 7.0) + 0.9 * pow(f, 8.0);
    uv += time * 0.22;
    uv *= size;

    vec2 iPos = floor(uv);
    vec2 fPos = (fract(uv) - 0.5);// * 2.0;

    float maxDist = 9999.9;
    
    for(float y = -1.0; y <= 1.0; y+=1.0){
        for(float x = -1.0; x <= 1.0; x+=1.0){
            vec2 neighbor = vec2(x, y);
            vec2 point = random2d2d(iPos + neighbor);
            point = sin(time + point * twoPi) * 0.422 + 0.5;
            vec2 diff = neighbor + point - fPos;
            float dist = length(diff);

            maxDist = min(maxDist, dist);
        }
    }

    color += 1.0 - 0.22/mix(COLOR_N, vec3(1.0), pow(maxDist, 5.0));
    color += fbm(vec3(uv, time*1.1)) * 0.5;

    return color;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    color += lattice(uv, 5.0);

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 color = renderingFunc(uv);
    glFragColor = vec4(color, 1.0);
}
