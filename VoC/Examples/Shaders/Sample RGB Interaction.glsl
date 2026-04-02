#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

#define iter 10
#define speed 0.25
#define grid 20.0

/*
#define iter 150
#define speed 0.1
#define grid 4.0
*/

void main()
{
    vec2 uv = gl_FragCoord.xy / max(resolution.x, resolution.y);
    float t = time * speed;
    vec2 p = uv;
    for(int i=1; i<=iter; ++i)
    {
        vec2 np = p;
        np.x += .5/float(i)*cos(float(i)*p.y+t) - 1.0;
        np.y += .5/float(i)*sin(float(i)*p.x+t) + 1.0;
        p=np;
    }
    glFragColor = vec4(cos(grid*p), sin(grid*(p.x + p.y)), 1.0);
}
