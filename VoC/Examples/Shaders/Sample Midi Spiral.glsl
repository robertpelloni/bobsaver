#version 420

// original https://www.shadertoy.com/view/WsXSD4

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

float sdfCyl(vec3 p, float r, float l)
{
    return length(p-vec3(0., clamp(p.y, -l, l), 0.)) - r;
}

float sdfTorus(vec3 p, float r, float w)
{
    return sqrt(pow(length(p.xz)-r, 2.) + pow(p.y, 2.)) - w;
}

vec2 merge(vec2 a, vec2 b)
{
    return a.x < b.x ? a : b;
}

vec2 map(vec3 p)
{
    //p.xz *= rot(sin(time));
    //p.yz *= rot(time);
    //p.z -= time;
    //p.y += sin(time*.25)*.1;
    //p.xy *= rot(time*.02);
    p.xy *= rot(p.z*.02*sin(time));
    p = mod(p+vec3(5.), 10.)-vec3(5.);
    
    
    
    
    vec3 wkp = p;
    wkp.x += .1;
    wkp.x = mod(wkp.x+.21, .41)-.21;
    float wkeys = max(max(sdfBox(wkp, vec3(.2, .15, .85)), -sdfBox(wkp-vec3(0., -.05, 1.), vec3(.25, .15, .5))), sdfBox(p-vec3(0.25, 0., 0.), vec3(3.)));
    
    vec3 bkp = p;
    bkp.yz *= rot(-.09);
    bkp.x -= -.2;
    bkp.x = mod(bkp.x-.16, .41)+.16;
    
    float bkeys = sdfBox(bkp-vec3(.3, .2, -.2), vec3(.1, .1, .6));
    vec3 bhp = p;
    bhp.x -= 1.;
    bhp.x = mod(bhp.x-.16, 2.9)+.16;
    float bholes = sdfBox(bhp-vec3(.3, .2, -.2), vec3(.17, .17, .65));
    bhp = p;
    bhp.x -= 2.7;
    bhp.x = mod(bhp.x-.16, 2.9)+.16;
    float bholes2 = sdfBox(bhp-vec3(.3, .2, -.2), vec3(.17, .17, .65));
    bkeys = max(max(max(bkeys, -bholes), -bholes2), sdfBox(p-vec3(0.25, 0., 0.), vec3(3.)));
    //float keys = min(wkeys, bkeys)*.5, sdfBox(p-vec3(0.25, 0., 0.), vec3(3.)));
    
    // Body
    float body = max(sdfBox(p-vec3(0.25, -.1, -.9), vec3(3.1, .25, 1.75)), -sdfBox(p-vec3(.25, 0., 0.), vec3(3., .25, .9)));
    
    // Pads
    vec3 pp = p;
    pp.xz -= vec2(.6, -.1);
    pp.xz = mod(pp.xz+vec2(.15), .73)-vec2(.15);
    float pads = max(sdfBox(pp-vec3(0., .11, 0.), vec3(.45, .08, .45)), sdfBox(p-vec3(-.3, 0., -1.8), vec3(1.4, 1., .7)));
    
    // Knobs
    vec3 kp = p;
    kp.xz = mod(pp.xz+vec2(.2), .4)-vec2(.2);
    float knobs = max(max(max(sdfCyl(kp-vec3(0., 0.2, 0.), .2, .1), sdfBox(p-vec3(2.3, 0., -2.1), vec3(.75, 1., .35))), -sdfTorus(kp-vec3(0., .3, 0.), .35, .25)), +(p.y-.3));
    
    return merge(merge(merge(merge(vec2(wkeys, 0.), vec2(bkeys, 1.)), vec2(body, 2.)), vec2(pads, 0.)), vec2(knobs, 1.));
}

vec2 march(vec3 ro, vec3 rd)
{
    vec2 t = vec2(0.);
    for(int i=0; i<228; ++i) {
        vec2 d = map(ro+rd*t.x);
        if(d.x < .0001) break;
        t.x += d.x;
        t.y = d.y;
    }
    return t;
}

vec3 getNormal(vec3 p)
{
    vec2 eps = vec2(.0001, 0.);
    return normalize(vec3(
        map(p+eps.xyy).x - map(p-eps.xyy).x,
        map(p+eps.yxy).x - map(p-eps.yxy).x,
        map(p+eps.yyx).x - map(p-eps.yyx).x
    ));
}

float getAo(vec3 p, vec3 normal)
{
    float t = 0.;
    p += normal*.002;
    for(int i=0; i<228; ++i) {
        vec2 d = map(p+normal*t);
        if(d.x < .001) break;
        t += d.x;
    }
    return clamp(t, 0., 1.);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;

    vec3 cam = vec3(2., 1.5, 2);
    vec3 dir = normalize(vec3(uv, -1));
    dir.yz *= rot(.3);
    dir.xz *= rot(.3);
    vec2 res = march(cam, dir);
    vec3 col = vec3(.05, .2, .1);
    
    if(res.x < 100.) {
        vec3 p = cam+dir*res.x;
        vec3 normal = getNormal(p);
        float ao = getAo(p, normal);
        float light1 =  max(0., dot(normal, normalize(vec3(1.))));
        float light2 =  max(0., dot(normal, normalize(vec3(-1., 1., 1.))));
        float fresnel = pow(1.-max(0., dot(normal, -dir)), 10.);
        
        if(res.y == 0.) {
            // While Keys
            col = vec3(.5) * light1;
            col += vec3(.5, .5, .45) * light2;
            //col += fresnel;
        } else if(res.y == 1.) {
            // Black keys
            col = vec3(.01) * light1;
            col += vec3(.01) * light2;
            col += vec3(1.) * fresnel;
        } else if(res.y == 2.) {
            // Body
            col = vec3(.01) * light1;
            col += vec3(.01) * light2;
        }
        col = mix(col, vec3(.1, .3, .09), clamp(sqrt(res.x/100.), 0., 1.));
    }
    col = pow(col, vec3(1.5, 1., .5));

    // Output to screen
    glFragColor = vec4(pow(col, vec3(1./2.2)),1.0);
}
