#version 420

// original https://www.shadertoy.com/view/wl2fzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= .5;
    uv.x *= resolution.x / resolution.y;
    uv *= 3.;
    
    vec3 color;
    
    float t = time;
    
    mat2 rot = mat2(cos(t/6.), -sin(t/6.), sin(t/6.), cos(t/6.));
    mat2 roti = mat2(cos(-t/6.), -sin(-t/6.), sin(-t/6.), cos(-t/6.));
    
    vec2 p1,p2,p3,p4;
    p1 = rot * vec2(-.5, .5);
    p2 = roti * vec2(.5, .5);
    p3 = roti * vec2(-.5, -.5);
    p4 = rot * vec2(.5, -.5);

    float v1,v2,v3,v4;
    v1 = sin(length(uv - p1)*50.-t)*exp(length(uv) + 1.);
    v2 = sin(length(uv - p2)*50.-t)*exp(length(uv) + 1.);
    v3 = sin(length(uv - p3)*50.-t)*exp(length(uv) + 1.);
    v4 = sin(length(uv - p4)*50.-t)*exp(length(uv) + 1.);
 
    color = vec3(v1+v2+v3+v4);
    
    // Output to screen
    glFragColor = vec4(color, 1.0);
}
