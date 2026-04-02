#version 420

// original https://www.shadertoy.com/view/WsfXWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    float angle = time;
    vec2 origin = vec2(0.5, 0.5);
    uv -= origin.xy;
    origin.y = 20.0*cos(time)*origin.y;
    vec2 rot = vec2(uv.x * cos(angle) - uv.y * sin(angle),
                    uv.x * sin(angle) + uv.y * cos(angle));
    rot += origin.xy;
    
    vec3 col = vec3(cos(rot.y+cos(20.0*rot.x+time)+time),
                    cos(rot.y+cos(20.0*rot.x+time)),
                    cos(rot.y+cos(20.0*rot.x+time)-time));
    

    // Output to screen
    glFragColor = vec4(col,0.5);
}
