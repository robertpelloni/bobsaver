#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NsfSz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NUM_OCTAVES 2

//uncomment below for original recipe perlin noise
//#define OLD_PERLIN

//not perfect, but the best looking hash function that I found after
//trying out a couple. No jarring discontinuities as UVs scroll and less
//repetitive than others I tried. Taken from https://www.shadertoy.com/view/4djSRW
float hash31(vec3 p3)
{
    p3  = fract(p3 * vec3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//the "fade" function defines the value used to blend values
//from each corner of the unit cube
//The "Improving Noise" paper updates
//this from 3t^2-2t^3 to 6t^5-15t^4+10t^3
float fade(float t)
{
#ifdef OLD_PERLIN
    return t * t * (3.0-2.0*t);
#else
    return  t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
#endif
}

//original perlin noise calculates gradient functions randomly, whereas "improved" perlin
//selects randomly from a fixed array of vectors.
vec3 grad(vec3 p)
{
#ifdef OLD_PERLIN
    return -1.0 + 2.0 *vec3(hash31(p.xyz), hash31(p.yxy), hash31(p.zyx));
#else
    float r = hash31(p)*16.0;
    int ri = int(r);
    
    vec3 grads[16];

    grads[0] = vec3(1.0, 1.0, 0.0);
    grads[1] = vec3(-1.0, 1.0, 0.0);
    grads[2] = vec3(1.0, -1.0, 0.0);
    grads[3] = vec3(-1.0, -1.0, 0.0);
    
    grads[4] = vec3(1.0, 0.0, 1.0);
    grads[5] = vec3(-1.0, 0.0, 1.0);
    grads[6] = vec3(1.0, 0.0, -1.0);
    grads[7] = vec3(-1.0, 0.0, 1.0);

    grads[8] = vec3(0.0, 1.0, 1.0);
    grads[9] = vec3(0.0, -1.0, 1.0);
    grads[10] = vec3(0.0, 1.0, -1.0);
    grads[11] = vec3(0.0, -1.0, -1.0);

    //pad array to 16 to avoid the cost of dividing by 12
    grads[12] = vec3(1.0, 1.0, 0.0);
    grads[13] = vec3(-1.0, 1.0, 0.0);
    grads[14] = vec3(0.0, -1.0, 1.0);
    grads[15] = vec3(0.0, -1.0, -1.0);

    return grads[ri%16];
#endif
}

float perlin3d(vec3 p)
{
    //floorP is used to generate the gradient vectors for the 4 corners of the unit cube
    //that surround point p. Since we already need floorP, it's easier to get fractP
    //via subtraction than a fract()
    vec3 floorP = floor(p);
    vec3 fractP = p - floorP;
    
    //calculate distance vectors from the input coordinate to the 4 corners of the unit cube
    //these are used to weight the contributions from each corner's gradient vector
    
    // "near" corners (z == 0)
    vec3 ntopLeft = fractP - vec3(0.0, 1.0, 0.0);
    vec3 ntopRight = fractP - vec3(1.0,1.0, 0.0);
    vec3 nbottomLeft = fractP;
    vec3 nbottomRight = fractP - vec3(1.0,0.0, 0.0);
    
    // "far" corners (z > 0)
    vec3 ftopLeft = fractP - vec3(0.0, 1.0, 1.0);
    vec3 ftopRight = fractP - vec3(1.0,1.0, 1.0);
    vec3 fbottomLeft = fractP - vec3(0.0,0.0,1.0);
    vec3 fbottomRight = fractP - vec3(1.0,0.0, 1.0);

    //determine gradient vectors for each corner of the cube
    //must be uniform for all sample points within the same "tile" of the noise plane.
    //(so (2.4,1.2)'s gradient vectors will be the same as (2.7,1.6)'s)
    vec3 ntopLeftGrad = grad(floorP + vec3(0.0, 1.0, 0.0));
    vec3 ntopRightGrad = grad(floorP + vec3(1.0, 1.0, 0.0));
    vec3 nbottomLeftGrad = grad(floorP);
    vec3 nbottomRightGrad = grad(floorP + vec3(1.0, 0.0, 0.0));
    
    vec3 ftopLeftGrad = grad(floorP + vec3(0.0, 1.0, 1.0));
    vec3 ftopRightGrad = grad(floorP + vec3(1.0, 1.0, 1.0));
    vec3 fbottomLeftGrad = grad(floorP + vec3(0.0, 0.0, 1.0));
    vec3 fbottomRightGrad = grad(floorP + vec3(1.0, 0.0, 1.0));
    
    float ng1 = dot(ntopLeft, ntopLeftGrad);
    float ng2 = dot(ntopRight, ntopRightGrad);
    float ng3 = dot(nbottomLeft, nbottomLeftGrad);
    float ng4 = dot(nbottomRight, nbottomRightGrad);
    
    float fg1 = dot(ftopLeft, ftopLeftGrad);
    float fg2 = dot(ftopRight, ftopRightGrad);
    float fg3 = dot(fbottomLeft, fbottomLeftGrad);
    float fg4 = dot(fbottomRight, fbottomRightGrad);

    //mix 2 bottom influences together, left to right, according to fade(fractP.x)
    //then blend them bottom to top according to fade(fractP.y)
    float nmix = mix( mix(ng3,ng4,fade(fractP.x)), mix(ng1,ng2,fade(fractP.x)), fade(fractP.y) );
    float fmix = mix( mix(fg3,fg4,fade(fractP.x)), mix(fg1,fg2,fade(fractP.x)), fade(fractP.y) );
    return mix(nmix, fmix, fade(fractP.z));
}

float fbm( in vec3 x)
{    
    float H = 1.0;
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for( int i=0; i<NUM_OCTAVES; i++ )
    {
        t += a*perlin3d(f*x);
        f *= 2.0;
        a *= -G/1.5;
    }
    return t;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float map(vec3 at)
{
  return sdSphere(at, 3.0) + fbm(at * 1.25);
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos )
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e);
    }
    return normalize(n);   
}

void main(void)
{
    float mouseX = (-mouse.x*resolution.xy.x / resolution.x) * 10.0;
    
    //xz coords for camera are a circle
    vec3 CAM_OFFSET = 6.0 * (vec3( cos(mouseX), 0.0 , sin(mouseX) ));    
    vec3 CAM_UP = vec3(0.0, 1.0, 0.0);
    vec3 CAM_POS = vec3(0,3,0) + CAM_OFFSET;
    vec3 CAM_LOOKPOINT = vec3(0.0, 0.0, 0.0);
    
    vec3 lookDirection = normalize(CAM_LOOKPOINT - CAM_POS);
    vec3 viewPlaneU = normalize(cross(CAM_UP, lookDirection));
    vec3 viewPlaneV = cross(lookDirection, viewPlaneU);
    vec3 viewCenter = lookDirection + CAM_POS;
    
    //remap uvs to -1 - +1
    vec2 uv = -1.0 + 2.0*gl_FragCoord.xy / resolution.xy;

    vec3 fragWorldPos = viewCenter + (uv.x * viewPlaneU * resolution.x / resolution.y) + (uv.y * viewPlaneV);
    vec3 camPosToFragWorld = normalize(fragWorldPos - CAM_POS);

    const float farClip = 50.0;
    
    vec3 col = mix(vec3(perlin3d(vec3(gl_FragCoord.xy*0.05,time*0.5))) * vec3(0.25), vec3(0.3,0.5,0.95)*vec3(1.0+perlin3d(vec3(gl_FragCoord.xy*0.025,time*0.5))), gl_FragCoord.y/resolution.y);
    
    vec3 light1 = normalize(vec3(1,1,-1));

    vec3 p = CAM_POS;
    for (int i = 0; i < 128; ++i)
    {
        float s=map(p);

        if ( abs(s) < 0.001 )
        {
            vec3 nrm = (calcNormal(p));
            vec3 sphereCol = mix(vec3(0.95,0.25,0.25), vec3(1,1,1), 0.5+perlin3d(p*0.5));
              
            vec3 halfVec = normalize(light1 + camPosToFragWorld);
            float spec = pow(max(dot(nrm, halfVec), 0.0), 32.0);

            col = sphereCol * max(0.0, dot(nrm, light1));
            col += sphereCol * spec;
            col += sphereCol * 0.25;

            break;
        }
       
        if (s > 10.0) break;
        
        //we don't have a true distance function, so we need to 
        //reduce the size of our steps to eliminate holes in the render
        p += camPosToFragWorld*s*0.4;

    }
  
    glFragColor = vec4(col, 1.0);
}
