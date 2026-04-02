#version 420

// original https://www.shadertoy.com/view/ltfGzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//an attempt to fit fb39ca4's Menger Tunnel https://www.shadertoy.com/view/XslGzl
//into two tweets
//
//I managed to do it, sort of, but didn't like the too simple coloring, and especailly
//the fact that camera was static
//
//so here it is now, with the camera movement that I wanted (291 chars)
//feel free to add coloring to your liking ;)
//btw, after 200 or so seconds fp errors might kick in...

//UPDATE: Thanks to the great community here at ShaderToy, it is now 280 chars

void main()
{
    vec4 p=gl_FragCoord/resolution.x-.5,r=p-p,q=r;
    q.x=.3*sin(q.z=-time);

    for (float i=1.; i>0.; i-=.01) {

        float d=0.,s=1.;

        for (int j = 0; j < 5; j++)
            r=max(r=abs(mod(q*s+1.,2.)-1.),r.yzxw),
            d=max(d,(.29-min(r.x,min(r.y,r.z)))/s),
            s*=3.;

        q+=p*d;
        
        glFragColor = p-p+i;

        if(d<1e-5) break;
    }
}
