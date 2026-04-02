#version 420

// original https://www.shadertoy.com/view/tts3z7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec3 col = 0.5 + 0.25*(cos(uv.yxy*15.0+time+uv.xyx*vec3(-3,-7,11)*7.0) + cos(uv.yxy*(-3.0)+time*vec3(-11,5,9)*0.3));
    float a = col.x*col.y*col.z;
    vec3 b = (1.0-uv.y) * vec3(1.0,0.5,0.7) + uv.y * vec3(0.4,0.8,1.0);
    
    glFragColor = vec4(b * (1.0-(col * a * 5.0)),1.0);

}
