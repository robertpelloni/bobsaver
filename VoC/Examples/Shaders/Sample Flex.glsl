#version 420

// original https://www.shadertoy.com/view/MsdBWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 fc = vec2(gl_FragCoord);
    float t = time;
    float z = 37.37;
    float k = sin(fc.y*0.005 * (uv.x-0.5) - t*1.5)*233.0;
  //float c= mod(gl_FragCoord.x+k, z ) - z * 0.5;
    float c = mod(fc.x+k, z + mod(uv.y+t*-0.3,0.1) * 10.0 ) - z * sin(uv.x*1.5);
    glFragColor = vec4(c);
}
