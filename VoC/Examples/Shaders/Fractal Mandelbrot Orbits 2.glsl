#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define maxiter 10
#define m1 1.0
#define m2 0.9
//#define x1 0.045
//#define y1 0.04
//#define x2 -0.05
//#define y2 -0.025
#define r1 1.0
#define r2 0.5
#define v1 0.5
#define v2 0.9

void main( void )
{
    vec2 z = vec2(0.0, 0.0);
    float p = 0.0;
    float dist = 0.0;
    float x1 = sin(time*v1)*r1;
    float y1 = cos(time*v1)*r1;
    float x2 = sin(time*v2)*r2;
    float y2 = cos(time*v2)*r2;
    for (int i=0; i<maxiter; ++i)
    {
        z *= 2.0;
        vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
        z = vec2(z.x*z.x-z.y*z.y, z.x*z.y*2.0) + surfacePos;
        p = m1/sqrt((z.x-x1)*(z.x-x1)+(z.y-y1)*(z.y-y1))+m2/sqrt((z.x-x2)*(z.x-x2)+(z.y-y2)*(z.y-y2));
        if (p > dist)
        {
            dist = p;
        }
    }
    dist = dist*0.005;
    glFragColor = vec4(dist/0.3, dist*dist/0.03, dist/0.1, 1.0);
}
