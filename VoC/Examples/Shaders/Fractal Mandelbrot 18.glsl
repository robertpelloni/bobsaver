#version 420

// original https://www.shadertoy.com/view/sty3Dz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926

#define PALETTE   vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30)
//#define PALETTE   vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25)
//#define PALETTE   vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20)

#define REPEAT 2.
#define USE_TEXTURE 0

// iq palette
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv -= vec2(1.25, 0.5);
    uv *= 2.;

    vec2 z = vec2(0.);
    int i0 = 0;
    
    for (int i = 0; i < 60; ++i)
    {
        vec3 z2 = z.xyx * z.xyy;
        z = vec2(z2.x - z2.y, 2. * z2.z) + uv;
        float l2 = dot(z,z);
        if (l2 > 4.) {
            i0 = i;
            break;
        }
    }
    
    float mu = fract(((atan(z.y,z.x) + 2.*PI) / (2.*PI)) + time * 0.5);
    
    #if USE_TEXTURE
    vec3 col = texture(iChannel0, vec2(float(i0)/60.,mu)).xyz;
    #else
    vec3 col = pal(fract(mu*REPEAT), PALETTE);
    #endif
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
