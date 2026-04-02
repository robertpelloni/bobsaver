#version 420

// original https://www.shadertoy.com/view/tlGyWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 R = resolution.xy,
         U = gl_FragCoord.xy+gl_FragCoord.xy - R;
    U = sin( R.y/+sin(time*.6)*  U/dot(U,U) );
    U /= fwidth( U*=U.y );
    glFragColor = vec4(vec3(.9 + sin(U.x*.05 )),1.0);
  
}
