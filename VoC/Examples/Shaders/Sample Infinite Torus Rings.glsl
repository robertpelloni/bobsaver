#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 50
#define MIN_DIST 0.0
#define MAX_DIST 100.0
#define EPSILON 0.0001

//oscillator
float osc(float _min, float _max, float _freq) {
    float wave = (1.0 + sin(time/_freq)) / 2.0;
    wave *= _max;
    wave += _min;
    return wave;
}

//SDF 3D Shape
float SDF( vec3 p, vec3 t )
{
  vec2 q = vec2(length(p.xy)-t.x * 2.5,p.z);
  return length(q)-t.z / 5.0;
}

//repeat SDF Shape
float opRep( in vec3 p, in vec3 c , float s )
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return SDF(q,vec3(s));
}

float getDist(vec3 p) {
    return opRep(p,vec3(1.0),osc(0.035, 0.215, 5.0));
}

// get shortest distance to surface
// eye = ray origin or ro
float rayMarch(vec3 eye, vec3 marchingDirection) {
    float depth = MIN_DIST;
    
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = eye + marchingDirection * depth;
        float dist = getDist(p);
        depth += dist;
        if(depth > MAX_DIST || dist < EPSILON) break;
    }
    
    return depth;
}

// calculate normals
vec3 getNormal(vec3 p) {
    float dist = getDist(p);
    vec2 e = vec2(EPSILON, 0);
    
    vec3 normal = dist - vec3(
        getDist(p-e.xyy),
        getDist(p-e.yxy),
        getDist(p-e.yyx));
    
    return normalize(normal);
}

float getLight(vec3 p){
    vec3 lightPos = vec3(0,1,time) ;
    //lightPos.xz += vec2(2.*sin(time),2.*cos(time));
    vec3 lv = normalize(lightPos - p ); 
    vec3 n = getNormal(p) ;
    float dif = clamp(dot(n,lv),0.,1.)*5. ;
    float d = rayMarch(p+n*EPSILON*2.,lv) ;
    //if(d<length(lightPos-p)) dif *=.1 ;
    return dif ;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float speed = 0.05 ;
    
    // movement matrix
    mat2 mat = mat2(vec2(cos(time*speed), sin(time*speed)),         // first column (not row!)    
                     vec2(-sin(time*speed), cos(time*speed)));
    uv = mat*uv ;
    
    vec3 eye = vec3(0,0.5,time);
    vec3 marchingDirection = normalize(vec3(uv.x,uv.y,1));
    float d = rayMarch(eye,marchingDirection);
 
    float dif = 1.0/(1.0+d*d*0.1);
    float difR = dif*2.0;
    float difG = dif/d*2.0;
    float difB = (difR + difG) / 2.0;
    
    vec3 col = vec3(difR, difG, difB);

    glFragColor = vec4(col,1.0);
}
