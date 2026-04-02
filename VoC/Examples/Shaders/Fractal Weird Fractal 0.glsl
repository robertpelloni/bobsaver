#version 420

// original https://www.shadertoy.com/view/Xts3RB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//based on shader from coyote => https://www.shadertoy.com/view/ltfGzS

void main()
{
    vec4 p=gl_FragCoord/resolution.x-.5,r=p-p,q=r;
    q.zw-=time*0.1+1.;
    
    for (float i=1.; i>0.; i-=.01) {

        float d=0.,s=1.;

        for (int j = 0; j < 6; j++)
            r=max(r=abs(mod(q*s+1.,2.)-1.),r.yzxw),
            d=max(d,(.3-length(r*0.95)*.3)/s),
            s*=3.;

        q+=p*d;
        
        glFragColor = p-p+i;

        if(d<1e-5) break;
    }
}
