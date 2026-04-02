#version 420

// original https://www.shadertoy.com/view/XsVyDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-resolution.xy/2.)/resolution.y;
    
    uv = vec2(length(uv)*(8.+2.*sin(time*.1)), sin(atan(uv.x,uv.y)*floor(5.+mod(time*.2,6.)) + time*.3) );
    
    vec3 col = vec3(0);
    
    uv+=sin(uv.yx*(sin(time*.3)*2.)+time*.6*vec2(1,.9));
    
    col += 1.-smoothstep(0.1,.2, length(uv-vec2(uv.x,0)));
    col += 1.-smoothstep(0.2,.3, length(uv-vec2(floor(uv.x+.5),uv.y)));

    col *= .5+.5*cos(6.28*vec3(0,.33,.66)+uv.y+time + col*2. );
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
