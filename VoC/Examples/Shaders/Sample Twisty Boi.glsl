#version 420

// original https://www.shadertoy.com/view/wsSGWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * I recreated Andy Duboc's first everyday since he inspired me to start 
 * doing everydays myself.
 * https://twitter.com/andyduboc/status/1080266860346703872
 */

float torus(vec3 p, float r, float w)
{
    return sqrt(pow(length(p.xz)-r, 2.) + pow(p.y, 2.)) - w;
}

vec2 rotate(vec2 p, float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c) * p;
}

float map(vec3 p)
{
    p.xz = rotate(p.xz, -5.*sin(time)*dot(p, vec3(0., 1., 0.)));
    return torus(p.yzx, .5, .3);
}

float march(vec3 ro, vec3 rd)
{
    float t = 0.;
    for(int i=0; i<128; ++i) {
        float d = map(ro+t*rd);
        if(d < .001) break;
        if(t > 100.) return -1.;
        t += d*.4;
    }
    return t;
}

vec3 getNormal(vec3 p)
{
    return normalize(vec3(
        map(p+vec3(.0001, .0, .0)) - map(p-vec3(.0001, .0, .0)),
        map(p+vec3(.0, .0001, .0)) - map(p-vec3(.0, .0001, .0)),
        map(p+vec3(.0, .0, .0001)) - map(p-vec3(.0, .0, .0001))
    ));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(.5);
    uv.x *= resolution.x/resolution.y;
    
    vec3 eye = vec3(0., 0., 2.);
    vec3 lookat = normalize(vec3(uv.x, uv.y, -1.));
    float d = march(eye, lookat);
    
    vec3 col;
    
    if(d < 0.) {
        col = vec3(.83);
    } else {
        vec3 normal = getNormal(eye+lookat*d);
        vec3 light1Pos = vec3(1., 1., 1.);
        vec3 light2Pos = vec3(-1., -1., -1.);
        col = .8 * vec3(1., .7, .5) * clamp(dot(normal, light1Pos), 0., 1.);
        col += .2 * vec3(.5, .9, 1.) * clamp(dot(normal, light2Pos), 0., 1.);
        col += .2* vec3(1., .7, .5);
        col += .4 * vec3(.5, .7, 1.) * (1.-clamp(dot(-lookat, normal), 0., 1.));
           col += pow(.1, 17.)*vec3(pow(abs(dot(light2Pos, normal)), 70.));
    }
    
    glFragColor = vec4(pow(col, vec3(1./2.2)),1.0);
}
