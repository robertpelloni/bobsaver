#version 420

// original https://www.shadertoy.com/view/ddK3zy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy -.5;

    float l = length(uv)/3.;
    float a = atan(uv.y, uv.x);

    float b1 = sin(100.*(sqrt(l)-0.02*a-0.3*((time*50.+uv.y*(0.+cos(time*0.72)*150.9)+uv.x*(0.+cos(time*0.14)*100.9))/140.)))*2.54;
    float b2 = l*2.5;
    
    float g=max(b1/16.,0.09)+sin((a/2.5+time/2.5)*25.)*13.*(b2*b2);
    float b=sin((a/5.+time/3.5)*25.)*0.71*b2*b2*42.+0.62;
    
    vec3 col = vec3(b1*b1*b1*0.1+.62,
                    b1/3.5+b1*b*0.2-g/2.-.32,
                    b1/8.+b1*g*0.26+b/3.+.45);

    glFragColor = vec4(col*min(l*l*640000.,1.),1.0);
}
