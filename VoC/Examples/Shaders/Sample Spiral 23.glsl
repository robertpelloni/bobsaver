#version 420

// original https://www.shadertoy.com/view/ts3XRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    uv -= 0.5;
    
    uv.y *= resolution.y/resolution.x;

    // Time varying pixel color
    float f1 = sin(atan(uv.y,uv.x)*25.+sin(length(uv)*10.-time*1.5)*40. + sin(length(uv)*250.-time*1.5)*0.25 + time*5. + sin(time));
    float f2 = sin(atan(uv.y,uv.x)*25.+sin(length(uv)*10.-time*1.5)*40. + sin(length(uv)*250.-time*1.5+5.)*0.25 + time*5. + sin(time+1.));
    float f3 = sin(atan(uv.y,uv.x)*25.+sin(length(uv)*10.-time*1.5)*40. + sin(length(uv)*250.-time*1.5+10.)*0.25 + time*5. + sin(time+2.));
    
    vec3 col = vec3(f1,f2,f3);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
