#version 420

// original https://www.shadertoy.com/view/llVyz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Anti-Aliasing. Pointless with artefacts due to stepsize being too large.
// "aa 1." is off 
// "aa 2." is on 
#define aa 1.

// taken from: https://www.iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// taken from: https://www.shadertoy.com/view/4djSRW
//#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE3 vec3(443.897, 441.423, 437.195)
vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);

}
//#define HASHSCALE1 .1031
#define HASHSCALE1 443.8975
float hash13(vec3 p3)
{
    p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 vnoise(vec2 v, float s) {
    vec2 g = v / s;
    g = floor(g) * s;
    vec2 ld = hash22(g);
    vec2 rd = hash22(g + vec2(s, 0.));
    vec2 lu = hash22(g + vec2(0., s));
    vec2 ru = hash22(g + s);
    g = fract(v / s);
    g = smoothstep(0., 1., g);
    return mix(mix(ld, rd, g.x), mix(lu, ru, g.x), g.y);
}

vec2 fbm(vec2 v) {
    float t = 0.;
    vec2 n = vec2(0.);
    for (float s = 1.; s > 0.02; s *= 0.5) {
        t += s;
        n += vnoise(v, s) * s;
    }
    return n / t;
}

float primitive(vec3 p, float r) {
    vec3 a = abs(p) - r * .75;
    return smin(max(a.x, max(a.y, a.z)), length(p) - r, .1);
}

vec2 sdf(vec3 p) {
    p -= vec3(1.3, 5.6, 2.0);
    
    vec2 obj = vec2(10000., -1.);
    for (float i = 0.; i < 7.; i++) {
        p = abs(p);
        p -= vec3(1.7, 1.75, 2.781);
        float a = 4.9 - length(p) * 0.2;
        p.xy = mat2(cos(a), sin(a), -sin(a), cos(a)) * p.xy;
        a = 1. + dot(p, p) * .005;
        p.yz = mat2(cos(a), sin(a), -sin(a), cos(a)) * p.yz;
        
        float d = primitive(p, 6.2 / (9.3 - i));
        obj = vec2(smin(d, obj.x, .2), mix(i, obj.y, clamp(d / obj.x, 0., 1.)));
    }
    
    return obj;
}

vec3 gradient(vec3 p) {
    vec2 eps = vec2(0.02, 0.);
    float dx = sdf(p + eps.xyy).x - sdf(p - eps.xyy).x;
    float dy = sdf(p + eps.yxy).x - sdf(p - eps.yxy).x;
    float dz = sdf(p + eps.yyx).x - sdf(p - eps.yyx).x;
    return normalize(vec3(dx, dy, dz));
}

bool trace(vec3 pos, vec3 dir, out vec3 p, out float i, out float t, out vec2 obj) {
    t = 0.;
    for(i = 0.; i < 400.; i++) {
        p = t * dir + pos;
        obj = sdf(p);
        if (abs(obj.x) < 0.005 * t)
            return true;
        t += obj.x * .25;
        if (t > 100.)
            break;
    }
    return false;
}

float ambientOcclusion(vec3 p, vec3 n, float steps, float dist) {
    float ao = 0.;
    for (float i = 1.; i <= steps; i++) {
        float t = i / steps * dist;
        ao += sdf(p + n * t).x / t;
    }
    return clamp(ao / steps, 0., 1.);
}

float translucency(vec3 p, vec3 n, float steps, float dist) {
    float ao = 0.;
    for (float i = 1.; i <= steps; i++) {
        float t = i / steps * dist;
        ao += -sdf(p - n * t).x / t;
    }
    return 1. - clamp(ao / steps, 0., 1.);
}

vec3 draw(vec3 p, vec3 dir, float i, float t, vec2 obj, vec2 uv) {
    vec3 normal = gradient(p);
    vec3 lightDir = normalize(vec3(cos(1.), 1., sin(1.)));
    float diffuse = max(0., dot(lightDir, normal)) * .4;
    float specular = pow(max(0., dot(normalize(lightDir - dir), normal)), 16.) * .8 * obj.y / 7.;
    float rim = pow(1. - abs(dot(normal, -dir)), 5.) * .5;
    float ao = ambientOcclusion(p, normal, 3., .3);
    float trans = translucency(p, normal, 3., .3) * .5 * smoothstep(1., .2, obj.y / 10.);
    vec3 lighting = trans * vec3(1., 0.7, 0.) 
        + ao * .15 + 
        diffuse * vec3(1., 1., 0.) + 
        + (rim + specular) * vec3(0., 1., .8);
    vec3 col = vec3(1. - t / 30., .5 - t / 60., smoothstep(0.2, 1., obj.y / 5.));
    vec2 s = uv + fbm(vec2(i / 350., t / 30.));
    vec2 h = fbm(s - time * .15);
    h = fbm(s + h - .5 + time * .01);
    h = fbm(s + h - .5);
    return clamp(col * lighting + i / 70. * (h.x) * vec3(1., 0.7, 0.), 0., 1.);
}

vec3 reflection(vec3 pos, vec3 dir, vec3 normal, vec2 uv) {
    dir = reflect(dir, normal);
    float i, t;
    vec2 obj;
    vec3 p;
    bool hit = trace(pos + dir * .05, dir, p, i, t, obj);
    return hit ? draw(p, dir, i, t, obj, uv) : vec3(0.);
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 c = vec3(0.);
    for (float k = 0.; k < aa; k++) {
        for (float l = 0.; l < aa; l++) {
            vec3 dir = normalize(vec3(uv + vec2(l, k) / aa / resolution.y, 1. / tan(radians(60.) * .5)));
            
            float a = time * .1 -10.;
            
            vec3 camPos = vec3(0., 0., sin(a) * 4.);
            
            dir.xz = mat2(cos(a), sin(a), -sin(a), cos(a)) * dir.xz;

            float i, t;
            vec2 obj;
            vec3 p;
            bool hit = trace(camPos, dir, p, i, t, obj);
            vec3 col = hit ? draw(p, dir, i, t, obj, uv) : vec3(0.);
            vec3 normal = gradient(p);
            vec3 r = reflection(p, dir, normal, uv);
            c += mix(col * (1. + r * .5), col, 1. - pow(abs(dot(normal, -dir)), 5.));
        }
    }
    
    
    glFragColor = vec4(c / (aa * aa), 1.);
}
