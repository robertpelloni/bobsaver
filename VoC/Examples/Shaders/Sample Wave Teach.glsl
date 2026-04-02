#version 420

// original https://www.shadertoy.com/view/WlSGWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 mv = mouse*resolution.xy.xy/resolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    float wave=0.0;
    wave+=sin((uv.x-mv.x)*8.0);
    wave+=sin(time*4.0+uv.x*16.0);
    wave+=sin(time*8.0+uv.x*32.0);
    wave/=8.0;

    col=vec3(0.5,1,0.5);
    if( uv.y+wave > 0.5)
    {
        col=vec3(0.5,0.5,1.0);
    }
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
