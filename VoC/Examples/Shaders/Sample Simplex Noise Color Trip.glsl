#version 420

// original https://www.shadertoy.com/view/3lG3Wz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//by @etiennejcb
//3d simplex noise from https://www.shadertoy.com/view/XsX3zB

const float PI = 3.1415926535897932384626433832795;

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
float simplex3d(vec3 p) {
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

float transformValue(float v){
    v = 0.5 + 0.5*v;
    v = pow(v+0.35,7.0);
    return v;
}

//from bookofshaders
vec3 rgb2hsb( in vec3 c ){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz),
                 vec4(c.gb, K.xy),
                 step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r),
                 vec4(c.r, p.yzx),
                 step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
                d / (q.x + e),
                q.x);
}

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void main(void)
{
    vec2 p = gl_FragCoord.xy/resolution.x;
    float offset = 0.9*simplex3d(vec3(9.*p+vec2(0.,-0.3*time),0.2*time))*clamp((2.0-5.*length(p-vec2(0.5,0.25))),0.,2.) + 10.*length(p-vec2(0.5,0.25));
    //float offset2 = simplex3d(vec3(123)+vec3(10.*p+vec2(-1.*time,0),0.5*time));
    
    float change = 9.0;
    
    float scl = 5.;
    
    float value = simplex3d(vec3(change*(time-offset),scl*p.x,scl*p.y));
    float value2 = simplex3d(vec3(1.1*change*(time-offset),123.+scl*p.x,scl*p.y));
    float value3 = simplex3d(vec3(1.5*change*(time-offset),1234.+scl*p.x,scl*p.y));
    //float value4 = simplex3d(vec3(1.5*change*(time-offset),3234.+scl*p.x,scl*p.y));
    
    value = transformValue(value);
    value2 = transformValue(value2);
    value3 = transformValue(value3);
    
    vec3 color0 = vec3(value+value2,value2+0.*value3,value3+value);
    
    vec3 rgb = clamp(color0,0.,1.);
    
    vec3 hsb = rgb2hsb(rgb);
    
    hsb.x += 0.3*sin(13.*length(p-vec2(0.5,0.25))-1.*time)+0.15*time;
    
    hsb.x = mix(hsb.x,0.5,0.7);
    
    hsb.y += 0.2*sin(14.*length(p-vec2(0.5,0.25))-1.1*time+0.5)-0.4;
                
    rgb = hsb2rgb(hsb);
    
    glFragColor = vec4(rgb,1.0);
    return;
}
