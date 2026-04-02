#version 420

// https://www.shadertoy.com/view/4ds3zX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float bouncy(vec2 v)
{    
    vec2  cp = v * time;
    vec2 cp_wrap = vec2(ivec2(cp) / ivec2(resolution.xy));    
    cp = mod(cp, resolution.xy);
    cp = mix(cp, resolution.xy - cp, mod(cp_wrap, 2.0));        
    return 25.0 / (1.0+length(cp - gl_FragCoord.xy));
}

void main(void)
{                        
    vec3 res = vec3(0);    
    res += vec3(1.0, 0.3, 0.2) * bouncy(vec2(211, 312));
    res += vec3(0.3, 1.0, 0.2) * bouncy(vec2(312, 210));
    res += vec3(0.2, 0.3, 1.0) * bouncy(vec2(331, 130));
    glFragColor = vec4(res, 1);    
}
