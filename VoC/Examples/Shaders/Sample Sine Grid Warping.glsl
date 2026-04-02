#version 420

// original https://www.shadertoy.com/view/4tVyRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float q(vec2 pos,float angle){
    return pos.x*cos(angle)+pos.y*sin(angle);
}
    
void main(void)
{
    float pi=atan(1.0,0.0)*2.0;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 pos=(uv-vec2(0.5))*resolution.xy/resolution.y*100.0;
    float s=time/5.0;
    float angle=atan(pos.y,pos.x)+s/2.0;
    pos=length(pos)*vec2(cos(angle),sin(angle));
    float c=cos(q(pos,pi/3.0))+cos(q(pos,0.0))+cos(q(pos,s+pi/3.0))+cos(q(pos,s+0.0))+cos(q(pos,pi/3.0*2.0))+cos(q(pos,s+pi/3.0*2.0));
    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+c+uv.xyx+vec3(0,2,4));

    // Output to screen
    glFragColor = vec4(col*(-c),1.0);
}
