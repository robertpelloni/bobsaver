#version 420

// original https://www.shadertoy.com/view/Mtj3Rh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float r(float n)
{
     return fract(abs(sin(n*55.753)*367.34));   
}
float r(vec2 n)
{
    return r(dot(n,vec2(2.46,-1.21)));
}
float cycle(float n)
{
     return cos(fract(n)*2.0*3.141592653)*0.5+0.5;
}
void main(void)
{
    float a = (radians(30.0));
    float zoom = 96.0;
    vec2 c = (gl_FragCoord.xy+vec2(time*zoom,0.0))*vec2(cos(a),1.0);
    //c = c*mat2(cos(a),-sin(a),sin(a),cos(a));
    c = ((c+vec2(c.y,0.0)*sin(a))/zoom)+vec2(floor((c.x-c.y*sin(a))/zoom),0.0);
    float n = cycle(r(floor(c*4.0))*0.2+r(floor(c*2.0))*0.3+r(floor(c))*0.5+time*0.125);
    glFragColor = vec4(n*2.0,pow(n,2.0),0.0,1.0);
}
