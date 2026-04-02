#version 420

// original https://www.shadertoy.com/view/3tjXzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265;
//use for differential
const float EPS = 0.001;

//common function
mat2 genRot(float val){
    return mat2(cos(val), -sin(val),
               sin(val), cos(val));
}

float rand (float x){
    x = fract(sin(x*416.31434));
    x = fract(sin(x*234.41523));
    x = fract(sin(x*235.51424));
    return x;
}

float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

vec3 pmod(vec3 p,float c){
    float tmp = PI * 2. / c;
    float l = length(p.xy);
    float theta = atan(p.y/p.x);
    theta = mod(theta,PI * 2. / c);
    return vec3(l * cos(theta), l * sin(theta),p.z);
    
}

//Common SDF

float sphere(vec3 p,vec3 o,float r){
    return length(p - o) - r;
}

float cylinder(vec2 p,vec2 o,float r){
    return length(p - o) - r;
}

float cube(vec3 p,vec3 o,vec3 s){
    float x = abs(p.x - o.x) - s.x/2.;
    float y = abs(p.y - o.y) - s.y/2.;
    float z = abs(p.z - o.z) - s.z/2.;
    return max(x,max(y,z));
}

float line(vec3 p,vec3 q1,vec3 q2,float r){
    float t = clamp(
        dot(q2 - p,q2 -q1)/dot(q2-q1,q2-q1),
        0.,
        1.
    );
    vec3 q = t * q1 + (1. - t) * q2;
    return length(q - p) - r;
}

//Gathering SDF

float map(vec3 p){
    float h = -10. + cos(p.x/2.) * 0.5 + cos(p.z/2.) * 0.5;
    h += sin(p.x /8.) * 3.;
    h -= sin(p.z /8.) * 3.;
    vec3 r = p;
    p.y = -abs(-p.y - (sin(p.x) + sin(p.z) + sin(time)) * 0.2)
        + (sin(p.x) + sin(p.z) + sin(time)) * 0.2;
    float ground = p.y - h;
    vec3 q = p;
    q.xz = fract((q.xz + 5.) /10.) * 10. - 5.;
    r.xz = fract((r.xz + 8.) /16.) * 16. - 8.;
    r.xz += vec2(3.);
    float towerA = length(r.xz) - (1.25 + 0.25 + sin(r.y));
    float towerB = length(q.xz - 2.5) - 1. / (0.9 + max(p.y - h,0.0));
    float terrain = min(ground,min(towerA,towerB));
    float path = max(abs(p.x) - 0.75,-p.y - 0.5);
    return max(terrain,-path);
}

//Getting Normal

vec3 getNormal(vec3 p) {
    return normalize(vec3(
        map(p + vec3(EPS, 0.0, 0.0)) - map(p + vec3(-EPS,  0.0,  0.0)),
        map(p + vec3(0.0, EPS, 0.0)) - map(p + vec3( 0.0, -EPS,  0.0)),
        map(p + vec3(0.0, 0.0, EPS)) - map(p + vec3( 0.0,  0.0, -EPS))
    ));
}

//Setting CameraPos
vec3 Camera(float t){
    return vec3(0.,0.,-2.0 + time * 2.0);
}

//Setting Ray
vec3 Ray(vec2 uv, float z){
    vec3 ray = normalize(vec3(uv,z));
    return ray;
}

//Tracing Ray

vec4 trace (vec3 o, vec3 r){
    float t = 0.0;
    vec3 p = vec3(0.0,0.0,0.0);
    
    for(int i = 0; i < 256; ++i){
        p = o + r * t;
        float d = map(p);
        t += d * 0.25;
    }
    return vec4(getNormal(p),t);
}

//Making color
vec3 getColor(vec3 o,vec3 r,vec4 data){
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.005);
    float a = dot(data.xyz,r);
    vec3 p = o + r * t;
    vec3 fc = min(fract(p.x),fract(p.z))<0.03 ? vec3(0.95) : vec3(0.05);
    fc = mix(fc,vec3(1.),1. + a*1.5);
    fc = mix(vec3(0.95),fc,fog);
    fc = t < 1000. ? fc : vec3(0.95);
    //fc = vec3(fog);
    return fc;
}

//Drawing

void main(void)
{
    //set canvas
    vec2 uv = gl_FragCoord.xy /resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    //set camera and ray
    vec3 r = Ray(uv,1.2);
    vec3 o = Camera(time);
    
    //trace ray
    vec4 data = trace(o,r);
    vec3 fc = getColor(o,r,data) ;
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
