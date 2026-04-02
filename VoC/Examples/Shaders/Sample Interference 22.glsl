#version 420

// original https://www.shadertoy.com/view/3tccRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 bounce(float t, vec2 p){
    return abs(fract(t*p*0.1)-0.5)*4.-1.;
}

void main(void)
{
    
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    float c = sin(35.*length(uv-bounce(time*0.9, vec2(2.2,3.4))))*0.5+0.5;
    c += sin(35.*length(uv-bounce(5.+time*0.9, vec2(0.2,2.4))))*0.5+0.5;
    c += sin(35.*length(uv-bounce(30.+time*0.9, vec2(1.33,0.74))))*0.5+0.5;
    c*= 0.34;

    glFragColor = vec4(0.,0.6*c,c,1.0);
}
