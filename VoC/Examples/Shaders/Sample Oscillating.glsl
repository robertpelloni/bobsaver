#version 420

// original https://www.shadertoy.com/view/WsG3Dm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    //vec2 uv = (gl_FragCoord-.5*resolution.xy)/resolution.y;
    
    int strips = 150;
    float width = resolution.x / float(strips);
    
    float curStrip = floor(gl_FragCoord.x / width);
    float center = curStrip * width + width*.5;
    float height = (sin(.025 * time * (curStrip+1.))*.5+.5) * resolution.y;
    
    vec2 delta = gl_FragCoord.xy - vec2(center, height);
    float d = .5*dot(delta, delta)/width;    
    vec3 col = vec3(d);

    glFragColor = vec4(col,1.0);
}
