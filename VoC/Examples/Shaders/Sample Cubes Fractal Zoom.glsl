#version 420

// original https://www.shadertoy.com/view/7s2XWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// by @etiennejcb
// code can be messy and stupid, not optimized

// Thanks tdhooper, iq, leon, FabriceNeyret2 and others

// most important parameters
#define motionBlur 1.0 // (integer)
#define duration 2.0
#define AA false

// others
#define nbIterations 6.0
#define ratio 4.0

#define PI 3.14159
#define TAU (2.*PI)

float time2;

float repeat (float v, float c) { return mod(v,c)-c/2.; }
vec2 repeat (vec2 v, vec2 c) { return mod(v,c)-c/2.; }
vec3 repeat (vec3 v, float c) { return mod(v,c)-c/2.; }

// details about sdf volumes
struct Volume
{
    float dist;
    int mat;
    int surfaceType;
    float iteration;
    vec3 face;
    vec2 facePos;
};

// union operation between two volume
Volume select(Volume a, Volume b)
{
    if (a.dist < b.dist) return a;
    return b;
}

// materials
const int mat_bright = 1;
const int mat_dark = 2;

// Rotation 2D matrix
mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c,-s,s,c); }

// Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Inigo Quilez
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// 3d simplex noise from https://www.shadertoy.com/view/XsX3zB

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

// volumes description
Volume map(vec3 pos)
{
    float L = 0.01;
    float scene = 100.;

    Volume white;
    white.mat = 1;
    // (unused)
    
    Volume black;
    black.mat = 2;
    
    white.dist = 100.0;
    
    
    
    for(float it=0.0;it<nbIterations;it+=1.0)
    {
        vec3 p = pos;
        
        float rit = (it+time2)*TAU*0.125;

        p.yz *= rot(TAU*0.08);
        p.xz *= rot(rit);
        p.y += -2.4+0.8325*L*pow(ratio,it+time2);
        
        float curL = L/2.0*pow(ratio,it+time2);
        
        //float boxDist = max(sdBox(p,vec3(curL)),-sdBox(p,vec3(curL)));
        float boxDist = sdBox(p,vec3(curL));
        
        if(boxDist<scene)
        {
            scene = boxDist;
            black.dist = scene;
            black.iteration = it+time2;
            
            float eps = 0.;
            
            float nbSquares = 6.0;
            
            float borderFactor = 0.96;
            
            float indX = floor(nbSquares*p.x/curL/2.0*borderFactor);
            float indY = floor(nbSquares*p.y/curL/2.0*borderFactor);
            float indZ = floor(nbSquares*p.z/curL/2.0*borderFactor);
            
            if(abs(p.x)<=curL+eps&&abs(p.y)<=curL+eps)
            {
                black.surfaceType = int(mod(indX+indY,2.0));
                black.face = vec3(0.,0.,p.z>0.?1.:-1.);
                black.facePos = p.xy/curL;
            }
            else if(abs(p.y)<=curL+eps&&abs(p.z)<=curL+eps)
            {
                black.surfaceType = int(mod(indY+indZ,2.0));
                black.face = vec3(p.x>0.?1.:-1.,0.,0.);
                black.facePos = p.yz/curL;
            }
            else
            {
                black.surfaceType = int(mod(indX+indZ,2.0));
                black.face = vec3(0.,p.y>0.?1.:-1.,0.);
                black.facePos = p.xz/curL;
            }
        }
    }
    
    
    
    Volume volume = select(white,black);

    return volume;
}

// NuSan
// https://www.shadertoy.com/view/3sBGzV
vec3 getNormal(vec3 p) {
    vec2 off=vec2(0.001,0);
    return normalize(map(p).dist-vec3(map(p-off.xyy).dist, map(p-off.yxy).dist, map(p-off.yyx).dist));
}

float activation(Volume volume,float pw)
{
    float eps = 0.1;
    float len0 = max(abs(volume.facePos.x),abs(volume.facePos.y));
    if(len0>1.0+eps) return 0.0;
    float len = abs(volume.facePos.x) + abs(volume.facePos.y);
    return 1.0*pow((0.5+0.5*sin(TAU*(1.7*volume.iteration + 0.*3.*atan(volume.facePos.y,volume.facePos.x)/TAU- 1.6*len))),pw);    
}

vec3 finishColor(float travel, float shade, float glow, Volume volume, vec3 normal, vec3 col)
{
    vec3 seed2 = volume.face*100.0;
    
    float act = 0.15+activation(volume,40.0);
    
    float scl = 12.0;
    
    col = vec3(0.);
    
    if(volume.surfaceType==1) col += vec3(0.8);
    else
    {
        for(int i=0;i<4;i++){
            float val = simplex3d(vec3(123.456*float(i)+seed2.x+scl*volume.facePos.x,seed2.y+scl*volume.facePos.y,seed2.z+0.7*(volume.iteration)));
            val = smoothstep(0.57,0.7,val);
            col += val*vec3(1.0);
        }

        col += smoothstep(0.95,0.98,act)*vec3(1.0);
    }
    
    /*
    vec2 f = volume.facePos;
    float distBorder = min(abs(abs(f.x)-1.0),abs(abs(f.y)-1.0));
    float borderLight = smoothstep(0.009,0.003,distBorder);
    col += vec3(borderLight);
    */
    
    //col *= pow(dot(vec3(-1.0,1.0,1.0),normal)*0.3+0.5,0.3);
    //col *= 1.0-smoothstep(nbIterations-2.0,nbIterations,volume.iteration);
    col *= smoothstep(0.,1.0,volume.iteration);
    //col += vec3(0.5,0.8,1.2)*shade;
    col += vec3(1.0)*pow(1.13*glow,1.8);
    return clamp(col,0.,1.);
}

void main(void) //WARNING - variables void 0( out vec4 color, in vec2 coordinate ) need changing to glFragColor and gl_FragCoord.xy
{
    vec4 color = glFragColor;
    vec2 coordinate = gl_FragCoord.xy;

    color = vec4(0);
    // coordinates
    vec2 uv = coordinate / resolution.xy;
    vec2 p = 2.*(coordinate - 0.5 * resolution.xy)/resolution.y;
    
    // camera
    vec3 cameraPos = vec3(0,0,-5);
    
    // look at
    vec3 z = normalize(vec3(0,0,0)-cameraPos);
    vec3 x = normalize(cross(z, vec3(0,1,0)));
    vec3 y = normalize(cross(x, z));
    vec3 ray = normalize(z * 1.5 + x * p.x + y * p.y);
    
    float mb = motionBlur;
    
    for(float it=0.0;it<mb;it++){
    
        time2 = mod(time,duration)/duration - it*0.017/mb;
    
        // render variables
        float shade = 0.0;
        vec3 normal = vec3(0,1,0);
        float ao = 1.0;
        float rng = hash12(coordinate + time2);
        const int count = 40;
        float travel = 0.0;
        float glow = 0.0;
        vec3 col;
        
        vec3 pos = cameraPos;
        
        int index;
        
        Volume volume;

        // raymarch iteration
        for (index = 0; index < count; ++index)
        {
            volume = map(pos);

            // accumulate fullness
            shade += 0.5/float(60);

            // step further on edge of volume
            normal = getNormal(pos);
            
            if(volume.dist>0.001){
                volume.dist *= 0.9+0.1*rng;

                // keep marching
                pos += ray * volume.dist;
                travel += volume.dist;
                
                if(volume.dist<0.65)
                {
                    float nf = 0.6+2.0*pow(abs(dot(normal,ray)),1.7);

                    glow += (0.027+0.07*activation(volume,4.0))*nf;
                    
                    if(volume.surfaceType==1) glow += 0.03;
                }
            }
            else
            {

                // coloring
                col = vec3(0);
                switch (volume.mat)
                {
                    case mat_bright:
                    col = vec3(1.3);
                    break;

                    case mat_dark:
                    col = vec3(0.25);
                    
                    
                    break;
                }

                break;

            }
        }
        
        if(index==count)
        {
            col = vec3(0.0);
        }
        color.rgb += finishColor(travel, shade, glow, volume, normal, col);
    }
    
    color.rgb /= mb;

    glFragColor = color;
}
