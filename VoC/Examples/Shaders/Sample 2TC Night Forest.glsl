#version 420

// original https://www.shadertoy.com/view/MtfGRB

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main()
{
    vec2 q=gl_FragCoord.xy/resolution.xy,p;
    vec4 o=mix(vec4(.6,0,.6,1),vec4(1,1,.3,1),q.y);

    for(float i=8.;i>0.;--i)
    {
        p=q*i;
        p.x+=time*.3;

        p=cos(p.x+vec2(0,1.6))*sqrt(p.y+1.+cos(p.x+i))*.7;

        for(int j=0;j<20;++j)
            p=reflect(p,p.yx)+p*.14;

        o=glFragColor=dot(p,p)<3.?o-o:o;
    }
}
