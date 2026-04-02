#version 420

// original https://www.shadertoy.com/view/3tcGR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_MARCHING_STEPS 96
#define EPSILON 0.0001
#define TINT vec3(.8, .4, .2)

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

float world(vec3 worldPos){
    //float time = PI;
    {
        vec3 p = worldPos;
        vec3 rp = vec3(-PI, length(p.xy), p.z);
        p = vec3(rp.y * sin(rp.x), rp.y * cos(rp.x), rp.z);
        
        float a = atan(worldPos.x, worldPos.y) * 2.5;
        p.y += 2.;
        p.zy *= mat2(cos(a), -sin(a), sin(a), cos(a));
        
        {
            vec2 mp = p.zy;
            vec2 a = vec2(atan(mp.y, mp.x)+time, length(mp.xy));
            a.x = mod(a.x, PI/16.)-PI/32.;
            p.zy = vec2(a.y * cos(a.x), a.y * sin(a.x));
        }
        
        return max(p.x, length(p.zy - vec2(1., 0.)) - .05);
    }
}

float march(vec3 eye, vec3 marchingDirection){
    const float precis = .001;
    
    float t = 0.0;
    for(int i=0; i<MAX_MARCHING_STEPS; i++){
        float hit = world( eye + marchingDirection * t );
        if( hit < precis ) return t;
        t += hit*.5;
    }
    return -1.;
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        world(vec3(p.x + EPSILON, p.y, p.z)) - world(vec3(p.x - EPSILON, p.y, p.z)),
        world(vec3(p.x, p.y + EPSILON, p.z)) - world(vec3(p.x, p.y - EPSILON, p.z)),
        world(vec3(p.x, p.y, p.z  + EPSILON)) - world(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

vec4 render(){
    vec3 color = vec3(0.);
    float a = 0.0;//mouse.x*resolution.xy.x/resolution.x * PI * 2.;
    a = mix(PI/4., PI * 3./4., a);
    vec3 eye = vec3(2.9, 0., 0.);
    vec3 viewDir = rayDirection(90., resolution.xy);
    vec3 worldDir = viewMatrix(eye, vec3(0.), vec3(0., 0., 1.)) * viewDir;
    
    float hit = march(eye, worldDir);
    if (hit > 0.) {
        vec3 p = (eye + hit * worldDir);
        vec3 norm = estimateNormal(p);
        color = TINT * (abs(dot(worldDir, norm)));
    }
    return vec4(color, 1.);
}

#define AA 1
void main(void) {
    glFragColor = vec4(0.);
    for(int y = 0; y < AA; ++y)
        for(int x = 0; x < AA; ++x){
            glFragColor += clamp(render(), 0., 1.);
        }
    glFragColor.rgb /= float(AA * AA);
}
