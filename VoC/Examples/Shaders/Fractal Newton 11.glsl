#version 420

uniform float time;
uniform vec2 mouse, resolution;

out vec4 glFragColor;

#define ITERATIONS 10.0
#define BOUND 2.0
#define POW 3.
#define EPS 0.0001    
#define sqCpx(a) vec2(a.x * a.x - a.y * a.y, a.x * a.y + a.y * a.x);
#define Mul2(u, v) vec2(u.x * v.x - u.y * v.y, u.x * v.y + u.y * v.x)

vec2 Inv2(vec2 v)
{
    float r = length(v);
    (r != 0.0) ? v = vec2(v.x / r / r, -v.y / r / r) : v;
    return v;
}

vec2 Power(vec2 v, float n)
{
    float r = length(v);
    float ang = (sin(time * .3) - .5) * 3.14 + atan(v.y, v.x);
    return pow(r, n) * vec2(cos(ang * n), sin(ang * n));
}

float NewTon(vec2 z)
{

    vec2 dz, f, df, ddf, ddz;

    for (float i = 1.0; i < ITERATIONS; i++)
    {
        f = Power(z, POW) - vec2(1, cos(time * 3.)); //z^p-1=0
        df = POW * Power(z, POW - 1.);
        dz = -Mul2(Inv2(df), f);
        z += dz;
        if (length(dz) < 0.001) return 0.0;
    }

    ddf = POW * (POW - 1.0) * Power(z, POW - 2.0);
    ddz = Mul2(Inv2(Mul2(df, df)), Mul2(f, ddf));

    float lens = length(ddz);

    return lens;

    //return length(dz)-0.001;
}

float toEsc(vec2 p)
{
    vec2 z = p;
    for (float i = 1.0; i < ITERATIONS; i++) 
    {
        z = Power(z, POW) + p;
        if (length(z) > BOUND) return i;
    }
    return 0.0;
}

void main() 
{
    vec2 scale = vec2(resolution.x / resolution.y, 1); // converts from square to rectangular
    vec2 position = (gl_FragCoord.xy / resolution.xy) * scale * 4.0 - scale * 2.0;

    float b = NewTon(position);

    if (b != 0.) 
    {

        float bx = NewTon(vec2(position.x + EPS, position.y));
    float by = NewTon(vec2(position.x, position.y + EPS));

        vec2 lr = vec2(0.7, 0.5), lg = vec2(-0.7, 0.5), lb = vec2(0, -1);

        vec2 norm = normalize(vec2(bx - b, by - b));

        vec3 color = vec3(dot(lr, norm), dot(lg, norm), dot(lb, norm));
        color = clamp(color, 0.0, 1.0);

        glFragColor = vec4(color, 1.0);

    }
    else glFragColor = vec4(0, 0, 0, 1);
}
