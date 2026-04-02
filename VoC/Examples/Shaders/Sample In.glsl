#version 420

// original https://www.shadertoy.com/view/Dt3BzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define rot(a) mat2(cos(a + vec4(0, 11, 33, 0)))
#define cor1 vec4(6, 3, 0, 0) / 40.
#define cor2 vec4(4, 0, 0, 0) / 40.

/*
    variações
    
    https://www.shadertoy.com/view/cdjBDK
    https://www.shadertoy.com/view/ddycDd
    https://www.shadertoy.com/view/ddBBRz
    https://www.shadertoy.com/view/DlXfzj
    https://www.shadertoy.com/view/cdjfDV
    https://www.shadertoy.com/view/clScDt
    https://www.shadertoy.com/view/dscBRr
    https://www.shadertoy.com/view/dsyfRD
    https://www.shadertoy.com/view/dlfyDS
    https://www.shadertoy.com/view/DlffD4
    https://www.shadertoy.com/view/DttcWl
    https://www.shadertoy.com/view/mt2cWm
    https://www.shadertoy.com/view/DsVfzd
    https://www.shadertoy.com/view/dtKfDh
    https://www.shadertoy.com/view/DdKBRw
    https://www.shadertoy.com/view/DlXyD2

*/

const float freqA = .3;
const float freqB = .2;
const float ampA = 2.;
const float ampB = 3.;
float id;

vec2 path(in float z) {
    return vec2(
        ampA * sin(z * freqA), 
        ampB * cos(z * freqB)
    );
}

vec2 path2(in float z) {
    return vec2(
        ampB * sin(z * freqB * .2), 
        ampA * cos(z * freqA * .8)
    );
}

float textura(vec3 p) {
    float dd, d = 0., a = 1.;
    p.xy *= rot(p.z * .3);
    while(a < 4.)
        d += dot(sin(p * a * 1.9) * .2, p / p) / a,
        d += (cos(time * 1.5 + p.z) * .5 + .5) 
              * length((1.5 * cos(p * a * 5.) * .1)) / a,
        a += a;
    return d;
}

float map(vec3 p) {
    vec2 t1 = p.xy - path(p.z);
    vec2 t2 = p.xy - path2(p.z);
    //id = step(length(t2), length(t1));
    id = 1.-length(cross(vec3(t2, 0),vec3(t1, 0)));
    return 1.5 - min(length(t1), length(t2)) + textura(p);
}

void main(void) {
    vec4 o =vec4(0.0);
    vec2 u = gl_FragCoord.xy;
    
    vec3 col, p, lookAt, fw, rt, up, rd;
    float s = 1., d, i, t = time * 2.; 
    
    u = (u + u - R) / R.y;

    lookAt.z  = t;
    lookAt.xy = path(lookAt.z);
    
    p.z  = t - .1;
    p.xy = path(p.z);

    fw = normalize(lookAt - p);
    rt = vec3(fw.z, 0., -fw.x);
    up = cross(fw, rt);
    rd = fw + (u.x * rt + u.y * up) / 2.6;
    
    while(i++ < 99. && s > .001)
        s = map(p) * .5, 
        p += s * rd;

    o = id > .5 ? cor1 : cor2;
    o += 3. / i;
    
    glFragColor = o;
}