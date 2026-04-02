#version 420

// original https://www.shadertoy.com/view/3lXSRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    uv -= 0.5;
    uv *= 10.0;
    
    float t = time+25.;
    uv -= t*3.8;
    // Time varying pixel color
    vec3 col;
    for (int i=0; i<9; i++) {
        t *= 1.13879213724+sin(col.r+col.g+col.b)*0.0052863;
        col.r += sin(uv.x*0.4+t);
        col.g += cos(uv.y*0.4+t*1.001379);
        col.rgb = col.gbr;
    }

    col.rgb = clamp(col.rgb/9.0+0.5,0.0,1.0);
    // Output to screen
    glFragColor = vec4(col,1.0);
}
