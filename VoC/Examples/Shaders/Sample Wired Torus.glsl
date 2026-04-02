#version 420

// original https://www.shadertoy.com/view/ttd3RN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_MARCHING_STEPS 64
#define EPSILON 0.0001
#define MIN_FLOAT 1e-6
#define MAX_FLOAT 1e6
const float PI = acos(-1.); 
const float TAU = PI*2.; 
struct Ray{vec3 origin, direction;};
    
bool plane_hit(in vec3 ro, in vec3 rd, in vec3 po, in vec3 pn, out float dist) {
    float denom = dot(pn, rd);
    if (denom > MIN_FLOAT) {
        vec3 p0l0 = po - ro;
        float t = dot(p0l0, pn) / denom;
        if(t >= MIN_FLOAT && t < MAX_FLOAT){
            dist = t;
            return true;
        }
    }
    return false;
}

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

float fbm1x(float x, float time){
    float amplitude = 1.;
    float frequency = 1.;
    float y = sin(x * frequency);
    float t = 0.01*(-time * 130.0);
    y += sin(x*frequency*2.1 + t)*4.5;
    y += sin(x*frequency*1.72 + t*1.121)*4.0;
    y += sin(x*frequency*2.221 + t*0.437)*5.0;
    y += sin(x*frequency*3.1122+ t*4.269)*2.5;
    y *= amplitude*0.06;
    return y;
}

struct BreakdownAnimationState{
    float id;
    float phase; 
};

BreakdownAnimationState bas;

#define BAS_EXPAND 0.
#define BAS_ROTATE 1.
#define BAS_COLLAPSE 2.
#define BAS_END 3.
    
const int PHASES_COUNT = 3;
const float PHASES_DURATIONS[PHASES_COUNT] = float[PHASES_COUNT](1.5, 3.0, 4.5);

BreakdownAnimationState getBreakdownAnimationState(float time){
    time = mod(time, PHASES_DURATIONS[PHASES_COUNT - 1]);
    
    int id = 0;
    for(int i=1; i<=PHASES_COUNT; i++){
        if(time < PHASES_DURATIONS[i-1]){
            id = i-1;
            break;
        }
    }
    float phase = (time - (id == 0 ? 0. : PHASES_DURATIONS[id-1]))
                / (PHASES_DURATIONS[id] - (id == 0 ? 0. : PHASES_DURATIONS[id-1]));
    
    return BreakdownAnimationState(float(id), phase);
}

float getNormalizedBAS(BreakdownAnimationState bas, float id){
    if(id == bas.id)
        return bas.phase;
    else
        return step(id, bas.id);
    //return max(bas.phase, step(bas.id, id-1.));
}

float getInvNormalizedBAS(BreakdownAnimationState bas, float id){
    if(id == bas.id)
        return 1.-bas.phase;
    else
        return step(bas.id, id);
    //return max(1.-bas.phase, step(bas.id, id-1.));
}

float sdCappedCylinder(vec3 p, float h, float r){
    vec2 d = abs(vec2(length(p.zy), p.x)) - vec2(h,r);
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

vec3 noodles(vec3 worldPos, float h){
    vec2 rp = vec2(atan(worldPos.z, worldPos.y) + worldPos.x*TAU*2.11, length(worldPos.yz));
    float id = floor(rp.x/(PI/32.));
    rp.x = mod(rp.x, PI/32.)-PI/64.;
    worldPos.yz = (rp.y+fbm1x(id*37.13, time*.5) * .25) * vec2(sin(rp.x), cos(rp.x));
    float size = pow(getInvNormalizedBAS(bas, BAS_COLLAPSE), .5)*.6 - .3;
    worldPos.z -= size * 10.;
   
    h -= fbm1x(id * 1.13, 1.) * 0.125 * smoothstep(.25, .2, distance(h, .25));
    worldPos.x -= h;
    return vec3(sdCappedCylinder(worldPos, .075, h), id, worldPos.x + h);
}

float outer(vec3 worldPos){
    float a = radians(90.);
    worldPos.xz *= mat2(cos(a), -sin(a), sin(a), cos(a));
    return sdCappedCylinder(worldPos, 8.2, 3.5);
}

vec3 world(vec3 worldPos){
    float size = 5.;
    worldPos = vec3((atan(worldPos.x, worldPos.y)/TAU+.5), length(worldPos.xy) - size, worldPos.z);
    float phase = getNormalizedBAS(bas, BAS_EXPAND)*.5;
    return noodles(worldPos, phase);
}

vec3 march(vec3 eye, vec3 marchingDirection){
    const float precis = .01;
    
    float t = 0.;
    bool hitOuter = false;
    for(int i=0; i<32; i++){
        float hit = outer(eye + marchingDirection * t);
        if(hit < .05){
            hitOuter = true;
        }
        t += hit;
        if(hitOuter)
            break;
    }
    if(hitOuter)
        for(int i=0; i<MAX_MARCHING_STEPS; i++){
            vec3 hit = world(eye + marchingDirection * t);
            if(hit.x < precis) return vec3(t, hit.gb);
            t += hit.x * .5;
        }

    return vec3(-1.);
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        world(vec3(p.x + EPSILON, p.y, p.z)).x - world(vec3(p.x - EPSILON, p.y, p.z)).x,
        world(vec3(p.x, p.y + EPSILON, p.z)).x - world(vec3(p.x, p.y - EPSILON, p.z)).x,
        world(vec3(p.x, p.y, p.z  + EPSILON)).x - world(vec3(p.x, p.y, p.z - EPSILON)).x
    ));
}

vec3 color1 = vec3(248., 241., 212.)/255.;
vec3 color2 = vec3(241., 150., 69.)/255.;

vec4 render(){
    vec3 color = vec3(.15);
    //float a = mouse*resolution.xy.x/resolution.x * PI * 2.;
    float a = PI*.15 + PI * pow(getNormalizedBAS(bas, BAS_ROTATE), 4.);
    vec3 eye = vec3(30. * sin(a), 0., 30. * cos(a));
    vec3 viewDir = rayDirection(60., resolution.xy);
    vec3 worldDir = viewMatrix(eye, vec3(0.), vec3(0., 1., 0.)) * viewDir;
    
    vec3 hit = march(eye, worldDir);
    if (hit.x > 0.) {
        vec3 p = (eye + hit.x * worldDir);
        vec3 norm = estimateNormal(p);
        color = color1;
        if(floor(mod(hit.y, 15.)) == 0. || floor(mod(hit.y, 15.)) == 2.)
            color = color2;
        color *= 1. - .125 * smoothstep(4., 5., mod(hit.y, 10.));
        color *= abs(pow(dot(worldDir, norm), 2.));
    }
    return vec4(color, 1.);
}

#define AA 2
void main(void) {
    bas = getBreakdownAnimationState(time);
    glFragColor = vec4(0.);
    for(int y = 0; y < AA; ++y)
        for(int x = 0; x < AA; ++x){
            glFragColor += clamp(render(),0., 1.);
        }
    glFragColor.rgb /= float(AA * AA);
}
