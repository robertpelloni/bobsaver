#version 420

// original https://www.shadertoy.com/view/tlXfz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//global variables

#define fractal_iterations 7
#define fractal_elongate 0.21
#define volume_iterations 7
#define volume_step 0.004
#define density 0.75
#define max_distance 5.
#define grad_step 0.0001
#define stop_threshold 0.002
#define maxiterations 100

#define scale 2.75
#define offset 0.22

const vec3 nn1 = normalize(vec3(-0.2,.5,1.));

mat3 objRot = mat3(1.);
mat3 frcRot = mat3(1.);

//-----------------------------------------------------------------------------
// Maths utils
//-----------------------------------------------------------------------------
// Taken from https://www.shadertoy.com/view/4ts3z2
float tri(in float x){return abs(fract(x)-.5);}
vec3 tri3(in vec3 p){return vec3( tri(p.z+tri(p.y*1.)), tri(p.z+tri(p.x*1.)), tri(p.y+tri(p.x*1.)));}
                                 
mat2 m2 = mat2(0.970,  0.242, -0.242,  0.970);

float triNoise3d(in vec3 p)
{
    float z=1.4;
    float rz = 0.;
    vec3 bp = p;
    for (float i=0.; i<=3.; i++ )
    {
        vec3 dg = tri3(bp*2.);
        p += (dg);

        bp *= 1.8;
        z *= 1.5;
        p *= 1.2;
        //p.xz*= m2;
        
        rz+= (tri(p.z+tri(p.x+tri(p.y))))/z;
        bp += 0.14;
    }
    return rz;
}

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float snoise(vec3 p) {
     /* 1. find current tetrahedron T and it's four vertices */
     /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
     /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
     
     /* calculate s and x */
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     
     /* calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);
         
     /* x1, x2, x3 */
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;
     
     /* 2. find four surflets and store them in d */
     vec4 w, d;
     
     /* calculate surflet weights */
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);
     
     /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
     w = max(0.6 - w, 0.0);
     
     /* calculate surflet components */
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);
     
     /* multiply d by w^4 */
     w *= w;
     w *= w;
     d *= w;
     
     /* 3. return the sum of the four surflets */
     return dot(d, vec4(52.0));
}

vec4 colornoise(vec3 p, float rgboff, float simple){
    vec4 color = vec4(0.);
    vec3 pos = p+vec3(0.,0.,rgboff);
    color.r = triNoise3d(pos*0.25)*simple+snoise(pos);
    pos = p+vec3(0.,0.,-rgboff);
    color.g = triNoise3d(pos*0.25)*simple+snoise(pos);
    pos = p+vec3(0.,rgboff,0.);
    color.b = triNoise3d(pos*0.25)*simple+snoise(pos);
    pos = p+vec3(2.,0.,-rgboff);
    color.a = triNoise3d(pos*0.25)*simple+snoise(pos);
    return color;
}

//Rotation matrix from euler (X/Y/Z) angles. http://glslsandbox.com/e#48064.5
mat3 rot3Dmat(vec3 angles)
{
    vec3 c = cos(angles);
    vec3 s = sin(angles);
    
    mat3 rotX = mat3( 1.0, 0.0, 0.0, 0.0,c.x,s.x, 0.0,-s.x, c.x);
    mat3 rotY = mat3( c.y, 0.0,-s.y, 0.0,1.0,0.0, s.y, 0.0, c.y);
    mat3 rotZ = mat3( c.z, s.z, 0.0,-s.z,c.z,0.0, 0.0, 0.0, 1.0);
    
    return rotX * rotY * rotZ;
}

//-----------------------------------------------------------------------------
//Vectors
//-----------------------------------------------------------------------------

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

//iq distance functions

float sdfSphere(vec3 z, vec3 pos, float s){
    vec3 p = z-pos;
    return length(p)-s;
}

float sdfOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

float sdfNoise( vec3 p, float s)
{
  float v = triNoise3d(p*0.35)*0.5+snoise(p*1.3)*0.8;
  return v*s;
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); 
}           

vec2 map(vec3 z){
    float upscale = 1.;
    vec3 rotated = (z*objRot)/upscale;
    float d0a = sdfOctahedron(rotated-vec3(0.,0.,0.),1.25);
    float d0b = sdfSphere(rotated,vec3(0.2,-0.4,0.),0.5);
    float d1 = sdfNoise(rotated+vec3(time*0.1,0.,0.),0.7);
    d1 = opSmoothUnion(d1,d0b,0.5);
    d1 = opSmoothIntersection(d1,d0a, 0.0001);
    return vec2(d1/upscale,1.);
}

vec3 calcNormal(vec3 pos ){   
    vec3 eps = vec3( grad_step, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
}

vec2 calcIntersection( in vec3 ro, in vec3 rd ){    
    float result = -1.0;
    float id = -1.;
    float dist = stop_threshold*2.0;

    for (int i = 0; i < maxiterations; i++) {
        vec3 p = ro+rd*dist;
        vec2 res = map(p);
        if (res.x <= stop_threshold) break;
        dist += res.x;
        id = res.y; 
        if (dist >= max_distance) break;
    }

    result = dist;
    id = mix(id,-1.0,float(dist>max_distance));
    
    return vec2(result,id);   
}

//diffuse lighting calc
vec3 calcLight(vec3 p, vec3 eye2, vec3 N, 
                            vec3 lightPos, vec3 lightIntensity) {
    vec3 L = normalize(lightPos);
    vec3 V = normalize(eye2 - p);
    vec3 R = normalize(reflect(-L, N));
    
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    
    if (dotLN < 0.0) {
        return vec3(0.0, 0.0, 0.0);
    } 
    
    if (dotRV < 0.0) {
        return lightIntensity * (dotLN);
    }
    return lightIntensity * (dotLN);
}

// procedural volume
// maps position to color
// based on https://www.shadertoy.com/view/ttSczc
vec4 volumeFunc(vec3 p)
{
    return colornoise(p*objRot*2.+vec3(time*0.3,0.,0.),1.5, 0.8);
}

vec4 volumeMarch(vec3 rayOrigin, vec3 rayDir, vec3 lightDir)
{
    vec4 sum = vec4(0, 0, 0, 0);
    vec3 pos = rayOrigin;
    vec3 ref = rayDir;
    float dist = 0.005;
    for(int i=0; i<volume_iterations; i++) {
        vec3 p = pos + ref * dist;
        dist += volume_step;
        vec4 vol = volumeFunc(p);
        //using volume sample diff to get lighting
        //based on https://www.shadertoy.com/view/XslGRr
        float dif = clamp((vol.a + volumeFunc(p-0.01*lightDir).a)/.7, 0.0, 1.0 );
        sum.rgb += vol.rgb*vol.a*density*(dif*0.85);
        sum.a += vol.a*density;
        ref = refract(rayDir, vol.xyz, 1./1.2);
    }
    return abs(sum);
}

#define light_dir vec3(1.,-1.,0.95)
vec3 render(vec2 res, vec3 ro, vec3 rd) {
    vec3 color = vec3(0.65,0.85,0.95)*0.25;
    if( res.y > -0.5 ) {
        vec3 p = ro +rd * res.x;
        vec3 norm = calcNormal(p);
        
        color += calcLight(p, ro, norm, 
                            light_dir, vec3(0.8,.2,0.2)*1.95); 
        
        vec4 vol = volumeMarch(p, refract(rd,norm,1./1.95), light_dir);
        vol.rgb = mix(vec3(dot(vol.rgb,vec3(0.333))),vol.rgb,0.15);
        vol.a = pow(vol.a,1.1);
        vol = clamp(vol,0.,1.);
        color = mix(color,vol.rgb,vol.a);
    }
    return color;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 p = (-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;
    vec3 ro = vec3(0.,0.,2.);
    vec3 ta = vec3(0.);
    
    //initialize globals
    objRot = rot3Dmat(vec3(0.25,0.25,0.));
    //frcRot = rot3Dmat(vec3(sin(time*0.23)*2.5,0.,time*0.3));

    mat3 camMat = calcLookAtMatrix(ro, ta, 0.);
    vec3 rd = normalize(camMat * vec3(p.xy,2.0) );
    vec2 res = calcIntersection(ro, rd);
    vec3 color = render(res,ro,rd);

    // Output to screen
    glFragColor = mix(vec4(0.25,0.5,0.45,1.),vec4(color, 1.0),float(res.y>-0.5));
}
