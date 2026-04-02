#version 420

// original https://www.shadertoy.com/view/3dScDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846

float circle(vec2 st, float r, float i, float aa)
{
    r = r+i*abs(sin(6.0
                    *atan(st.y, st.x)
                    +time*1.));
    float d = length(st);
    float d1 = smoothstep(r, r-aa, d);//d<r?1.0:0.0;
    float d2 = smoothstep(r, r-aa, d+0.02);//d<r-0.01?1.0:0.0;
    return d1-d2;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(uv, 0.0);
    float mus = 0.0;//texelFetch(iChannel0, ivec2(1, 0), 0).x;
    mus *= .5;
    
    //circle
    float amp = 0.01;
    float aa = 0.1+
                pow( (0.5+0.5*sin(PI*time+uv.y)), 4.)
                *0.1;
    float cir1 = 0.;//circle(uv, 0.3, amp, aa);
    for (float i=0.1; i<0.27; i+=0.04)
        cir1 += circle(uv, i, amp, aa);
    
    float cir2 = circle(uv, 0.4, amp+0.1, aa+0.02);
    cir1 += cir2;
    // Output to screen
    vec3 A = vec3(0.8, 0.6, 0.1)*(1.0-length(uv));
    vec3 B = vec3(0.1, 0.1, 0.5);
    col = mix(B, A, (1.0-cir1)*(2.3));
    col = clamp(col, 0.0, 1.0);
    
    //gamma correction
    col *= 0.8+mus*0.4;
    //col = pow(col, vec3(1./2.4));
    glFragColor = vec4(col,1.0);
}
