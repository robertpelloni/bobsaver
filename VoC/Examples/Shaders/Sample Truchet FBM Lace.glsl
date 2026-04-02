#version 420

// original https://www.shadertoy.com/view/DtjXDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ---------------------------------------------------------------------------------------
//    Created by fenix in 2023
//    License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//    Just trying to understand noise and I wondered what it would look like to try to
//    build a noise function on top of a truchet pattern. I came across this lacy pattern
//    and I thought it was interesting enough to share.
//
// ---------------------------------------------------------------------------------------

// From iq's Noise - gradient - 2D https://www.shadertoy.com/view/XdXGW8
vec2 grad( ivec2 z )  // replace this anything that returns a random vector
{
    // 2D to 1D  (feel free to replace by some other)
    int n = z.x+z.y*11111;

    // Hugo Elias hash (feel free to replace by another one)
    n = (n<<13)^n;
    n = (n*(n*n*15731+789221)+1376312589)>>16;

    // simple random vectors
    return vec2(cos(float(n)),sin(float(n)));                       
}

mat2 rotate(float a)
{
    vec2 sc = vec2(sin(a), cos(a));
    return mat2(sc.y, -sc.x, sc.x, sc.y);
}

const float PI = 3.141592653589793;

float truchet(vec2 p, float t)
{
    float a = trunc(grad(ivec2(p)).x * 4.) * PI * .5;
    vec2 uv = (fract(p) - .5) * rotate(a) + .5;
    return smoothstep(t, 0., abs(length(uv) - .5)) + smoothstep(t, 0., abs(length(uv - 1.) - .5));
}

vec3 truchetFbm(vec2 p)
{
    vec3 c = vec3(0);
    float t = .0005;
    for (float i = 0.; i < 50.; ++i)
    {
        p += i*vec2(0.01 * time + .3, 0.) * rotate(i * 4.);
        c = max(c, truchet(p, t));
        const float R = 1.1;
        p = p * rotate(1.9) * R;
        t *= R;
    }
    return c;
}

void main(void) //WARNING - variables void ( out vec4 O, vec2 u ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 u = gl_FragCoord.xy;
	vec4 O = vec4(0.0);

	u = (u - .5*resolution.xy) / resolution.y;
    
    vec3 bg = normalize(sin(time + u.x + u.y + vec3(0, 1, 3)) * .5 + .5) * .5;
    O.rgb = truchetFbm(u*.25) + bg;
    O.a = 1.;

	glFragColor = O;
}
