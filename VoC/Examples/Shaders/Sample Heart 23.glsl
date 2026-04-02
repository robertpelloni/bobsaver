#version 420

// original https://www.shadertoy.com/view/wtdGWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "A golden heart" by pik33. https://shadertoy.com/view/3tdGDB
// 2019-12-27 16:39:40

void main(void)
{

    vec2 uv =2.* (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec2 ab=-uv;
    
    ab.x=ab.x*0.6;
    ab.y+=-0.1+0.6*sqrt(abs(ab.x));

    float f=1.+0.05*sin(0.25*7.83*3.14159*time);
    float l=length(ab);
    float s=smoothstep(f*0.35,f*0.31,l);//-smoothstep(f*0.15,0.,l);

    vec2 p=vec2(s)+(1./f)*ab;
    p.x=abs(p.x);

    for(int i=1;i<55;i++)
    {
        vec2 newp=p;
        newp.x+=(0.5/(1.0*float(i)))*cos(float(i)*p.y+time*11.0/37.0+0.03*float(i));        
        newp.y+=(0.5/(1.0*float(i)))*cos(float(i)*p.x+time*17.0/41.0+0.03*float(i));
        p=newp;
    }
        vec3 col=vec3(fract(p.x),fract(p.y),fract(0.3*p.x+0.7*p.y));
    col.x=smoothstep(0.90,1.0,col.x);   
    col.y=smoothstep(0.90,1.0,col.y);
    col.z=smoothstep(0.90,1.0,col.z);

     if (s>0.1) col = vec3(s,s*0.63,s*0.2);

    glFragColor = vec4(col,1.0);
}
