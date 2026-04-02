#version 420

// original https://www.shadertoy.com/view/MlSXzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// using the base ray-marcher of Trisomie21: https://www.shadertoy.com/view/4tfGRB#

#define T time
#define r(v,t) v *= mat2( C = cos((t)*T), S = sin((t)*T), -S, C )

void main(void) 
{
    float C,S,r,x;
    vec4 p = vec4(gl_FragCoord.xy,0,1)/resolution.yyxy-.5, d,p2; p.x-=.4; // init ray 
    r(p.xz,.13); r(p.yz,.2); r(p.xy,.1);   // camera rotations
    d = p;                                 // ray dir = ray0-vec3(0)
    p.z += 5.*T;
   
    for (float i=1.; i>0.; i-=.01)  
    {
        vec4 u = floor(p/8.), t = mod(p, 8.)-4., M,m; // objects id + local frame
        // r(t.xy,u.x); r(t.xz,u.y); r(t.yz,1.);      // objects rotations
        u = fract(1234.*sin(78.*(u+u.yzxw)));         // randomize ids
        
        p2 = p; p2.x -= 15.*T*(2.*u.y-1.);            // offset column
        u = floor(p2/8.); t = mod(p2, 8.)-4.;
        u = fract(1234.*sin(78.*(u+u.yzxw)));
        
        if (u.y<.5) if (mod(T,6.)<1.) r(t.xy,3.14159);// rotate column
              
        r = 1.2;
        t = abs(t); M=max(t,t.yzxw); 
        x = max(t.x,M.y)-r;
        if (u.x<.5) x = max(x,r-u.x -M.x);
        if (u.y<.5) x = max(x,r-u.y -M.y);
        if (u.z<.5) x = max(x,r-u.z -M.z);
        if(x<.01)  // hit !
            { glFragColor = i*i*(1.+.2*t); break; } // color texture + black fog 
        glFragColor=vec4(0.0);
        p -= d*x;           // march ray
     }
 }
