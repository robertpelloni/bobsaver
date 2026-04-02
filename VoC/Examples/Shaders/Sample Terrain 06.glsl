#version 420

// original https://www.shadertoy.com/view/tsl3zl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LOD_CLOSE 50.
#define LOD_FAR    4.

#define COL_SKY_TOP vec3(.46, .84, .89)
#define COL_SKY_BOT vec3(.80, .97, 1.0)
#define COL_STONE_1 vec3(.50, .50, .50)
#define COL_STONE_2 vec3(.35, .35, .35)
#define COL_SNOW_1  vec3(1.4, 1.4, 1.4)
#define COL_GRASS_1 vec3(.47, .56, .19)
#define COL_GRASS_2 vec3(.30, .56, .19)
#define COL_SAND_1  vec3(.92, .79, .59)
#define COL_WATER_1 vec3(1.2, 1.0, 1.2)
#define COL_WATER_2 vec3(0.7, .50, 0.7)

const vec3 sunDir = normalize(vec3(1, 1, -1));

// https://www.shadertoy.com/view/4djSRW
vec2 hash22(vec2 st) {
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

float gradientNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f*f * (3. - 2.*f);
    
    return mix(
        mix(
            dot(hash22(i), f),
            dot(hash22(i + vec2(1., 0.)), f - vec2(1., 0.)),
            u.x
        ),
        
        mix(
            dot(hash22(i + vec2(0., 1.)), f - vec2(0., 1.)),
            dot(hash22(i + vec2(1., 1.)), f - vec2(1., 1.)),
            u.x
        ),
        
        u.y
    );
}

float terrainHeight(vec2 p, float lod, float water) {
    float height = 0.;
    
    for(float i = 1.; i < lod; i += 2.) {
        height += gradientNoise((p + i) * i) / pow(i, 1.8);
    }
    
    return max(pow(height * .5 + .5, 2.), water);
}

#define EPSILON 0.01
vec3 terrainNormal(vec2 p, float lod) {
    vec2 e = vec2(EPSILON, 0);
    return normalize(vec3(
        (terrainHeight(p + e.xy, lod, 0.) - terrainHeight(p - e.xy, lod, 0.)),
        EPSILON,
        (terrainHeight(p + e.yx, lod, 0.) - terrainHeight(p - e.yx, lod, 0.))
    ));
}

float calculateLOD(float dist) {
    return mix(LOD_CLOSE, LOD_FAR, smoothstep(0., 8., dist));
}

vec3 raymarch(vec3 pos, inout vec3 dir, out vec3 reflNml, out float depth) {
    vec3 startPos = pos;
    for(int i = 0; i < 32; ++i) {
        float lod = calculateLOD(distance(pos, startPos));
        float dist = pos.y - terrainHeight(pos.xz * 0.5, lod, 0.1) * 2.;
        pos += dir * dist;
        
        if(abs(0.2 - pos.y) < 0.01) {
            reflNml = terrainNormal(pos.xz * vec2(20., 60.) + vec2(time), 4.);
            reflNml = normalize(sign(reflNml) * sqrt(abs(reflNml)) * vec3(.2, 1., .2));
            depth = 0.2 - terrainHeight(pos.xz * 0.5, 4., 0.);
            
            dir = reflect(dir, reflNml);
            pos += vec3(0, 0.04, 0);
            i = 0;
        }
    }
    return pos;
}

vec3 skyColor(vec3 dir) {
    return mix(COL_SKY_BOT, COL_SKY_TOP, dot(dir, vec3(0,1,0)) * .5 + .5);
}

vec3 terrainColor(vec3 pos, inout vec3 nml) {
    float slope = dot(nml, vec3(0,1,0));
    vec2 roundedPos = floor(pos.xz * 1000.) * 0.001;
    
    float sparkle = smoothstep(.9, 1., hash22(roundedPos).r + hash22(pos.xz).r * 0.1) * .2 + 1.;
    float altCol = gradientNoise(pos.xz * 20.);
    
    vec3 grass = mix(COL_GRASS_1, COL_GRASS_2, altCol) * (hash22(roundedPos).r * .10 + .90);
    vec3 stone = mix(COL_STONE_1, COL_STONE_2, altCol) * (hash22(roundedPos).r * .05 + .95);
    vec3 sand  = COL_SAND_1 * sparkle;
    vec3 snow  = COL_SNOW_1 * sparkle;
    
    vec3 stoneNml = terrainNormal(pos.zx * 10. - 100., 16.);
    stoneNml = normalize(mix(nml, stoneNml, 0.5));
    nml = normalize(mix(stoneNml, nml, smoothstep(.7, .8, slope)));
    
    return mix(
        stone,
        mix(
            mix(sand, grass, smoothstep(.1, .2, pos.y)),
            snow,
            smoothstep(.27, .32, pos.y)
        ),
        smoothstep(.7, .8, slope)
    );
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

void main(void) {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec3 pos = vec3(0, 1.3, time * 0.5);
    vec3 dir = normalize(vec3(uv, 1.));
    dir *= viewMatrix(pos, pos - vec3(0,1,2), vec3(0,1,0));
    
    vec3 reflNml = vec3(0);
    float depth = 0.;
    vec3 hit = raymarch(pos, dir, reflNml, depth);
    
    float lod = calculateLOD(distance(pos, hit));
    vec3 nml = terrainNormal(hit.xz * .5, lod);
    vec3 terrainCol = terrainColor(hit * .5, nml);
    float diffuse = dot(nml, sunDir) * 0.5 + 0.5;
    
    float fog = clamp(distance(pos, hit) * 0.1, 0., 1.);
    glFragColor = vec4(mix(
        terrainCol * diffuse,
        skyColor(dir),
        fog
    ), 1);
    
    if(length(reflNml) > 0.1) {
        depth = 1. - depth * 10.;
        glFragColor *= vec4(mix(COL_WATER_2, COL_WATER_1, depth), 1.);
        glFragColor += vec4(1. - COL_WATER_1, 0.);
        
        float angle = pow(clamp(dot(reflNml, dir), 0., 1.), 2.) * 0.8;
        glFragColor  = vec4(mix(glFragColor.rgb, COL_SAND_1 * depth, angle), 1.);
    }
}
