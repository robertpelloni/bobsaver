#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool b = false;

vec3 barycentric(vec2 uv)
{    
//    uv.y        /= sqrt(3.);
    uv.y        /= 1.73205080757;
    vec3 uvw    = vec3(uv.y - uv.x, uv.y + uv.x, -(uv.y + uv.y));
//    uvw        *= cos(pi/6.);
    uvw        *= .86602540358;
    //uvw *= time * .04;
    return uvw;
}

vec4 harmonic(in vec2 uv)
{
    vec4 f, r, s;

    vec3 b = barycentric(uv);
    f = vec4(b.x, b.y, b.z, b.x);
 
    r = s;
    //float m = mouse.y * 3.14;
    float m = 9.;
    float a = 1.;
    const int it = 16;
    for ( int i = 0; i < it; i++ )
    {
        f = (f.wxyz + f) * .5 + s;
        
        f.xzw = f.zwz;
        
        s = fract(sin(m*time*.04) + cos(m+time) * (f-f.wxyz));
        s = s * s;
        s = s * (1. - s);
        
        r += s * a; 
        
        a *= 2.;
        
    }
    
    return r/a*2.;
}

void main(void) 
{
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2. - 1.;
    uv.x *= resolution.x/resolution.y;

    uv *= 32.;
    vec4 fn;
    fn  = harmonic(uv);
    
    glFragColor.xyz    = cross(fn.yzx, fn.zxy)*16.;
    glFragColor.w    = 1.;
}//sphinx
