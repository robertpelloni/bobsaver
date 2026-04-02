#version 420

// original https://www.shadertoy.com/view/3lXXDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define PI2 6.28318530718
#define e 2.71828
#define SS01(t, count) mod(ceil((t)/PI2), count) / (count-1.)
#define SS(t, min, max, count) mix(min, max, SS01(t,count) )
#define S(a,b,t)  mix(a, b, sin(t) * .5 + .5)
#define C(a,b,t)  mix(a, b, cos(t) * .5 + .5)

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float t = time;
    
    float l = length(uv);
    float a = atan(uv.x,uv.y)/6.28+.5;

    ///
    
    float p = a;
    float sh = pow(e,-l);
    p += -t + l*5. * (sh)*S(1.,5.,t/3.);
    p = fract(p);
    p = step(.5,p);

    
    p *= pow(1.-sh,1.5)*3.; // shadow
//    p += pow(sh-.2,9.)*2.*S(1.,5.,t/5.); // light
    
    ///
    
    float c = p;

    vec3 col = vec3(c);

    glFragColor = vec4(col,1.0);
}
