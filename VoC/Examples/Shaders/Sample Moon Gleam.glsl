#version 420

// original https://www.shadertoy.com/view/4tGfWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 LIGHT_POS = vec3(0.0, 10.0, -100.0);
const vec3 LIGHT_COL = vec3(0.7, 0.7, 0.9);
const vec3 WATER_COL = vec3(0.4, 0.7, 1.0);

const float WAVE_FREQ = 1.0;
const float WAVE_AMP = 0.03;
const float WAVE_SPEED = 0.3;
const float SPEC_EXP = 64.0;

float rand( vec2 p ) {
    float h = dot(p,vec2(127.1,311.7));    
    return fract(sin(h)*43758.5453123);
}

float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );    
    vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( rand( i + vec2(0.0,0.0) ), 
                     rand( i + vec2(1.0,0.0) ), u.x),
                mix( rand( i + vec2(0.0,1.0) ), 
                     rand( i + vec2(1.0,1.0) ), u.x), u.y);
}

float sphereDF(vec3 p, float rad) {
    return length(p) - rad;
}

float oct(vec2 uv) {
    uv += noise(uv);
    uv = 1.0 - abs(sin(uv));
    return pow(1.0 - uv.x * uv.y, 8.0);
}

float waveDist(vec3 p) {
    vec2 uv = p.xz;
    
    float d = 0.0;
    float freq = WAVE_FREQ;
    float amp = WAVE_AMP;
    for (int i = 0; i < 3; ++i) {
        d += amp * oct((uv + (2.0 + time) * WAVE_SPEED) * freq);
        d += amp * oct((uv - (2.0 + time) * WAVE_SPEED) * freq);
        amp *= 0.5;
        freq *= 1.5;
    }
    
    return d;
}

float planeDF(vec3 p, float y) {
    return p.y - y;
}

float boxDF(vec3 p, vec3 b) {
    return length(max(abs(p) - b, 0.0)) - 0.1;
}

float capDF(vec3 p, float h, float r) {
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

float subDF(float a, float b) {
    return max(a, -b);
}

vec4 mapU(vec4 a, vec4 b) {
    return a.w < b.w ? a : b;
}

float waves(vec3 p, float y) {
    return planeDF(p, y) - waveDist(p);
}

mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c         );
}

float moon(vec3 p, float r) {
    return sphereDF(p, r);
}

vec4 map(vec3 p) {
    vec4 ret =      vec4(vec3(0.0), waves(p, -1.0));
    ret = mapU(ret, vec4(LIGHT_COL, moon(p - LIGHT_POS, 2.0)));
    
    return ret;
}

vec3 normal(vec3 p) {
    float eps = 0.01;
    vec3 norm = vec3(
        map(vec3(p.x + eps, p.y, p.z)).w - map(vec3(p.x - eps, p.y, p.z)).w,
        map(vec3(p.x, p.y + eps, p.z)).w - map(vec3(p.x, p.y - eps, p.z)).w,
        map(vec3(p.x, p.y, p.z + eps)).w - map(vec3(p.x, p.y, p.z - eps)).w
    );
    return normalize(norm);
}

float shadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    for (float t = mint; t < maxt;) {
        float h = map(ro + rd * t).w;
        if (h < 0.001)
            return res;
        t += h;
        res = min(res, k * h / t);
    }
    return clamp(res, 0.0, 1.0);
}

vec3 render(vec3 ro, vec3 rd) {
    float mint = 0.0;
    float maxt = 150.0;
    
    bool found = false;
    vec3 surfPos = ro;
    vec3 mapCol = vec3(0.0);
    for (float t = mint; t < maxt;) {
        surfPos = ro + t * rd;
        vec4 mapVal = map(surfPos);
        float h = mapVal.w;
        if (h < 0.001) {
            found = true;
            mapCol = mapVal.xyz;
            break;
        }
        t += h;
    }
    
    vec3 col = vec3(1.0);
    if (found && mapCol != LIGHT_COL) {
        vec3 norm = normal(surfPos);
        vec3 ref = reflect(rd, norm);
        float ndl = dot(ref, normalize(LIGHT_POS - surfPos));

        vec3 amb = 0.1 * normalize(LIGHT_COL);
        vec3 dif = normalize(WATER_COL);
        dif *= 0.1 * ndl;
        
        vec3 spe = normalize(LIGHT_COL);
        spe *= pow(ndl, SPEC_EXP);

        col = amb + dif + spe;
    } else if (mapCol == LIGHT_COL) {
        vec3 p = normalize(surfPos - LIGHT_POS);
        vec2 sph = vec2(acos(p.z), atan(p.y / p.x));
        
        col = normalize(LIGHT_COL);
        col *= vec3(0.5 + sin(p.x) + sin(p.z));
        col -= 0.1 * (1.0 + noise(4.0 * sph));;
    } else {
        col = vec3(0.05, 0.07, 0.1);
    }
    
    return clamp(col, 0.0, 1.0);
}

mat3 setCamera( vec3 ro, vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 mouseCurr = mouse*resolution.xy.xy / resolution.xy;
    
    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 camPos = vec3(0.0, 15.0 * (1.0 - mouseCurr.y), 50.0);
    vec3 ro = camPos;
    mat3 ca = setCamera(ro, vec3(0.0), 0.0);
    vec3 rd = ca * normalize(vec3(p, 3.2));

    vec3 col = render(ro, rd);
    
    glFragColor = vec4(col, 1.0);
}
