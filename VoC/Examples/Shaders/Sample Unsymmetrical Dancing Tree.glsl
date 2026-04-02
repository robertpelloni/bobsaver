#version 420

// original https://www.shadertoy.com/view/tdy3Ww

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Forked from https://www.shadertoy.com/view/wslGz7

// Included partial solution for unsymmetrical trees - but was not able 
// to get rid of some clipping or floating wigs.

vec2 N(float angle) {
    return vec2(sin(angle), cos(angle));
}

vec2 po (vec2 v) {
    return vec2(length(v),atan(v.y,v.x));
}
vec2 ca (vec2 u) {
    return u.x*vec2(cos(u.y),sin(u.y));
}
float ln (vec2 p, vec2 a, vec2 b) { 
    float r = dot(p-a,b-a)/dot(b-a,b-a);
    r = clamp(r,0.,1.);
    p.x+=(0.7+0.5*sin(0.1*time))*0.2*smoothstep(1.,0.,abs(r*2.-1.))*sin(3.14159*(r-4.*time));
    return (1.+0.5*r)*length(p-a-(b-a)*r);
}
void main(void)
{   
     vec2 U = gl_FragCoord.xy;
     vec4 Q = glFragColor;
     vec2 R = resolution.xy;
     float r = 1e9;
     vec2 mouse = 2.*mouse*resolution.xy.xy/resolution.xy-1.; // -1 1 
     U = 4.*(U-0.5*R)/R.y;
     U.y += 1.5;
     Q = vec4(0);
     for (int i = 1; i < 16; i++) {
        U = ca(po(U)+0.3*(sin(2.*time)+0.5*sin(4.53*time)+0.1*cos(12.2*time))*vec2(0,1));
        r = min(r,ln(U,vec2(0),vec2(0,1.)));
        U.y-=1.;
        
        vec2 n = N(2.2);
        float d = dot(U, n);
        U -= min(0.,d)*n*2.;
        
        U.x=abs(U.x);
        U*=1.4+0.1*sin(time)+0.05*sin(0.2455*time)*(float(i));
        U = po(U);
        U.y += 1.+0.5*sin(0.553*time)*sin(sin(time)*float(i))+0.1*sin(0.4*time)+0.05*sin(0.554*time);
        U = ca(U);
        
        
        Q+=sin(1.5*exp(-1e2*r*r)*1.4*vec4(1,-1.8,1.9,4)+time);
        
         
     }
     Q/=18.;

     glFragColor = Q;
}
