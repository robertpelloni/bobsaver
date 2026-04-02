#version 420

// original https://www.shadertoy.com/view/WljSDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265;
//use for differential
const float EPS = 0.001;

struct traceData{
    vec3 normal;
    float t;
    float nearestt;
    float nearestd;
    int objectId;
};
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
float cubeSize = 1.5;
float fractSize = 4.;
float map(vec3 p){
    p = (fract(p / fractSize + 0.5)-0.5) * fractSize;
    float biggerC = cube(p,vec3(0.),vec3(cubeSize));
    float smallerBelt = max(0.1 - abs(p.x),
                            max(0.1 - abs(p.y),
                               0.1 - abs(p.z)));
    float smallerCube = cube(p,vec3(0.),vec3(cubeSize - 0.3));
    float result = max(biggerC,smallerBelt);
    result = min(result,smallerCube);
    return result;
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
    vec3 c =vec3(0.,0.,-2.0);
    c += vec3(1.5,1.5,time * 2.);
    return c;
}

//Setting Ray
vec3 Ray(vec2 uv, float z){
    vec3 ray = normalize(vec3(uv,z));
    ray.xy *= genRot(time/4.);
    ray.xz *= genRot(time/4.);
    return ray;
}

//Tracing Ray

traceData trace (vec3 o, vec3 r){
    traceData result;
    float t = 0.0;
    float nearestd = 100000000.0;
    float nearestt = 1000000.0;
    vec3 p = vec3(0.0,0.0,0.0);
    
    for(int i = 0; i < 256; ++i){
        p = o + r * t;
        float d = map(p);
        nearestt = d < nearestd ? t + d * 0.15 : nearestt;
        nearestd = min(nearestd,d);
        t += d * 0.15;
    }
    result.normal = getNormal(p);
    result.nearestd = nearestd;
    result.nearestt = nearestt;
    result.t = t;
    return result;
}

//Making color
vec3 getColor(vec3 o,vec3 r,traceData data){
    float t = data.t;
    float Nt = data.nearestt;
    float Nd = data.nearestd;
    bool isLight = Nd < 1. 
        && abs(Nt - t) > 0.001
        ;
    float fog = 1.0 / (1.0 + t * t * 0.025);
    float a = dot(data.normal,r);
    vec3 p = o + r * t;
    vec3 Np = o + r * Nt;
    vec3 q = (fract(p / fractSize + 0.5)-0.5) * fractSize;
    float at = atan(r.y/r.x)/PI + 0.5;
    vec3 ccol = vec3(sin(at * PI + time), 1. - sin(at * PI + time),sin(p.z -time) + 0.1);
    vec3 Nccol = vec3(sin(at * PI + time), 1. - sin(at * PI + time),sin(Np.z -time) + 0.1);
    vec3 fc = vec3(0.05);
    
    fc = mix(fc,vec3(1.),1. + a*1.5);
        Nccol = mix(Nccol,vec3(0.0) ,smoothstep(-0.25,0.75,sin(Np.z * 0.05 * PI + time * 2.)));
        fc += isLight ? Nccol/(Nd * Nd) : vec3(0.);
    fc = mix(vec3(0.05),fc,fog);
    ccol = mix(ccol,vec3(0.0) ,smoothstep(-0.25,0.75,sin(p.z * 0.05 * PI + time * 2.)));

    
    fc += max(abs(q.x),max(abs(q.y),abs(q.z))) < cubeSize/2. - 0.1
        ? ccol * 1.5 : vec3(0.);
    
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
    traceData data = trace(o,r);
    vec3 fc = getColor(o,r,data) ;
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
