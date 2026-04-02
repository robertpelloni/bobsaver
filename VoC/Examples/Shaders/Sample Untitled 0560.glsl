#version 420

// original https://www.shadertoy.com/view/WsfBz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 O = glFragColor;
    vec2 R=resolution.xy,U=(gl_FragCoord.xy-.5*R.xy)/R.y;
    float D,t=time;
    vec3 P,B = normalize( vec3( U.x, U.y,1) );
    for(int i = 0; i<64;i++) {
        P = vec3(0, sin(U.x*5.+t), -5)+ B*D;
        P.z-=t*6.; 
        P=mod(P,3.)-1.5;
        P.z -= clamp( P.z, 0., 5. );
        D+=length(P) - .05;
    }
    O.r=O.g=((D< 16.) ? 1.:0.);
    glFragColor = O;
}
