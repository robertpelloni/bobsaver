#version 420

// original https://www.shadertoy.com/view/ltVBRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define maxiter 250
#define m1 1.0
#define m2 0.9
#define r1 0.5
#define r2 0.5
#define v1 0.5
#define v2 0.95

void rotate (inout vec2 vertex, float rads)
{
  mat2 tmat = mat2(cos(rads), -sin(rads),
                   sin(rads), cos(rads));
 
  vertex.xy = vertex.xy * tmat;
}

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - .5*resolution.xy ) / resolution.y;
    rotate(uv,0.35 * time);
    vec2 z = vec2(0.0, 0.0);
    float p = 0.0;
    float dist = 0.0;
    float x1 = tan(time*v1)*r1;
    float y1 = sin(time*v1)*r1;
    float x2 = tan(time*v2)*r2;
    float y2 = sin(time*v2)*r2;
    for (int i=0; i<maxiter; ++i)
    {
        z *= 2.0;
        z = mat2(z,-z.y,z.x) * z + uv;
        p = m1/sqrt((z.x-x1)*(z.x-x1)+(z.y-y1)*(z.y-y1))+m2/sqrt((z.x-x2)*(z.x-x2)+(z.y-y2)*(z.y-y2));
        dist = max(dist,p);

    }
    dist *= 0.0099;
    glFragColor = vec4(dist/0.3, dist*dist/0.03, dist/0.112, 1.0);
}
