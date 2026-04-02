#version 420

// original https://www.shadertoy.com/view/llX3zB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//based on shader from coyote => https://www.shadertoy.com/view/ltfGzS

void main()
{
    float t = time;
    vec4 p=gl_FragCoord/resolution.x-.5,r=p-p,q=r;p.y+=.25;
       q.x=1.5*cos(t*0.3);
    q.y=1.5*sin(t*0.3);
    q.zw-=t*0.7;
    
    for (float i=1.; i>0.; i-=.01) {

        float d=0.,s=1.;

        for (int j = 0; j < 4 ; j++)
            r=max(r*=r*=r=mod(q*s+1.,2.)-1.,r.yzxw),
            d=max(d,( .27 -length(r)*.3)/s),
            s*=3.1;

        q+=p*d;
        
        glFragColor = p-p+i;

        if(d<1e-5) break;
    }
}
