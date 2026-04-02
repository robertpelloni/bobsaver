#version 420

// original https://www.shadertoy.com/view/Nsc3Rn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float checker(in vec2 st)
{
  const float checkSize = 4.0;
  vec2 tile = abs( mod(checkSize * st, 2.) - 1.);
  tile = smoothstep( checkSize*length(fwidth(st)),0.,tile-.5);
  tile = tile*2.-1.;
  return tile.x*tile.y *.5 + .5;
}

void main(void)
{
    // Set coordinate system from -1.5 to 1.5 on y-axis
    // dist 1.0 is where distance will go to infinite in hyperbolic space.
    vec2 uv = 1.5 * ( gl_FragCoord.xy - .5*resolution.xy ) / resolution.y;
    
    //Transfrom to hyperbolic space.
    uv /=  (1. / (length(uv) - 3.*sin(time/5.0) - 1.0) ) - 1.;
    uv += vec2(time, 2.*sin(time/3.));
    glFragColor = vec4(vec3(checker(uv)),1.);
}
