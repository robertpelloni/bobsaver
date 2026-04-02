#version 420

// original https://www.shadertoy.com/view/3sj3DW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(vec2 p) {
    return fract(sin(dot(p, vec2(123.3345, 876.654))) * 984594.2343);
}

float perlin(vec2 p){
    p *= 10.;
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float bl = random(i);
    float br = random(i + vec2(1, 0));
    float tl = random(i + vec2(0, 1));
    float tr = random(i + vec2(1, 1));
    
    float x = mix(bl, br, smoothstep(0., 1., f.x));
    float y = mix(tl, tr, smoothstep(0., 1., f.x));
    return mix(x, y, smoothstep(0., 1., f.y));
}

float sdfSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdfDough(vec3 p, float r, float w)
{
    float d = sqrt(pow(length(p.xz)-r, 2.) + pow(p.y, 2.)) - w - pow(perlin(p.xz), .1)*.05;
    
    return d;
}

float sdfTorus(vec3 p, float r, float w)
{
    float d = sqrt(pow(length(p.xz)-r, 2.) + pow(p.y, 2.)) - w - perlin(p.yz)*.07;
    
    return d;
}

float sdfCapsule(vec3 p, float r)
{
    return length(p-vec3(0., clamp(p.y, 0.5, 1.), 0.)) - r;
}

vec2 rotate(vec2 p, float a)
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, s, -s, c) * p;
}

vec2 opMin(vec2 a, vec2 b)
{
    return (a.x<b.x) ? a : b;
}

vec2 map(vec3 p)
{
    p.z -= time*4.;
    
    p.y += 4.;
    
    p = mod(p+vec3(5.), 10.)-vec3(5.);
    p.yz = rotate(p.yz, time*2.);
    p.xy = rotate(p.xy, time*2.);
    p.x += smoothstep(0., 1., abs(sin(time)));
    

    vec2 dough = vec2(sdfDough(p, 1., .6), 0.);
    
    vec3 fp = p;
    fp.y -= .08;
    vec2 frost = vec2(sdfTorus(fp, 1., .6), 1.);
    
    vec3 flp = p;
    flp.xz = abs(flp.xz);
    flp.xy = rotate(flp.xy, 1.3);
    flp *= 4. ;
    flp = mod(flp+vec3(20.), 200.)-vec3(10.);
    vec2 fl1 = vec2(sdfCapsule(flp, .1), 2.);
    
    vec2 res = opMin(dough, frost);
    return res;
}

vec3 march(vec3 o, vec3 dir)
{
    float d = 0.;
    vec2 res;
    int i;
    vec3 p;
    for(i=0; i<328; ++i)
    {
        p = o + d*dir;
        res = map(p);
        if(res.x < .0001) break;
        if(d > 120.) return vec3(-1.);
        d += res.x;
    }
    return vec3(d, res.y, i);
}

vec3 getNormal(vec3 p)
{
    return normalize(vec3(
        map(p+vec3(0.0001, 0., 0.)).x - map(p-vec3(0.0001, 0., 0.)).x,
        map(p+vec3(0., 0.0001, 0.)).x - map(p-vec3(0., 0.0001, 0.)).x,
        map(p+vec3(0., 0., 0.0001)).x - map(p-vec3(0., 0., 0.0002)).x
    ));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(.5);
    uv.x *= resolution.x/resolution.y;
    
    vec3 eye = vec3(0., 0., 5.);
    vec3 target = normalize(vec3(uv.x, uv.y, -1.));
    vec3 res = march(eye, target);
    
    vec3 col;
    
    if(res.y < 0.) {
        col = vec3(0.);
    } else if(res.y == 0.) {
        vec3 light1 = normalize(vec3(1., 0., -1.));
        vec3 light2 = normalize(vec3(-1., 1, -1.));
        vec3 light3 = normalize(vec3(-1., -1, -1.));
        vec3 normal = getNormal(eye+target*res.x);
        col = .5+.5*vec3(normal.z);
        col *= vec3(.85 ,.73, .52);
    } else if(res.y >= 1.) {
        
        vec3 c = vec3(.9, 0.2, 0.2);
        if(res.y == 2.){ c = vec3(.2, .9, 0.2); }
        
        vec3 lightPos = normalize(vec3(1., 0., -1.));
        vec3 normal = getNormal(eye+target*res.x);
        col = vec3(.6) * clamp(dot(normal, lightPos), 0., 1.);
        col += c;
        col += .1+.3*normal.y;
        col += .004*vec3(pow(clamp(dot(normal, lightPos), 0., 1.), 12.));
        col += .3 * pow(clamp(dot(normal, lightPos), 0. ,8.), .8);
        col += .4 * pow(col, vec3(2.));
    }
    
    if(res.y >= 0.) {
        col = mix(col, vec3(0.), smoothstep(0., 1., res.x*.016));
    }
    
    col *= pow(dot(target, vec3(0., 0. ,-1.)), 5.);
    col = sqrt(col);
    glFragColor = vec4(col,1.0);
}
