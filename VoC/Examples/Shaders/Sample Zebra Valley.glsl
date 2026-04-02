#version 420

// original https://www.shadertoy.com/view/sdlfRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
	vec2 U=gl_FragCoord.xy;
	vec4 O=gl_FragColor;

    vec2 R = resolution.xy;
    U *= 7./R;
    O-=O;
    for(float i=0.,v; i++ < 70.; )
        v = 9.-i/6.+2.*cos(U.x + sin(i/6. + time ) ) - U.y,
        O = mix(O, vec4(int(i)%2), smoothstep(0.,15./R.y, v) );

	glFragColor=O;
}
