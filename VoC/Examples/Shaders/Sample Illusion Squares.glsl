#version 420

// original https://www.shadertoy.com/view/dslSW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1416;
mat2 rotationMatrix(float angle){
    angle *= PI / 180.0;
    float s=sin(angle), c=cos(angle);
    return mat2( c, -s, s, c );
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;

    uv *=rotationMatrix(45.);
    uv *=7.;
    uv.x += step(1., mod(uv.y,2.0));

    bool c = (mod(uv.x,2.) < 1.);

    uv *=rotationMatrix(45.);
    uv = fract(uv)-(time/2.);

    vec3 d;
    if(c)
       d = vec3(1.- step(0.5,fract(uv.y*4.)))+0.3;
    else
       d = vec3( step(0.5,fract(uv.y*4.)));

    // Output to screen
    glFragColor = vec4(d,1.0);
}
