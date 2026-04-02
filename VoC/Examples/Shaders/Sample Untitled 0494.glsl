#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141593

void main( void ) {

    vec2 p = ( gl_FragCoord.xy * 2. - resolution )/ min(resolution.x, resolution.y );
    //p *= 1.3;
    p.y = 0.01/dot(p,p);
    p.x = 0.08/dot(p,p);

    
    float a = atan(p.y, p.x);
    vec4 c = vec4(cos(p.y*132.+time+a*256.), sin(time-a*3.3), 0, 1.);
    c *= 1. - length(p*0.5+sin(10.*p.x+time*2.4));
    
    c = c * 0.5 + 0.5;
    c.g = abs(sin(time+p.x)*0.4);
    c.b *= cos(7.7*time+p.y*132.0)*2.0;

    float vv =c.r;
    float vv2 =c.b;
    
    c *= smoothstep(3.25, 0.1, length(p*4.0));
    c.r = vv;
    
    c.xyz = vec3(length(c.xyz)*0.6);
    c.r -= vv2*0.3;
    c.rb *= vv;
    
     c = pow(c,vec4(1.1-sin(time+p.x*2.0)*0.5));
    
    c.a = 1.0;
    
    

    glFragColor = c;

}
