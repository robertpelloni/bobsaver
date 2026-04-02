#version 420

// original https://www.shadertoy.com/view/3t2XRm

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
    //p.xy *= genRot(PI / 12.);
        p.xy += 5.;
    p.xy = fract(p.xy / 10.) * 10.;
    p.xy -= 5.;
    
    p = pmod(p,12.);
    p.y -= .0;
    p.xy *= genRot(-PI / 12.);
    p.z += 2.;
    p.z = fract(p.z / 4.) * 4.;
    p.z -= 2.;
    
    float theta = 0.;
    float a = 0.2;
    float begin = sin(time * 2. * (0.2 + rand(0.)) + 0.) * a;
    float prev = 0.;
    float curr = 0.;
    float r = 1.5 + 0.2 * cos(time);
    
    float res = sphere(p,vec3(0.,0.,begin),0.15);
    for(int i = 1; i < 5; i++){
        res = min(res,
                 line(p,
                     vec3(prev,
                          0.,
                          sin(time * 2. * (0.2 + rand(prev)) + prev) * a),
                      vec3(float(i),
                          0.,
                          sin(time * 2. * (0.2 + rand(float(i))) + float(i)) * a),
                      0.025
                     ));
        res = min(res,sphere(p,vec3(float(i),
                              0.,
                              sin(time * 2. * (0.2 + rand(float(i))) + float(i)) * a)
                             ,0.15));
        prev = float(i);
    }
    return res;
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
    return vec3(-2.0 * sin(-time* PI / 8.),-2.0 * cos(-time* PI / 8.),-5. + time*0.75 );
}

//Setting Ray
vec3 Ray(vec2 uv, float z){
    vec3 ray = normalize(vec3(uv,z));
    ray.yz *= genRot(-PI/8.);
    ray.xz *= genRot(-PI/8.);
    ray.xy *= genRot(time * PI / 8.);
    return ray;
}

//Tracing Ray

vec4 trace (vec3 o, vec3 r){
    float t = 0.0;
    vec3 p = vec3(0.0,0.0,0.0);
    
    for(int i = 0; i < 128; ++i){
        p = o + r * t;
        float d = map(p);
        t += d * 0.75;
    }
    return vec4(getNormal(p),t);
}

//Making color
vec3 getColor(vec3 r,vec4 data){
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.025);
    float a = dot(data.xyz,r);
    vec3 fc = mix(vec3(0.95),vec3(1. + a),fog);
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
    vec3 fc = getColor(r,data) ;
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
