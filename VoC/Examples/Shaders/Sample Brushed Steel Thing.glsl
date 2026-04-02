#version 420

// original https://www.shadertoy.com/view/ts23RG

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

vec2 rotate(vec2 p, float a)
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, s, -s, c) * p;
}

float cube(vec3 p, vec3 d)
{
    p = abs(p);
    float s = length(p) - .7;
    s = max(s, p.x-d.x);
    s = max(s, p.y-d.y);
    s = max(s, p.z-d.z);
    
    return s;
}

float caps(vec3 p, float l, float w)
{
    return length(vec3(0., p.y, 0.)-vec3(p.x, clamp(p.y, -1., 1.), p.z)) - w;
}

float sphere(vec3 p, float r)
{
    return length(p) - r;
}

float map(vec3 p)
{
    p.xz = rotate(p.xz, time);
    p.yz = rotate(p.yz, time);
    
    //p = mod(p+vec3(2.5), 5.)-vec3(2.5);
    float c = cube(p, vec3(.5));
    float s = sphere(p, 1.);
    
    float h = sphere(p-vec3(.7, 0., 0.), .55);
    float h2 = sphere(p-vec3(-.7, 0., 0.), .55);
    float h3 = sphere(p-vec3(0., .7, 0.), .55);
    float h4 = sphere(p-vec3(0., -.7, 0.), .55);
    float h5 = sphere(p-vec3(0., 0., .7), .55);
    float h6 = sphere(p-vec3(0., 0., -.7), .55);
    
    vec3 p2 = mod(p+vec3(.1), .5)-vec3(.1);
    float c1 = caps(p2, .1, .1);
    float c2 = caps(p2.yzx, .1, .1);
    float c3 = caps(p2.zxy, .1, .1);
    
    vec3 p3 = mod(p+vec3(.2), .38)-vec3(.2);
    float s2 = sphere(p3, .1);
    
    vec3 p4 = mod(p+vec3(.025), .18)-vec3(.025);
    float s3 = sphere(p4, .05);
    
    float d = mix(c, s, .4);
    d = max(d, -h);
    d = max(d, -h2);
    d = max(d, -h3);
    d = max(d, -h4);
    d = max(d, -h5);
    d = max(d, -h6);
    
    d = max(d, -c1);
    d = max(d, -c2);
    d = max(d, -c3);
    
    d = max(d, -s2);
    d = mix(d, -s3, .03);
    d = mix(d, s, .01);
    
    d += perlin(p.yy*20.)*.0003;
    
    return d;
}

vec3 getNormal(vec3 p)
{
    return normalize(vec3(
        map(p+vec3(0.001, 0., 0.)) - map(p-vec3(0.001, 0., 0.)),
        map(p+vec3(0., 0.001, 0.)) - map(p-vec3(0., 0.001, 0.)),
        map(p+vec3(0., 0., 0.001)) - map(p-vec3(0., 0., 0.001))
    ));
}

float march(vec3 ro, vec3 rd)
{
    float t=0.;
    for(int i=0; i<128; ++i) {
        float d = map(ro+t*rd);
        if(d < .001) break;
        t += d;
    }
    return t;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(.5);
    uv.x *= resolution.x/resolution.y;

    vec3 eye = vec3(0., 0., abs(sin(time*.4))*2. + .5);
    vec3 lookat = normalize(vec3(uv.x, uv.y, -1.));
    
    
    eye.xz = rotate(eye.xz, sin(time)*.5);
    eye.yz = rotate(eye.yz, sin(time)*.5);
    lookat.xz = rotate(lookat.xz, sin(time)*.5);
    lookat.yz = rotate(lookat.yz, sin(time)*.5);
    
    
    float d = march(eye, lookat);
    vec3 normal = getNormal(eye+d*lookat);
    vec3 col = vec3(.8, .7, 1.) * clamp(dot(normal, vec3(0., 1., 0.)), 0., 1.);
    col += vec3(1., .7, .8) * clamp(dot(normal, vec3(-1., 0., -1.)), 0., 1.);
    col += vec3(.2*d);
    
    col = vec3(.5, .5, .5) * col * d * .2;
    col += vec3(.5) * pow(clamp(dot(normal, -lookat), 0., 1.), 5.);
    col += vec3(1., .5, .5) * pow(clamp(dot(normal, -lookat), 0., 1.), 50.);
    
    if(d>20.) col = vec3(0.);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
