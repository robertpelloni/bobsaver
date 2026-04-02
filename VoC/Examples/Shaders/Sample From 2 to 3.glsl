#version 420

// original https://www.shadertoy.com/view/wlfXWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void twod()
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    float expand = sin(time*.25)*0.5 - .5;
    //float expand = sin(126.59*.25)*0.5 - .5;
    uv -= -smoothstep(-1., 0., expand);
    vec2 o = vec2(10000.);
    for(float i = 0.; i < 5.; i++) {
        uv -= smoothstep(-1., 0., expand);
        float a = .3 + .5/length(uv) + time * .125;
        uv *= mat2(cos(a), sin(a), -sin(a), cos(a));
        uv = abs(uv) * 1.3;
        o = min(o, vec2(length(uv - 1.), length(uv - vec2(0., 1.))));
    }
    //float d = length(uv) - 1.;
    glFragColor = vec4((o.yyx + o.yxx)*.5, 1.);
}

vec4 sdf( vec3 p )
{
    vec3 uv = p;
    //float expand = sin(time*.25)*0.5 - .5;
    float expand = sin(126.59*.25)*0.5 - .5;
    uv -= -smoothstep(-1., 0., expand);
    vec2 o = vec2(10000.);
    for(float i = 0.; i < 7.; i++) {
        uv -= smoothstep(-1., 0., expand);
        float a = .3 + .5/length(uv) + (time * 1.) * .125;
        uv.xy *= mat2(cos(a), sin(a), -sin(a), cos(a));
        uv = abs(uv) * 1.3;
        o = min(o, vec2(length(uv - 1.), length(uv - vec3(0., 1., 0.))));
    }
    float d = length(uv) - 1.2;
    return vec4(d, (o.yyx + o.yxx)*.5);
}

vec3 normal(vec3 p) {
    vec2 eps = vec2(0., .005);
    float dx = sdf(p + eps.yxx).x - sdf(p - eps.yxx).x;
    float dy = sdf(p + eps.xyx).x - sdf(p - eps.xyx).x;
    float dz = sdf(p + eps.xxy).x - sdf(p - eps.xxy).x;
    return normalize(vec3(dx, dy, dz));
}

vec3 trace(vec3 camPos, vec3 dir, out vec3 p) {
    float i = 0.;
    float t = 0.03;
    vec3 orb = vec3(0.);
    for (; i < 300.; i++) {
        p = t * dir + camPos;
        vec4 d = sdf(p);
            orb = d.yzw;
        if (abs(d.x) < 0.05 * t) {
            break;
        }
        t += abs(d.x) * .01;
        if (t > 100.)
            break;
    }
    
    return orb * (.2 + .2 * t + i / 100. * max(0.2, (1.-t)));
}

void threed()
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 camPos = vec3(-0.065 + sin(time * .3) * .1, -0.75, -.4 + sin(time * .1) * 1.5);
    vec3 dir = normalize(vec3(uv, 1. / tan(radians(60.) * .5)));
    float a = time * .1;
    dir.xz *= mat2(cos(a), sin(a), -sin(a), cos(a));
    
    bool hit = false;
    vec3 p = vec3(0.);
    vec3 orb = trace(camPos, dir, p);
    vec3 n = normal(p);
    orb *= .8+.5*trace(p, reflect(dir, n), p) * orb.b * pow(1.-abs(dot(n, -dir)), orb.r);
    
    glFragColor = vec4(orb, 1.);
}

void main(void) {
    float x = 0.0;//mouse*resolution.xy.x / resolution.x;
    x = x == 0. ? step(time, 6.28) * sin(time) * .5 + .5 : x;
    if (gl_FragCoord.x / resolution.x < x)
        twod();
    else
        threed();
    
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.xy;
    uv = pow(abs(uv), vec2(3.));
    glFragColor *= clamp(1.5-sqrt(uv.x + uv.y), 0., 1.);
}
