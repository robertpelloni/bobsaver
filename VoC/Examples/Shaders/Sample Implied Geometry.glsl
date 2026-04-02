#version 420

// original https://www.shadertoy.com/view/llcfW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define CHROMA

#define pi acos(-1.)
#define tau (pi*2.)

const float SCROLL_SPEED = 1.;
const float SPIN_SPEED_H = 1.;
const float SPIN_SPEED_V = .1;
const float WIRE_THICKNESS = .03;
const float CUBE_SCALE = .66;

bool state;
float time2;

vec2 rotate(vec2 a, float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
    );
}

float sdOctahedron(vec3 p, float r)
{
    p = abs(p);
    float d = p.x + p.y + p.z - r;
    return d / sqrt(3.);
}

float sdLine(vec3 p, vec3 a, vec3 b)
{
    float t = dot(p-a,b-a)/dot(b-a,b-a);
    return distance(p,mix(a,b,t));
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r)
{
    return sdLine(p,a,b)-r;
}

float sdCappedLine(vec3 p, vec3 a, vec3 b)
{
    float t = dot(p-a,b-a)/dot(b-a,b-a);
    t = clamp(t,0.,1.);
    return distance(p,mix(a,b,t));
}

float sdCappedCylinder(vec3 p, vec3 a, vec3 b, float r)
{
    return sdCappedLine(p,a,b)-r;
}

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

float sdBox(vec3 p, vec3 r)
{
    vec3 d = abs(p)-r;
    return min(max(max(d.x,d.y),d.z),0.) + length(max(d,0.));
}

vec3 spin(vec3 p)
{
    p.xy = rotate(p.xy, time);
    p.yz = rotate(p.yz, time);
    p.zx = rotate(p.zx, time);
    return p;
}

vec3 spin2(vec3 p)
{
    p.xy = rotate(p.xy, -time);
    p.yz = rotate(p.yz, -time);
    p.zx = rotate(p.zx, -time);
    return p;
}

float scene(vec3 p)
{
    float d;
    if (state)
    {
        d = min(
            min(
                sdOctahedron(spin2(p), .5),
                sdCappedCylinder(abs(spin(p)),vec3(1,0,0),vec3(0,1,0),WIRE_THICKNESS)
            ),
            min(
                sdCappedCylinder(abs(spin(p)),vec3(0,1,0),vec3(0,0,1),WIRE_THICKNESS),
                sdCappedCylinder(abs(spin(p)),vec3(0,0,1),vec3(1,0,0),WIRE_THICKNESS)
            )
        );
    }
    else
    {
        d = min(
            min(
                sdBox(spin2(p), vec3(.5)*CUBE_SCALE),
                sdCappedCylinder(abs(spin(p)),vec3(1,1,1)*CUBE_SCALE,vec3(0,1,1)*CUBE_SCALE,WIRE_THICKNESS)
            ),
            min(
                sdCappedCylinder(abs(spin(p)),vec3(1,1,1)*CUBE_SCALE,vec3(1,0,1)*CUBE_SCALE,WIRE_THICKNESS),
                sdCappedCylinder(abs(spin(p)),vec3(1,1,1)*CUBE_SCALE,vec3(1,1,0)*CUBE_SCALE,WIRE_THICKNESS)
            )
        );
    }
    return min(
        d,
        -sdSphere(p, 10.)
    );
}

void main(void)
{
    vec4 out_color = glFragColor;
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;

#ifdef CHROMA
    for(int c=0;c<3;++c)
    {
        time2 = time + float(c)*.02;
#else
    {
        time2 = time;
#endif
        float spinHTime = time2 * SPIN_SPEED_H;
        float spinVTime = time2 * SPIN_SPEED_V;
        float scrollTime = time2 * SCROLL_SPEED;
        
        vec3 perspcam = vec3(0,0,-2);
        vec3 perspdir = normalize(vec3(uv,.8));

        vec3 orthocam = vec3(uv*3.,-5.);
        vec3 orthodir = vec3(0,0,1);

        vec3 cam = mix(orthocam, perspcam, abs(sin(spinVTime)));
        vec3 dir = mix(orthodir, perspdir, abs(sin(spinVTime)));

        cam.yz = rotate(cam.yz, sin(spinVTime)*.9);
        dir.yz = rotate(dir.yz, sin(spinVTime)*.9);

        cam.xz = rotate(cam.xz, spinHTime);
        dir.xz = rotate(dir.xz, spinHTime);

        state = dir.y > 0.;

        float t = 0.;
        for(int i=0;i<100;++i)
        {
            float k = scene(cam+dir*t);
            t+=k;
            if (k<.001)
                break;
        }
        vec3 h = cam+dir*t;
        vec2 o = vec2(.001,0);
        vec3 n = normalize(vec3(
            scene(h+o.xyy)-scene(h-o.xyy),
            scene(h+o.yxy)-scene(h-o.yxy),
            scene(h+o.yyx)-scene(h-o.yyx)
        ));

        float th = .05;
#ifdef CHROMA
        out_color[c] = smoothstep(-th, th, sin(tau*h.y-scrollTime));
#else
        out_color = vec4(smoothstep(-th, th, sin(tau*h.y-scrollTime)));
#endif

    glFragColor = out_color;
    }
}
