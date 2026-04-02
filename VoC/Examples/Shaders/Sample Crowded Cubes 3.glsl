#version 420

// original https://www.shadertoy.com/view/MtBSRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// using the base ray-marcher of Trisomie21: https://www.shadertoy.com/view/4tfGRB#

#define T time
#define r(v,t) v *= mat2( C = cos((t)*T), S = sin((t)*T), -S, C )

void main(void) 
{
    float C,S,r,x,x1;
    vec4 p = vec4(gl_FragCoord.xy,0,1)/resolution.yyxy-.5, d; p.x-=.4; // init ray 
    r(p.xz,.13); r(p.yz,.2); r(p.xy,.1);   // camera rotations
    d = p;                                 // ray dir = ray0-vec3(0)
    p.z += 5.*T;
   
    for (float i=1.; i>0.; i-=.01)  
    {
        vec4 u = floor(p/8.), t = mod(p, 8.)-4., M,m; // objects id + local frame
        // r(t.xy,u.x); r(t.xz,u.y); r(t.yz,1.);      // objects rotations
        u = sin(78.*(u+u.yzxw));                      // randomize ids
   
        r = 1.2;
        t = abs(t); M=max(t,t.yzxw); m=min(M,M.yzxw);
        x = max(t.x,M.y)-r;
        x1 = min(m.x,m.y);
        x = max(x,1.1-x1);
        x = min(x,x1-.02);
        if(x<.01)  // hit !
            { glFragColor = i*i*(1.+.2*t); break; } // color texture + black fog 
        glFragColor=vec4(0.0);
        p -= d*x;           // march ray
     }
 }
