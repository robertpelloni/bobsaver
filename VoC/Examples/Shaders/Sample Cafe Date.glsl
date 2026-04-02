#version 420

// original https://www.shadertoy.com/view/NdVGWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1416
#define FAR 10.0
#define MAX_RAY 92
#define MAX_REF 16
#define FOV 1.57
#define OBJ_MIN_D 0.01

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

float rand(float seed) {
    float v = pow(seed, 6.0 / 7.0);
    v *= sin(v) + 1.;
    return v - floor(v);
}

vec3 col(float x) {
    return vec3(
        .5 * (sin(x * 2. * PI) + 1.),
        .5 * (sin(x * 2. * PI + 2. * PI / 3.) + 1.),
        .5 * (sin(x * 2. * PI - 2. * PI / 3.) + 1.)
    );
}

float smin( float a, float b, float s ){

    float h = clamp( 0.5+0.5*(b-a)/s, 0.0, 1.0 );
    return mix( b, a, h ) - s*h*(1.0-h);
}

float smod(float x, float m) {
    return (1. - step(m * .95, mod(x, m))) * min(m, mod(x, m) * 1.05) + step(m * .95, mod(x, m)) * min(m, mod(-x, m) * 40.); 
}

vec3 rot(vec3 v, vec3 c, vec3 a) {
    return (v - c)
    * mat3(1, 0, 0,
         0, cos(a.x * 2. * PI), sin(a.x * 2. * PI),
         0, -sin(a.x * 2. * PI), cos(a.x * 2. * PI))
    * mat3(cos(a.y * 2. * PI), 0, sin(a.y * 2. * PI),
         0, 1, 0,
         -sin(a.y * 2. * PI), 0, cos(a.y * 2. * PI))
    * mat3(cos(a.z * 2. * PI), sin(a.z * 2. * PI), 0,
         -sin(a.z * 2. * PI), cos(a.z * 2. * PI), 0,
         0, 0, 1) + c;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

float sphere(vec3 q, vec3 p, float r) {
    return length(q - p) - r;
}

float plane(vec3 q, vec3 d, float offset) {
    return dot(d, q) + offset;
}

float capsule(vec3 q, vec3 p1, vec3 p2, float r) {
    vec3 ab1 = p2 - p1;
    vec3 ap1 = q - p1;
    float t1 = dot(ap1, ab1) / dot(ab1, ab1);
    t1 = clamp(t1, 0., 1.);
    vec3 c1 = p1 + t1 * ab1;
    return length(q - c1) - r;
}

float torus(vec3 q, vec3 p, float r1, float r2) {
    q -= p;
    float x = length(q.xz) - r1;
    return length(vec2(x, q.y)) - r2;
}

float box(vec3 q, vec3 p, vec3 s, float r) {
    return length(max(abs(q - p) - s + r, 0.)) - r;
}

float cyl(vec3 q, vec3 p1, vec3 p2, float r) {
    vec3 ab2 = p2 - p1;
    vec3 ap2 = q - p1;
    float t2 = dot(ap2, ab2) / dot(ab2, ab2);
    vec3 c2 = p1 + t2 * ab2;
    float d = length(q - c2) - r;
    float y = (abs(t2 - .5) - .5) * length(ab2);
    float e = length(max(vec2(d, y), 0.));
    float i = min(max(d, y), 0.);
    return e + i;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define OBJ_COUNT 6

float objects[OBJ_COUNT] = float[](FAR, FAR, FAR, FAR, FAR, FAR);
vec3 objectsColor[OBJ_COUNT] = vec3[](vec3(1.), vec3(1.), vec3(1.), vec3(1.), vec3(1.), vec3(1.));
const float objectsRef[OBJ_COUNT] = float[](.4,.0,.0,.0,.3,.1);

void setObjects(vec3 q) {
    objects[0] = FAR;
    objects[0] = min(objects[0], plane(q, vec3(.0, 1., .0), 0.));
    
    vec3 q2 = q;
    q2.x = mod(q.x, 2.);
    q2.z = mod(q.z, 1.);
    
    float chair_seed = abs(floor(q.x)) * 100. + abs(floor(q.z)) * 100. + 100.;
    float table_seed = abs(floor(q.x * .5)) * 100. + abs(floor(q.z)) * 100. + 100.;
    
    vec3 q3 = q2;
    if(q2.x < 1.) {
        q3.x = 1. - q2.x + .1 * rand(chair_seed++);
    } else if (q2.x < 2.) {
        q3.x -= 1. + .1 * rand(chair_seed++);
    }
    
    vec3 q4 = rot(q3, vec3(.5), vec3(.0, .04 * (rand(chair_seed++) - .5),.0));
    
    objects[1] = FAR;
    objects[1] = min(objects[1], box(q4, vec3(.5, .3, .5), vec3(.2, .02, .2), .005));
    objects[1] = min(objects[1], box(q4, vec3(.69, .3, .69), vec3(.01, .3, .01), .005));
    objects[1] = min(objects[1], box(q4, vec3(.69, .3, .31), vec3(.01, .3, .01), .005));
    objects[1] = min(objects[1], box(q4, vec3(.31, .15, .31), vec3(.01, .15, .01), .005));
    objects[1] = min(objects[1], box(q4, vec3(.31, .15, .69), vec3(.01, .15, .01), .005));
    objects[1] = min(objects[1], box(q4, vec3(.69, .59, .5), vec3(.01, .05, .2), .005));
    
    objects[2] = FAR;
    objects[2] = min(objects[2], box(q4, vec3(.49, .33, .5), vec3(.24, .02 + .0005 * sin(q2.x * 200.) * sin(q2.z * 200.), .25), .1));
    objects[2] = min(objects[2], box(q4, vec3(.65, .59, .5), vec3(.03 + .0005 * sin(q2.y * 200.) * sin(q2.z * 200.), .1, .22), .05));
    
    q2 = rot(q2, vec3(.5), vec3(.0, .01 * (rand(table_seed++) - .5),.0));
    
    objects[3] = FAR;
    objects[3] = min(objects[3], box(q2, vec3(1., .5, .5), vec3(.3, .02, .3), .0));
    
    objects[4] = FAR;
    objects[4] = min(objects[4], cyl(q2, vec3(1., .0, .5), vec3(1., .5, .5), .05));
    
    vec3 cup_center = vec3(.2 - .1 * rand(chair_seed++), .0, .5 + .2 * (rand(chair_seed++) - .5));
    
    vec3 q5 = rot(q3, cup_center, vec3(.0, rand(chair_seed++),.0));
    
    objects[5] = FAR;
    objects[5] = min(objects[5], cyl(q5, cup_center + vec3(.0, .51 + length(q3.xz - cup_center.xz)* .3, .0), cup_center + vec3(.0, .52  + length(q3.xz - cup_center.xz)* .3, .0), .04));
    objects[5] = min(objects[5], torus(q5, cup_center + vec3(.0, clamp(q3.y, .54, .56), .0), .02 + (q3.y - .54) * .6, .004));
    
    objects[5] = min(objects[5], torus(rot(q5, cup_center + vec3(.0, .55, .04), vec3(.0, .0, .25)), cup_center + vec3(.0, .55, .04), .01, .004));
}

#define TILING .3

void setObjectColors(vec3 q) {

    bool tile = (mod(q.x, 2. * TILING) < TILING) ^^ (mod(q.z, 2. * TILING) < TILING);

    objectsColor[0] = tile ? vec3(.9) : vec3(.4, .0, .0);
    objectsColor[1] = vec3(.8, .3, .1);
    objectsColor[2] = vec3(.9);
    objectsColor[3] = vec3(.8, .3, .1);
    objectsColor[4] = vec3(.3);
}

float map(vec3 q) {
    float d = FAR;
    
    setObjects(q);
    
    for(int i = 0; i < OBJ_COUNT; i++)
        d = min(d, objects[i]);
    
    return d;
}

vec3 mapColor(vec3 q, float t) {
    setObjects(q);
    setObjectColors(q);
    
    vec3 c = vec3(.0);
    float mind = FAR;
    
    for(int i = 0; i < OBJ_COUNT; i++) {
        if(abs(objects[i]) < .001 * (t * .25 + 1.) && abs(objects[i]) < mind){
             c = objectsColor[i];
             mind = abs(objects[i]);
        }
    }

    return c;
}

float mapRef(vec3 q, float t) {
    setObjects(q);
    
    float ref = .0;
    float mind = FAR;
    
    for(int i = 0; i < OBJ_COUNT; i++) {
        if(abs(objects[i]) < .001 * (t * .25 + 1.) && abs(objects[i]) < mind){
             ref = objectsRef[i];
             mind = abs(objects[i]);
        }
    }

    return ref;
}

float rayMarch(vec3 ro, vec3 rd, int max_d) {
    float t = 0., d;
    for(int i = 0; i < max_d; i++){
        d = map(ro + rd * t);
        if(abs(d) < .001 * (t * .25 + 1.) || t > FAR)  break;
        t += d;
    }
    return t;
}

vec3 normal(vec3 p) {
    //Tetrahedral normal
    const vec2 e = vec2(0.0025, -0.0025); 
    return normalize(e.xyy * map(p + e.xyy) + e.yyx * map(p + e.yyx) + e.yxy * map(p + e.yxy) + e.xxx * map(p + e.xxx));
}

float occlusion(vec3 pos, vec3 nor)
{
    float sca = 2.0, occ = 0.0;
    for(int i = 0; i < 10; i++) {
    
        float hr = 0.01 + float(i) * 0.5 / 4.0;        
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= 0.6;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

vec4 getHitColor(vec3 ro, vec3 rd, float t, vec3 lightPos) {
    vec3 hit = ro + rd * t;
    vec3 norm = normal(hit);
    
    vec3 light = lightPos - hit;
    float lightDist = max(length(light), .001);
    float atten = 1. / (1.0 + lightDist * 0.125 + lightDist * lightDist * .05);
    light /= lightDist;
    
    float occ = occlusion(hit, norm);
    
    float dif = clamp(dot(norm, light), 0.0, 1.0);
    dif = pow(dif, 4.) * 2.;
    float spe = pow(max(dot(reflect(-light, norm), -rd), 0.), 8.);
    
    vec3 color = mapColor(hit, t) * (dif + .35  + vec3(.35, .45, .5) * spe) + vec3(.7, .9, 1) * spe * spe;
    
    return vec4(color, atten * occ);
}

vec3 getColor(vec2 uv, vec3 ro, vec3 dir, vec3 lightPos) {
    vec3 fwd = normalize(dir);
    vec3 rgt = normalize(vec3(fwd.z, 0, -fwd.x));
    vec3 up = (cross(fwd, rgt));
    
    vec3 rd = normalize(fwd + FOV*(uv.x*rgt + uv.y*up));
    
    float t = rayMarch(ro, rd, MAX_RAY);
    
    vec3 outColor = vec3(.0);
    
    if(t < FAR) {
        vec3 hit = ro + rd * t;
        vec3 norm = normal(hit);
        vec4 color = getHitColor(ro, rd, t, lightPos);
        
        vec3 ref = reflect(rd, norm);
        float refQ = mapRef(hit, t);
        float t2 = refQ <= .001 ? .0 : rayMarch(hit + ref * .1, ref, MAX_REF);
        vec4 color2 = refQ <= .001 ? vec4(.0) : getHitColor(hit + ref * .1, ref, t2, lightPos);
    
        outColor = (color.xyz * (1. - refQ) + refQ * color2.xyz * color2.w) * color.w;
    }
    
    outColor = mix(min(outColor, 1.), vec3(.0), 1. - exp(-t*t/FAR/FAR*10.));
    
    return outColor;
}

#define CAMERA_SPEED .5

void main(void) {
    vec2 uv = (gl_FragCoord.xy / resolution.xy - 0.5);
    uv.x *= resolution.x / resolution.y;
    
    vec3 pos = vec3(1. + 3. * cos(time * CAMERA_SPEED), 1. + sin(time * CAMERA_SPEED) * .2, 3. * sin(time * CAMERA_SPEED));
    vec3 dir = vec3(3. * cos(time * CAMERA_SPEED + PI), -1.5, 3. * sin(time * CAMERA_SPEED + PI));
    vec3 light = vec3(.0, 4., .0);
    
    vec3 c = getColor(uv, pos, dir, light);
    
    glFragColor = vec4(sqrt(c),1.0);
}
