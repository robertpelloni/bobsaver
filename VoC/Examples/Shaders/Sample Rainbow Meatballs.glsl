#version 420

// original https://www.shadertoy.com/view/tsXyDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_MARCH_STEPS 120
#define CLIP_DIST 1000.0
#define EPSILON 0.01

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float texNoise(vec3 p) {
    return 0.0;//texture(iChannel0, vec2(p.xy)).r;
}

float sdBall(vec3 pos, float radius)
{
    return 0.006*texNoise(1.5*pos) + 0.04*noise(5.*pos) + length(pos) - radius;
}

float sceneSDF(vec3 pos) {
    pos = mod(pos, 10.0) - 5.0;
    
    float temp;
    float dist = CLIP_DIST;

    dist = (temp = sdBall(pos - vec3(0.0, 0.0, 5.0), 1.0)) < dist ? temp : dist;

    return dist;
}

float raymarch(vec3 ro, vec3 rd, float mint, float maxt) {
    float depth = mint;
    for(int i=0;i<MAX_MARCH_STEPS;i++)  {
        float dist = sceneSDF(ro+rd*depth);
        if (dist < EPSILON) return depth;

        depth += dist;
        if (depth > maxt) break;
    }

    return maxt;
}

vec3 calcNormal(vec3 pos) {
    const vec2 eps = vec2(0.001, 0.0);

    vec3 nor = vec3(
        sceneSDF(pos + eps.xyy) - sceneSDF(pos - eps.xyy),
        sceneSDF(pos + eps.yxy) - sceneSDF(pos - eps.yxy),
        sceneSDF(pos + eps.yyx) - sceneSDF(pos - eps.yyx));
    return normalize(nor);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 aspect = vec2(1.0, resolution.y / resolution.x);
    uv = 2.0 * uv - 1.0;
    uv *= aspect;

    vec3 col = vec3(0.0);

    vec3 ro = vec3(2.0*cos(time), 5.0, 2.0*sin(time));

    const float FOV = 90.0;
    const float RDF = 1.0 / tan(radians(FOV / 2.0));
    vec3 rd = normalize(vec3(uv, RDF));

    float dist = raymarch(ro, rd, 0.01, CLIP_DIST);

    if (dist < CLIP_DIST) {
        vec3 hitPos = ro + rd*dist;

        vec3 normal = calcNormal(hitPos);

        const vec3 lightPosition = vec3(-2.0, 2.0, 1.0);
        float lightness = max(0.0, dot(-normalize(hitPos - lightPosition), normal));

        col = vec3(mod(hitPos / 30., 1.));
        col = smoothstep(0., 1., col); // Brightens up the colors
        col *= 0.2 + 0.8*lightness;
        col *= mix(1.0, 0.0, length(hitPos - lightPosition) / 250.0);
    }

    col = pow (col, vec3 (1.0 / 2.2)); // Gamma correction
    glFragColor = vec4(col, 1.0);
}

