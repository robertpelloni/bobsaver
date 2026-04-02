#version 420

// original https://www.shadertoy.com/view/wssSR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

float sdfBox(vec3 p, vec3 d)
{
    p = abs(p) - d;
    return max(max(p.x, p.y), p.z);
}

float sdfTorus(vec3 p, float r, float w)
{
    return sqrt(pow(length(p.xz)-r, 2.) + pow(p.y, 2.)) - w;
}

float sdfCap(vec3 p, float r, float l)
{
    return length(p - vec3(0., clamp(p.y, -l, l), 0.)) - r;
}

float sdfSphere(vec3 p, float r)
{
    return length(p) - r;
}

float field(vec3 p)
{
    
    p.xz *= rot(time*.1);
    p.yz *= rot(-.7);
    p.xz *= rot(dot(p, normalize(vec3(1., 5., -1.)))*.02);
    p.xz = mod(p.xz+vec2(4.), 8.)-vec2(4.);
    p.y += sin(time)*.5+.5;
    p.xz *= sin(time+p.y)*.01*length(p)+1.;
    
    p.x += sin(p.y+time*2.)*.2;
    p.y += time*.5;
    p.xz /= abs(sin(p.y-time))*1.1+.3;
    p.y = mod(p.y+.5, 1.)-.5;
    
    
    float c = sdfCap(p, .65, 1.);
    float s = sdfSphere(p, .79);
    float s2 = sdfSphere(p, .75);
    float s3 = sdfSphere(abs(p)-vec3(0, 1., 0), .8);
    float t = sdfTorus(p, .9, .35);
    float c2 = sdfCap(p, .5, 1.);
    vec3 pp = abs(p.xzy);
    pp.xy *= rot(.75);
    float t2 = sdfTorus(pp-vec3(.8, 0., 0.), .3, .1);
    pp.xy *= rot(-.5);
    float t3 = sdfTorus(pp-vec3(.8, 0., 0.), .3, .1);
    pp.xy *= rot(1.05);
    float t4 = sdfTorus(pp-vec3(.8, 0., 0.), .3, .1);
    float b = sdfBox(p, vec3(.6));
    return max(max(max(max(max(max(max(min(max(c, s), s2), -s3), -t), -c2), -t2), -t3), -t4), b)*.2;
}

float march(vec3 ro, vec3 rd)
{
    float t = 0.;
    for(int i=0; i<228; ++i) {
        float d = field(ro+rd*t);
        if(d < .001) break;
        t += d;
    }
    return t;
}

vec3 getNormal(vec3 p)
{
    vec2 eps = vec2(.1, 0.);
    return normalize(vec3(
        field(p+eps.xyy) - field(p-eps.xyy),
        field(p+eps.yxy) - field(p-eps.yxy),
        field(p+eps.yyx) - field(p-eps.yyx)
    ));
    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy) / resolution.y;
    // Time varying pixel color
    vec3 cam = vec3(0, 0, 4);
    vec3 dir = normalize(vec3(uv, -1));
    float d = march(cam, dir);
    vec3 p = cam+dir*d;
    vec3 col = vec3(0., .1, .2);
    
    if(d < 50.) {
        vec3 normal = getNormal(p);
        col = vec3(.5, .2, .1) * max(0., dot(normal,  normalize(vec3(1.))));
        col += vec3(.1, .4, .1) * max(0., dot(normal,  normalize(vec3(-1., .1, -1.))));
        col *= vec3(.3, .7, .1) * (1.-pow(max(0., dot(normal, -dir)), 1.));
        col *= 2.+.5;
    }
    col = pow(col, vec3(.8)) + .03;
    col *= vec3(.3, .6, .5) * 1.-(d/50.);

    // Output to screen
    glFragColor = vec4(sqrt(col),1.0);
}
