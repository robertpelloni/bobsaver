#version 420

// original https://www.shadertoy.com/view/XsXSRf

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// vincent francois - cyanux/2014
// Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License (CC BY-NC-ND 3.0)

#define D 5.0

// hsv2rgb - iq / https://www.shadertoy.com/view/MsS3Wc
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}
vec3 rX(vec3 v, float t) {
    float COS = cos(t);
    float SIN = sin(t);
    return vec3(v.x,SIN*v.z+COS*v.y,COS*v.z-SIN*v.y);
}
vec3 rY(const vec3 v, const float t) {
    float COS = cos(t);
    float SIN = sin(t);
    return vec3(COS*v.x-SIN*v.z, v.y, SIN*v.x+COS*v.z);
}
void main(void) {
    vec2 M = 0.05 * vec2(cos(time), sin(time)) + vec2(0.3, 0.0);
    vec2 ar = vec2(resolution.x/resolution.y, 1.0);
    vec2 uv = 0.3 * ar * (gl_FragCoord.xy / resolution.xy - 0.5);
    vec3 ro = -rY(rX(vec3(0.0, 0.0, D) , M.y), M.x);
    vec3 rd = normalize(rY(rX(vec3(uv, 1.0), M.y), M.x));
    vec2 z;
    float d=0.0;
    float dz=0.0;
    int N=0;

    vec2 c = 2.0 * vec2(rd.x/rd.z, rd.y/rd.z);

    for(int n = 0; n < 32; n++)
    {
        d = length(ro) - 0.1;
        z = vec2(ro.x/ro.z, ro.y/ro.z);    
        for(int n = 0; n < 32; n++)
        {
            z = vec2(z.x*z.x-z.y*z.y,2.0*z.x*z.y) + c;
            N = n;            
            dz = length(z);            
            if(dz > 2.0)
                break;
        }        
        if(dz > 2.0)
            break;    
        ro += rd * 0.5 * d;
    }    
    glFragColor.rgb = hsv2rgb(vec3(rd.x - rd.y, (1.0 - float(N) / 32.0) + 4.0 * ro.z, 1.0 - d));
}
