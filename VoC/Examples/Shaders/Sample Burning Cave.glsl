#version 420

// original https://www.shadertoy.com/view/sl3yz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NOISE_FIRE

#define SPHERE_ID 2.
#define LIGHT_ID 3.

#define SPHERE_R 1.
#define LIGHT_R .2
#define EPS 1e-5

vec3 sunPos;

mat2 rotate2D(float r){
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float hash(float p){
    p = fract(p * 0.1234);
    p *= p + 34.3;
    return fract(p*p);
}
float hash21(vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * 1.013);
    p3 += dot(p3, p3.yzx + 19.19) * 13.7;
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.43);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

//https://www.shadertoy.com/view/lsf3RH
float snoise(vec3 uv, float res){
    const vec3 s = vec3(1e0, 1e2, 1e3);
    
    uv *= res;

    vec3 uv0 = floor(mod(uv, res))*s;
    vec3 uv1 = floor(mod(uv+vec3(1.), res))*s;
    
    vec3 f = fract(uv); f = f*f*(3.0-2.0*f);

    vec4 v = vec4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z,
                    uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);

    vec4 r = fract(sin(v*1e-1)*1e3);
    float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
    
    r = fract(sin((v + uv1.z - uv0.z)*1e-1)*1e3);
    float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
    
    return mix(r0, r1, f.z)*2.-1.;
}

float sphere(vec3 p, float r){
    return length(p) - r;
}

float gyroid(vec3 p, float scale, float th){
    return (abs(dot(sin(p*scale), cos(p.yzx*scale))) - th)/scale;
}

vec2 upU(vec2 d1, vec2 d2) {
    return (d1.x < d2.x) ? d1: d2;
}

vec2 upAND(vec2 d1, vec2 d2) {
    return (d1.x > d2.x) ? d1: d2;
}

vec2 map(vec3 p){
    vec2 d,d2;
    vec3 q = p;

    d = vec2(gyroid(q, 1., .1)*.5, SPHERE_ID);

    q=p;
    q.y*=.5;
#ifdef NOISE_FIRE
    d2 = vec2(gyroid(q-snoise(q-time*.5,3.)*.3, 12., .03), SPHERE_ID);
#else
    d2 = vec2(gyroid(q-time*.5, 12., .03)*.8, SPHERE_ID);
#endif

    d = upAND(d, d2);

    d2 = vec2(sphere(p-sunPos, LIGHT_R*2.5), LIGHT_ID);
    d = upU(d, d2);

    return d;
}

vec3 calcNormal(vec3 p){
    vec2 h = vec2(EPS, 0.0);
    return normalize(vec3(map(p + h.xyy).x - map(p - h.xyy).x,
                        map(p + h.yxy).x - map(p - h.yxy).x,
                        map(p + h.yyx).x - map(p - h.yyx).x
        )); 
}

mat3 setCamera(vec3 ro, vec3 tg, float cr){
    vec3 cw = normalize(tg-ro);
    vec3 cu = normalize(cross(cw,vec3(sin(cr), cos(cr), 0.0)));
    vec3 cv = cross(cu,cw);
    return mat3(cu, cv, cw);
}

vec3 raymarch(vec3 ro, vec3 rd){
    float td = .1;
    vec2 d = vec2(100., -1.);
    vec3 p;

    vec3 col = vec3(0);

    for(int i=0;i<80;++i){
        p = ro + td * rd;
        col.r += .02 / exp((length(p-sunPos) - LIGHT_R)*.1);
        col.rg += .02 / exp((length(p-sunPos) - LIGHT_R));

        d = map(p);

        if(abs(d.x) < EPS || abs(d.x) > 30.){
            break;
        }
            
        td += d.x * .3;
    }
    
    p = ro + td * rd;

    if(d.y == SPHERE_ID) {
        vec3 nor = calcNormal(p);
        float diff = clamp(dot(sunPos-p, nor), 0.1, 1.0);

        col.rg += (sin((p.z-sunPos.z)*10.+p.x*10.+p.y*10.)+1.)*diff*vec2(1,.4);
        col.rg *= (.7 + .3*snoise(sin(p-sunPos)+sin(time), 15.));
    }
    else if(d.y == LIGHT_ID){
        col *= vec3(1,.3,0) / exp(d.x) * (.5 + .4*snoise(sin(p)+sin(time)*.05, 30.));
    }
    
    col.rgb *= 5. / exp(length((p-sunPos)) * vec3(1,.7,0) + .05);

    return col;
}

vec2 path_xy(float z){
    return vec2(-1.5-sin(z)*1.41, -cos(z)*.71);
}

void main(void)
{

    float t = time;
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;
    
    vec2 uv = 2.0 * (gl_FragCoord.xy - 0.5 * resolution.xy) / min(resolution.y, resolution.x);
    vec3 col = vec3(0), col2 = vec3(0);
    

    
    vec3 ro, tg;

    sunPos = vec3(path_xy(t),t);

    float roz = -3.2+t;
    vec2 roxy = path_xy(roz);
    ro = vec3(
        roxy,
        roz
    );
    tg = vec3(path_xy(-2.+t),t);
    //tg = vec3(0,0,t);

    mat3 ca = setCamera(ro, tg, 0.);
    vec3 rd = ca * normalize(vec3(uv, 1.));
    
    col = raymarch(ro, rd);

    //col = pow(col, vec3(0.4545));
    

    glFragColor = vec4(col,1.0);
}
