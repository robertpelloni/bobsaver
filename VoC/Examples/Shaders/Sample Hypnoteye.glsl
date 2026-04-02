#version 420

// original https://www.shadertoy.com/view/Xl2GDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Couldn't resist to bring this at least to under 512b :P
// See the 128b original at https://www.pouet.net/prod.php?which=65604
// Or as directly as video at https://www.youtube.com/watch?v=HIFY5AETrlM
// Feel free to use any of this. If you got ideas on how to make
// the XOR pattern faster or smaller, i'd be curious to hear them =)

void main(void)
{

    vec2 uv = gl_FragCoord.xy / resolution.xy - 0.5;
    uv.x *= resolution.x / resolution.y;
    
    float a=atan(uv.x,uv.y)/3.14-time/20.;
    float r=(length(uv));
    r=.2/r;
    float c1=float(r<2.);
    float c2=float(r>.4);
    float c3=float(r<.38);
    r+=time/4.;
    a=mod(a,1.);
    r=mod(r,1.);
    float v=0.;
    float p=.5;
    for (int i=7;i>0;i--)
    {
        float m=0.;
        if (a>p)
        {
            m+=1.;
            a-=p;
        }
        if (r>p)
        {
            m+=1.;
            r-=p;
        }
        if (m!=1.)v+=p;
        p/=2.;
    }
    glFragColor = vec4(mod(v*8.,1.),mod(v*4.,1.),mod(v,2.),0)*c1*c2+c3;
}
