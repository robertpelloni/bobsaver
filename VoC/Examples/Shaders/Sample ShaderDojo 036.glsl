#version 420

// original https://www.shadertoy.com/view/3tBXWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

#define RID(p, r) (floor((p + r/2.) / r))
#define REP(p, r) (mod(p + r/2., r) - r /2.)

//from https://www.shadertoy.com/view/XlfGzr
float random(float p) {
      return fract(sin(p)*1e5);
}

float hash21(vec2 p) {
      return random(p.x + p.y*1e5);
}

// hash and noise from shane's : https://www.shadertoy.com/view/ldscWH
vec3 hash33(vec3 p) { 

    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768)*n)*2. - 1.;
}

float tetraNoise(in vec3 p)
{
    vec3 i = floor(p + dot(p, vec3(0.333333)) );  p -= i - dot(i, vec3(0.166666)) ;
    
    vec3 i1 = step(p.yzx, p), i2 = max(i1, 1.0-i1.zxy); i1 = min(i1, 1.0-i1.zxy);    
    
    vec3 p1 = p - i1 + 0.166666, p2 = p - i2 + 0.333333, p3 = p - 0.5;
  
    vec4 v = max(0.5 - vec4(dot(p,p), dot(p1,p1), dot(p2,p2), dot(p3,p3)), 0.0);
    vec4 d = vec4(dot(p, hash33(i)), dot(p1, hash33(i + i1)), dot(p2, hash33(i + i2)), dot(p3, hash33(i + 1.)));
    
    return clamp(dot(d, v*v*v*8.)*1.732 + .5, 0., 1.); 
}

// from iq
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

mat2 rot(float a)
{
    float ca = cos(a); float sa = sin(a);
    return mat2(ca,-sa,sa,ca);
}

float overCurve(float t)
{
    return sin(t * PI * .5);
}

float underCurve(float t)
{
    return 1. - cos(t * PI * .5);
}

float map(vec3 p)
{
    vec3 cp = p;
    //p.xz *= rot(time * .25);
    
    float volNoise = tetraNoise(p * .1125 - vec3(0.,0.,-time * 2.5));
    volNoise = overCurve(volNoise);
    volNoise = volNoise * volNoise  * 4.;
    float dist =3.95 - volNoise;
    
    float repSize = 10.;
    vec2 rid = RID(p.xy, repSize);
    p.xy = REP(p.xy, repSize);
    
    float cellNoise = hash21(rid);
    
    float cylRadius = overCurve(sin(time * 2. + p.z * .1 + cellNoise * 10.) * .5 + .5) * 3.;
    float cyl = cylRadius - length(p.xy + vec2(cellNoise * 2.));
    cyl = clamp(cyl,0.,1.);
    dist *= cyl;
    p = cp;
    dist *= clamp(length(p.xy) - repSize*.5,0.,1.);
    //p = abs(p);
    //float cu = max(p.x, max(p.y, p.z));
    //    dist = min(dist, 3. - cu);
    
    return dist;
}

float volRay(in vec3 ro, in vec3 rd, float maxDist)
{
    float nbSample = 60.;
    float acc = 0.;
    
    for(float i = 1.; i > 0.; i -= 1. / nbSample)
    {
        vec3 p = ro + rd * maxDist * i;
        acc += max(0., map(p)) / nbSample;
        if(acc >= 1.)
        {
          //  break;
        }
    }
    
    return clamp(acc, 0. ,1.);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5)/resolution.y;

    vec3 ro = vec3(0.,0.,-10.);
    vec3 cp = ro;
    vec3 rd = normalize(vec3(uv, 1.));
    
    float vol = volRay(ro, rd, 100.);
    vol *= 2.;
    vol *= vol;
    vec3 noColor = vec3(0.,0.,0.);
    vec3 fullColor = vec3(.6,.4,.37) * 2.;
    
    vec3 col = mix(noColor, fullColor, vol);

    // Output to screen
    glFragColor = vec4(col, 0.);
}
