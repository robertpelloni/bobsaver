#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SIN_ITER 3

float f(vec3 p)
{       p.y +=.9;
    p.x += time;
    for (int i=0;i<SIN_ITER;i++)
    {
        p = sin(p*0.91+0.17+cos(time*0.123)*0.1);
    }
    return length(p) - 1.0/float(SIN_ITER);
}

void main( void ) {

    vec2 pos = (gl_FragCoord.xy) / max(resolution.x, resolution.y);

    vec3 p = vec3(pos, -2.0);
    for (int i=0;i<200;i++)
    {
        p += f(p)*vec3(pos, 0.5+sin(time*0.1));
    }

    glFragColor = vec4(1.-abs(p-4.*vec3(pos, 1.))/5., 1.);

}
