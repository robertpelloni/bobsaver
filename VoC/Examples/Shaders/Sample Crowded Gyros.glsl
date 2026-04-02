#version 420

// original https://www.shadertoy.com/view/MllXz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// using the base ray-marcher of Trisomie21: https://www.shadertoy.com/view/4tfGRB#

#define T time
#define r(v,t) { float a = (t)*T, c=cos(a),s=sin(a); v*=mat2(c,s,-s,c); }
#define SQRT3_2  1.26

void main(void) {
    vec4 p = vec4(gl_FragCoord.xy,0,1)/resolution.yyxy-.5, d,c; p.x-=.4; // init ray 
    r(p.xz,.13); r(p.yz,.2); r(p.xy,.1);   // camera rotations
    d = p;                                 // ray dir = ray0-vec3(0)
    p.z += 5. *T;
    glFragColor = vec4(0);
    float closest = 999.0; vec4 u_c=glFragColor;
   
    for (float i=1.; i>0.; i-=.01)  
    {
        vec4 u = floor(p/8.), t = mod(p, 8.)-4., ta; // objects id + local frame
        // r(t.xy,u.x); r(t.xz,u.y); r(t.yz,1.);     // objects rotations
        u = sin(78.*(u+u.yzxw));                     // randomize ids
        // t -= u;                                   // jitter positions
        c = p/p*1.2;
        
    
 
        float x1,x2,x=1e9;
        for (float j=2.3; j>1.; j-= .3) {
            r(t.xy,u.x); r(t.xz,u.y); r(t.yz,u.z);
            ta = abs(t);
            x1 = length(t.xyz) -j*SQRT3_2;       // inside carving sphere
            x2 = max(ta.x,max(ta.y,ta.z)) -j;    // cube
            x2 = max(-x1,x2);                    // cube-sphere
            x1 = length(t.xyz) -j*SQRT3_2-.1;    // outside carving sphere
            x2 = max(x1,x2);                     // shape inter sphere
            x = min(x,x2);                       // union with the others
        }

        x1 = length(t.xyz) -.6;                  // central spheres
        if (x1 < closest) { closest = x1; u_c = u; } 
        x = min(x1,x);
        if (x==x1)  c  = u*3.; 
        //   else   c += u*3.*pow(abs((x-x1)),.2)*(.5+.5*sin(.5*T));  // thanks squid !
        
        // f = i*i*c;      // color texture + black fog 

        if(x<.01) // hit !
            { glFragColor = i*i*c; break;  }  // color texture + black fog 
        p -= d*x;           // march ray
     }
     if (cos(.25*T)>0.) glFragColor += u_c * exp(-closest)*(.5+.5*cos(.5*T)); // thanks kuvkar ! 
}
