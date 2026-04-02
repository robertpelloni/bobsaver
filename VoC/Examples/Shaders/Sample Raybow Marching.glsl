#version 420

// original https://www.shadertoy.com/view/WssXDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MXDIST 1000.
#define MXSTEPS 10000
#define ACCURACY 0.001

float sdOctahedron(vec3 p, float s)
{
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.57735027;
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdPlane(float y){
    return y;
}

float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float opUnion( float d1, float d2 ) { return min(d1,d2); }
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }
float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
       return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float opRep( in vec3 p, in vec3 c)
{
    vec3 q = mod(p,c)-0.5*c;
    return opSubtraction(sdSphere(q,1.4045),sdBox(q,vec3(1.)));

}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float testDistance(vec3 p){
    //float result = opSubtraction(sdSphere(p,1.4),sdBox(p,vec3(1.)));
    float result = opRep(p,vec3(2));
    return result;
}

float rayMarch(vec3 p, vec3 d){
    float dist=0.;
    for(int i = 0;i<MXSTEPS;i++){
        vec3 point = p + d*dist;
        float dtest = testDistance(point);
        dist += dtest;
        if(dtest<ACCURACY||dist>MXDIST) break;
    }
    
    return dist;
}

vec3 getNormal(vec3 p){
    float d = testDistance(p);
    vec2 e = vec2(.01,0);
    
    vec3 n = d - vec3(
        testDistance(p-e.xyy),
        testDistance(p-e.yxy),
        testDistance(p-e.yyx));
    return normalize(n);
}

float getLight(vec3 p){
    vec3 lightPos = vec3(1,1,time+1.);
    vec3 l = normalize (lightPos - p);
    vec3 n = getNormal(p);
    float dif = clamp(dot(n,l),0.,1.);
    float d = rayMarch(p+n*ACCURACY*2.,l);
    if(d<length(lightPos-p)) dif *= .2;
    return dif;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 rOrigin = vec3(1,1,time);
    vec3 rDir = normalize(vec3(uv.x,uv.y,1.));
    float d = rayMarch(rOrigin,rDir);
    vec3 colhue = hsv2rgb(vec3(d*.2,1,1));
    vec3 p = rOrigin + rDir*d;
    float dif = getLight(p);
    //d = clamp(d,0.,d);
    d*=.15;
    d=1./(d*d);
    d = clamp(d,0.,1.);
    
    vec3 col = vec3(dif*d*colhue);
    glFragColor = vec4(col,1.0);
}
