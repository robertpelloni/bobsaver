#version 420

// original https://www.shadertoy.com/view/3dXSzM

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

float field(vec3 p)
{
    p.x -= 2.;
    p.y += sin(p.z*.2+time)*2.;
    p.y += cos(p.x*.2-time)*2.;
    p.z += time;
    p.xz = mod(p.xz+vec2(2.), 4.)-vec2(2.);
    vec3 bp = abs(p) - 1.;
    return min(max(max(bp.x, bp.y), bp.z), p.y+.9);
}

float march(vec3 ro, vec3 rd)
{
    float t = 0.;
    for(int i=0; i<228; ++i) {
        float d = field(ro+rd*t);
        if(d < .0001 || d > 200.) break;
        t += d*.5;
    }
    return t;
}

vec3 getNormal(vec3 p)
{
    vec2 eps = vec2(3.*pow(length(p), .001), 0.);
    return normalize(vec3(
        field(p+eps.xyy) - field(p-eps.xyy),
        field(p+eps.yxy) - field(p-eps.yxy),
        field(p+eps.yyx) - field(p-eps.yyx)
    ));
}

float getSss(vec3 ro, vec3 rd)
{
    float t = 0.;
    for(float i=0.; i<2.; i+=.1) {
        t += field(ro+rd*i);
    }
    return clamp(exp(t*.1), 0., 1.);
}

float getAo(vec3 ro, vec3 rd)
{
    float t = 0.;
    ro += rd*.002;
    int i;
    for(i=0; i<64; ++i) {
        float d = field(ro+rd*t);
        if(d < .001 || d > 100.) break;
        t += d;
    }
    return float(i);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;

    vec3 cam = vec3(0, 2, 6);
    vec3 dir = normalize(vec3(uv, -1));
    dir.yz *= rot(.2);
    cam.z -= time*5.;
    dir.xz *= rot(time*.1);
    float d = march(cam, dir);
    vec3 col = vec3(0.);
    if(abs(uv.y) < .85) {
        col = vec3(.2, .06, .1) * uv.y+.25;

        if(d < 100.) {
            vec3 p = cam+dir*d;
            vec3 normal = getNormal(p);
            col += vec3(.5, .2, .2) * (pow(1.-max(0., dot(normal, -dir)), .6));
            col = vec3(1.)-pow(col, vec3(.1));
            float ss = getSss(p, dir);
            col += .2*vec3(pow(ss, .5));
            float ao = getAo(p, normal);
            col *= vec3(1.-ao/428.);
            col += .5*vec3(.3, .2, .4) * (pow(max(0., dot(normal, normalize(vec3(-2., 2., 2.)))), 2.));
            col += .5*vec3(1., .1, .3) * (pow(max(0., dot(normal, normalize(vec3(-2., 2., -2.)))), 2.));
            col = mix(col, vec3(.27, .24, .25), d/100.);
        }
        col = pow(col, vec3(2));
    }

    // Output to screen
    col *= 1.-length(uv)*.4;
    glFragColor = vec4(pow(col, vec3(1./2.2)),1.0);
}
