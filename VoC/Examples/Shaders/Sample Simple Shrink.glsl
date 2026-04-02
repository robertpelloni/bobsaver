#version 420

// original https://www.shadertoy.com/view/lldBD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265359;

vec2 kaleidoscope(vec2 uv, vec2 offset, float splits)
{
    // XY coord to angle
    float angle = atan(uv.y, uv.x);
    // Normalize angle (0 - 1)
    angle = ((angle / PI) + 1.0) * 0.5;
    // Rotate by 90°
    angle = angle + 0.25 * time * 0.05;
    // Split angle 
    angle = mod(angle, 1.0 / splits) * splits;
    
    // Warp angle
    angle = -abs(2.0*angle - 1.0) + 1.0;
    
    angle = angle*0.1;
    
    // y is just dist from center
    float y = length(uv);
    
    angle = angle * (y*3.0);
    
    return vec2(angle, y) + offset;
}

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;

    vec2 offset = vec2(time   *0.05,  time   *0.5);
    vec2 uv  = kaleidoscope(p, offset, 10.);
    // pattern: cosines
    float f = cos(8.*uv.x)*cos(6.0*uv.y);
    
    // color fetch: palette
    vec3 col =0.+  sin( 3.1416*f + vec3(1.,0.5,1.0) );
    
    // output:
    glFragColor = vec4( col, 1.0 );

    // Output to screen
    glFragColor = vec4(col,1.0);
}
