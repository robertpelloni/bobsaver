#version 420

// original https://www.shadertoy.com/view/WtjSRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float size=4.;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv=uv*2.-1.;
    uv.x*=resolution.x/resolution.y;
    float d= length(uv);
    uv*=fract(d+time);//cos(d+time);
    
    // Time varying
    vec2 v=uv*size;
    uv=fract(uv*size); 
    
    float x=mod(v.x,2.);
    x=x-1.;
    x=sign(x);
    x=smoothstep(0.,1.,x);
    float y=mod(v.y,2.);
    y=y-1.;
    y=sign(y);
    y=smoothstep(0.,1.,y);
    float l =(x+y)==0.?1.:0.;
    float l2=(x+y)>1.?1.:0.;
    // Output to screen
    glFragColor = vec4(l+l2);
}
