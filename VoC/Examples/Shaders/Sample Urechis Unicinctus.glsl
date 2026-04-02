#version 420

// original https://www.shadertoy.com/view/fs3SDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = ((gl_FragCoord.xy-resolution.xy/2.)/resolution.yy)*10.;
    vec3 col=vec3(0);
    col=vec3(.1,.4+.05*uv.y,.5+.1*uv.y);
    float t=time*3.;
    vec2 ps[7];
    for(int k=0;k<6;k++)
    {
        ps[k]=vec2(0);
    }
    
    for(float f=0.;f<1.;f+=0.005)
    {
        for(int k=0;k<6;k++)
        {
            vec2 p=ps[k];
            float j=float(k);
            float r=sin(f*48.+sin(t+j*3.1));
            r*=r;
            float w=clamp((1.-length(uv-p*.03)*4.-f*.6-r*r*.1)*5.,0.,1.);
            vec3 c=vec3(.6,.4,.2);
            col=mix(col, (-r+2.)*c*(uv.y-p.y*.03+.05)*2.5*(1.+f)+vec3(.5,.3,.3), w);
            float af=t*.1+j+sin(f*12.*(11.7+j*1.71)*.05-t*(26.3+j*1.87)*.02+j*3.1+117.)*f*5.;
            ps[k]+=vec2(sin(af), cos(af))*1.7;
        }
    }
    glFragColor = vec4(col,1.0);
}
