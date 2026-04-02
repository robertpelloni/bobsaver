#version 420

// original https://www.shadertoy.com/view/MtSXDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float brightness = 3.;
const int iterations = 30;

void main(void)
{
    
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    
    float ang = atan(uv.y,uv.x);
    float len = length(uv);
    
    vec3 c = vec3(0.);
    
    for (int i = 0; i < iterations; i++) {
        float wlen = len*(35.+cos(time+float(i)*.723)*10.) + time;
        vec2 vuv = vec2(cos(wlen),sin(wlen))*len;
        float o = max(0.,1.-length(uv-vuv)*(5.+cos(float(i)*.6345)*3.));
        c += o*(vec3(sin(float(i)),cos(float(i)),-cos(float(i)))*.5+.5);
        uv = uv-uv*vuv/len*.4;
    }
    
    glFragColor = vec4(c*(1./float(iterations))*brightness,1.);
    
}
