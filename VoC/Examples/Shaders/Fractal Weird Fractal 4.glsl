#version 420

// original https://www.shadertoy.com/view/MtsGzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//based on shader from coyote => https://www.shadertoy.com/view/ltfGzS

// matrix op
mat3 getRotYMat(float a){return mat3(cos(a),0.,sin(a),0.,1.,0.,-sin(a),0.,cos(a));}
//mat3 getRotZMat(float a){return mat3(cos(a),-sin(a),0.,sin(a),cos(a),0.,0.,0.,1.);}
void main()
{
    vec2 s = resolution.xy;
    float t = time*.2, c=0.0,d,m;
    vec3 p=vec3((2.*gl_FragCoord.xy-s)/s.x,1.),r=p-p,q=r;
    //p*=getRotZMat(-t);
    p*=getRotYMat(-t);
       q.zx += 10.+vec2(sin(t),cos(t))*3.;
    for (float i=1.; i>0.; i-=.01) {
        c=d=0.,m=1.;
        for (int j = 0; j < 3 ; j++)
            r=max(r*=r*=r*=r=mod(q*m+1.,2.)-1.,r.yzx),
            d=max(d,( .29 -length(r)*.6)/m)*.8,
            m*=1.1;

        q+=p*d;
        
        c = i;
        
        if(d<1e-5) break;
    }
    
    float k = dot(r,r+.15);
    glFragColor.rgb = vec3(1.,k,k/c)-.8;
    
}
