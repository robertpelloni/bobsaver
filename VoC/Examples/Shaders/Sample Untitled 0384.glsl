#version 420

// original https://www.shadertoy.com/view/wsBXzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.1415;
float rond(float offset,vec2 uv,float r,float phi) {
     uv.x -= offset ;
    
    uv.y -= 0.5+ tan(2.*(time+2.*PI*offset))/5.;
    uv.x *= resolution.x/resolution.y;
    float dis = length(uv);
   
   
    float c =  smoothstep(r,r-phi,dis);
    return c ;
}
void main(void)
{ 
    float unphase = 0.5;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
 float phi_inner = 0.005;
    float phi_outter= 0.001+ clamp(abs(sin(time))/10.,0.04,0.09) ;
   float ca = rond(0.5+0.15*sin(time+4.*PI/3.),uv,.3,phi_inner)+ rond(0.5+0.15*sin(time+unphase+4.*PI/3.),uv,.4,phi_outter)/2.;
    
     float cb = rond(0.5+0.15*sin(time+(2.*PI/3.)),uv,0.3,phi_inner) +  rond(0.5+0.15*sin(time+unphase+2.*PI/3.),uv,0.4,phi_outter)/2.;
     float cc = rond(0.5+0.15*sin(time),uv,0.3,phi_inner)+ rond(0.5+0.15*sin(time+unphase),uv,0.4,phi_outter)/2.;
    float d = smoothstep(0.1,0.9,ca + cb + cc);
    // Output to screen
   
    glFragColor = vec4(vec3(ca,cb,cc),1.0);
}
