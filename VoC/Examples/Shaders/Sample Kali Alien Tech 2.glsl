#version 420

// original https://www.shadertoy.com/view/3t3XRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define aa 3

mat2 rot(float a) {
    float s=sin(a);
    float c=cos(a);
    return mat2(c,s,-s,c);
}

vec3 fractal(vec2 p) {
    float c=cos(time*.1);
    p.x+=smoothstep(.5,1.,abs(c))*sign(c)*2.;
    p*=.4;
    p.y+=time*.05+1.5;
    float v=(floor(mod(p.y,10.))+smoothstep(.9,1.,fract(p.y)))*.1;
    p=abs(.5-fract(p*.5));
    vec2 m=vec2(100.);
    float s=100.,t=s;
    for (int i=0; i<10; i++) {
        p=abs(p+2.)-abs(p-2.)-p;
        p.x-=3.;
        p=p*2.5/clamp(dot(p,p),.2,1.)-1.5-v;
        m=min(m,abs(p));
        s=min(s,length(p*p*p)*.1);
        t=min(t,length(p));
    }
    s=1.-abs(.5-fract(s))*2.;
    t=pow(max(0.,1.-t),2.);
    s-=mod(p.x*.7+1.,16.)*.05;
    m*=rot(-time+p.y*.1);
    m=normalize(abs(m));
    return vec3(m*m*3.,1.)*smoothstep(0.,3.,atan(m.x,m.y))+.3-s*s*s*10.+t;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    uv.x*=sqrt(1.+uv.y);
    uv.y*=sqrt(1.5+uv.y);
    vec3 col = vec3(0.);    
    for (int i=-aa; i<aa; i++) {
        for (int j=-aa; j<aa; j++) {
            col+=fractal(uv+vec2(i,j)*1./resolution.xy/float(aa));
        }
    }    
    col*=(1.3-abs(uv.x))*vec3(1.,.7,.4)/float(aa*aa)*.15*smoothstep(0.,1.,time);
    col*=max(0.2,1.-uv.y);
    glFragColor = vec4(col,1.0);
}
