#version 420

// original https://www.shadertoy.com/view/3ljGzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592654

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.yy*2.;
    float a=(atan(uv.x,uv.y)/2./PI)+.5;
    float l=length(uv);
    float w=0.1/(1.+sqrt(l));
    l*=(1.+w*sin(a*10.*PI));
    a+=w*sin(l*2.*PI);
    l*=(1.+w*sin(a*12.*PI));
    a+=w*sin(l*2.2*PI);
    l*=(1.+w*sin(a*14.*PI));
    a+=w*sin(l*2.4*PI);
    l*=(1.+w*sin(a*16.*PI));
    a+=w*sin(l*2.6*PI);

    float r=a*12.+l-time;
    float g=l*3.+a+time*.5;
    float b=-a*6.+l*2.+time*.75;
    
    vec3 c=vec3(
        fract(r)>.5?0.:1.,
        fract(g)>.5?0.:1.,
        fract(b)>.5?0.:1.
    );
    //if(mouse*resolution.xy.z<0.1)
        c=(vec3(
            sin(r*2.*PI),
            sin(g*2.*PI),
            sin(b*2.*PI)
        )+1.)*0.5;
    glFragColor = vec4(c,1);
}
