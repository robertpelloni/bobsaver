#version 420

// original https://www.shadertoy.com/view/ldcXRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec4 f = glFragColor;
    
    f.xy = resolution;
    vec2 v2 = g / f.xy;
    vec2 v3 = (g+g-f.xy)/f.y*8.;
    
    float t = time*.5;
    
    v3 = vec2(atan(v3.x,v3.y)/3.14159*5., length(v3));
    v3.x *= floor(v3.y);
    v3.x += floor(v3.y) * t;
       v3 = abs(fract(v3)-0.5);
    
    vec4 buf = vec4(0.01/dot(v3,v3));
    
    //if (mouse*resolution.xy.z>0.)
    //    v2 *= 0.999;
    //else
        v2 *= (.99 + vec2(cos(t*t),sin(t*t)) * 0.005);
         
    vec4 tex = texture2D(backbuffer, v2);
    
    f = buf * 0.1 + tex * 0.9;

    glFragColor = f;
}
