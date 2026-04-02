#version 420

// original https://www.shadertoy.com/view/cddGRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    float d = length(uv);
    float a = atan(uv.y,uv.x);
    float r = abs(sin(time+a*3.)*sin(a*5.))*.5+.3;
    
    vec3 col = vec3( 1.-smoothstep(r,r+0.3,d*2.) );
    col += vec3( -smoothstep(r,r-0.3,d) );
    col += vec3( 1.-smoothstep(r,r-0.6,d*2.) );
    col += vec3( -smoothstep(r,r+0.6,d*2.) );
    
    glFragColor = vec4(col,1.0);
}
