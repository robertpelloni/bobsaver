#version 420

// original https://www.shadertoy.com/view/wlSSDR

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
    vec3 originalP = p;
    p.xy *= genRot(PI / 6.0 + p.z/8.);
    p = pmod(p,6.);
    p.xy *= genRot(-PI / 6.0);
    p.z = fract(p.z + 0.5) -0.5;
    
    float vol = 0.;
    for(float i = 0.0; i < 1.0; i++){
        int tx = int(i*512.0);
            float fft  = 0.0; //texelFetch( iChannel0, ivec2(tx,0), 0 ).x; 
        vol += fft;
    }
    
    float r = 1.25 + 0.15 * sin(originalP.z);
    
    
    float hexB = length(p - vec3(r * 1.73,r,0.)) - 0.25;
    float hexC = length(p - vec3(r * 1.73,-r,0.)) - 0.25;
    p.x = fract((p.x / 3. + 0.5) -0.5) * 3.;
    float hexA = length(p.xz - vec2(r * 1.73,0.)) - 0.05;

    float hex = smin(hexA,smin(hexB,hexC,32.),32.);
    return hex;
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
    vec3 c = vec3(.0,.0,-2.0 + time * 4.);
    return c;
}

//Setting Ray
vec3 Ray(vec2 uv, float z){
    vec3 ray = normalize(vec3(uv,z));
    ray.xy *= genRot(time / 4.);
    ray.xz *= genRot(time / 4.0);
    ray.yz *= genRot(time / 4.0);
    
    return ray;
}

//Tracing Ray

vec4 trace (vec3 o, vec3 r){
    float t = 0.0;
    vec3 p = vec3(0.0,0.0,0.0);
    
    for(int i = 0; i < 128; ++i){
        p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    return vec4(getNormal(p),t);
}

//Making color
vec3 getColor(vec3 o,vec3 r,vec4 data){
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.01);
    float a = dot(data.xyz,r);
    vec3 p = o + r * t;
    float at = atan(r.y/r.x)/PI + 0.5;
    vec3 ccol = vec3(sin(at * PI), 1. - sin(at * PI),sin(p.z) + 0.1);
    vec3 fc = vec3(0.05);
    fc = mix(fc,vec3(1.),1. + a*1.);
    fc += fract(p.z / 4. + time) < 0.75 ?ccol : vec3(0.);
    
    fc = mix(vec3(0.05),fc,fog);
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
