#version 420

// original https://www.shadertoy.com/view/fdX3WB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 1000.
#define MIN_HIT 0.01

vec3 rotation(vec3 point, vec3 axis, float angle){ // https://www.shadertoy.com/view/Wtl3zN
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    mat4 rot= mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,0.0,0.0,1.0);
    return (rot*vec4(point,1.)).xyz;
}
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

vec3 opRep( in vec3 p, in vec3 c)
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return q;
}

float getDist(vec3 p) {
    float dist = MAX_DIST; 
    dist = min(dist,  p.y- (-0.5));
    dist = min(dist, sdSphere(p-vec3(0, 0, 5.), 0.5));
    vec3 fractp = p-vec3(5., 1., 0.);
    fractp = rotation(fractp, vec3(1.,0.,0.), time);
    dist = min( dist, sdOctahedron( opRep( fractp, vec3(10.)), 2. ) );
    //dist = min( dist, sdSphere( opRep(p-vec3(5., 1., 0.), vec3(11.)), 1.3) );

    return dist;
}
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.01, 0.);
    float d = getDist(p);
    vec3 n = d-vec3(getDist(p-e.xyy), getDist(p-e.yxy), getDist(p-e.yyx));
    return normalize(n);
}
float rayMarch(vec3 ro, vec3 rd) {

    float rayDist = 0.;
    for(int step = 0; step < MAX_STEPS; step++) {
        vec3 pos = ro + rd*rayDist;
        float distanceHit = getDist(pos);
        rayDist += distanceHit;
        if(distanceHit < MIN_HIT || rayDist > MAX_DIST) break;   
    }
    return rayDist;
}
float getLight(vec3 p, vec3 sun) {
    
    vec3 n = getNormal(p);
    float lighting = dot(n, normalize(sun-p));
    lighting = clamp(lighting, 0., 1.);
    
    float d = rayMarch(p+n*MIN_HIT*1.1, normalize(sun-p));
    if(d < length(sun- p)) {
        lighting = lighting * 0.5;
    }
    return lighting;
}
void main(void)
{
    vec2 uv =  ( gl_FragCoord.xy - .5*resolution.xy ) / resolution.y;
    
    vec3 col = vec3(100., 100., 100);
    
    vec3 rayOrigin = vec3(0.,30.*sin(time)+30.,sin(time)*50.-50.);
    vec3 rayDir = normalize( 
                   rotation( 
                       vec3( uv.x, uv.y, 1.),
                       vec3(0., 1., 0.),
                       0.
                       ) );
    vec3 sun = vec3(0., 20., -20.);
    
    
    float d = rayMarch(rayOrigin, rayDir);
    vec3 p = rayOrigin+rayDir*d;
    float l = getLight(p, sun);
    col = vec3(l);
    
    
    glFragColor = vec4(col,1.);
} 

