#version 420

// original https://www.shadertoy.com/view/dlVXzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define RT(a) mat2(cos(m.a+vec4(0,11,33,0))) // rotate
#define S s = min(s, rd12(p-round(p), .44)); // repeating this a few times
float rd12(vec3 p, float r) // rhombic dodeca
{
    p = abs(p);
    return max(p.x+max(p.y, p.z), p.z+max(p.y, p.x))/1.732-r/1.732;
}
void main(void)
{
    vec2 U = gl_FragCoord.xy;
    float d = 0., e, s;
    vec2 R = resolution.xy,
         m = (mouse*resolution.xy.xy/R*4.)-2.;
    vec3 v = vec3(0, 0, -50), // cam
         u = normalize(vec3((U-.5*R)/R.y, 10)), // coords
         p;
    m = vec2(time/3., -.6); // move when not clicking
    mat2 pitch = RT(y), yaw = RT(x); // rotation
    for (int i=0; i<50; i++) // raymarch
    {
        p = v+u*d;
        p.yz *= pitch;
        p.xz *= yaw;
        s = rd12(p-round(p), .44); // first set
        p.xy += .5; S // next set
        p.yz += .5; S // etc.
        p.xy -= .5; S
        p.yz -= .5;
        s = max(s, rd12(p, 2.4)); // big one to boolean
        if (s < .001 || d > 100.) break;
        d += s;
        e = d/rd12(p, 0.); // inner shadow trick
    }
    glFragColor = vec4(vec3(pow(35./e, 25.)), 1);
}