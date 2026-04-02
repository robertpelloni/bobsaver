#version 420

// original https://www.shadertoy.com/view/wtXXzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// update 2021/02/26: added simple animation for param C
//
// thx to https://www.shadertoy.com/user/FabriceNeyret2 for hints and tips
//
// TODO: remove ugly pixel trans, get rid of visual artifacts at y=0
//

#define ANIMATE 1
#define AA 2

// change param C here (if ANIMATE > 0 then C will be taken from circle centered at C_Center)
#if ANIMATE > 0

    #define C_Center vec2(0.)

#else

    #define C vec2(-1.05,0.48)

#endif

// change formula here if you like
#define z_iter(z,c,sgn) ( cmul( csqr(z), sgn*csqrt(z) ) + c )

#define MAX_STEPS 11
#define BAIL      128.
#define SAMPLING  32.

// viewport = vec4(center.x, center.y, size.x, size.y)
#define VIEWPORT vec4(0.,0.,3.,3.)
#define MAGN 1.

// taken from 
// https://www.ronja-tutorials.com/2018/09/02/white-noise.html
// get a scalar random value from given 2d-vector
float rand1from2(vec2 val)
{
    float random = dot(sin(val), vec2(12.9898, 78.233));
    return fract(sin(random) * 143758.5453);
}

#define cs(A) (vec2(cos(A), sin(A)))
#define cmul(A,B) (mat2( A, -(A).y, (A).x ) * (B))
#define csqr(Z) (vec2(Z.x*Z.x-Z.y*Z.y, 2.*Z.x*Z.y))
vec2 csqrt(vec2 z) { float r = length(z); return vec2(sqrt((r+z.x)*.5), sign(z.y)*sqrt((r-z.x)*.5)); }

float iter(vec2 p, float k)
{
    vec2 z = p;
    float sgn = 1.;

    #if ANIMATE > 0
    vec2 c = C_Center+1.1*cs(time);
    #else
    vec2 c = C;
    #endif 
    
    for(int i = 0; i < MAX_STEPS; ++i)
    {
        if (rand1from2(p+vec2(float(i), k)) < 0.5)
            sgn = -sgn;

        if (dot(z,z) > BAIL) 
            return 0.;

        z = z_iter(z,c,sgn);        
    }
    
    return 1.;
}

vec3 pixelColor(in vec2 pixel) 
{   
    vec2 R = resolution.xy;
    float ar = R.x/R.y;
    vec2 vps = 1.0/MAGN*vec2(VIEWPORT.z*ar, VIEWPORT.w);
    vec2 dxy = vps/R.xy;
    vec2 p = VIEWPORT.xy-0.5*vps+pixel.xy*dxy;
      
    float res = 0.;
    for (float k = 0.; k < 128.; k+=1.)
         res += iter(p, k);
    
    if (res > 0.)
        return vec3(exp(-2.*res/SAMPLING)); 
    else
        return vec3(0.);
}

void main(void)
{
    float d = 1./float(AA);
    vec3 col = vec3(0.);
    
    for(int j = 0; j < AA; ++j)
        for(int i = 0; i < AA; ++i)
            col += pixelColor(gl_FragCoord.xy+vec2(i, j)*d);

    // gamma correction
    glFragColor.rgb = pow(col.rgb*d*d, vec3(.4545));
}
