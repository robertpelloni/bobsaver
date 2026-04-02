#version 420

// original https://www.shadertoy.com/view/XlXcRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** Wilhelm Kali Röntgen
    https://www.shadertoy.com/view/XlXcRj

    (cc) 2017, stefan berke
    
    Greetingx to all ya shadertoya
*/

struct Kali {
    vec3 col;
    float d;
    float fold;
};

Kali kali_set(vec3 pos, vec3 param) 
{
    float d = 10000.;
    vec3 col = vec3(0.);
    vec4 p = vec4(pos, 1.);
    for (int i=0; i<17; ++i)
    {
        p = abs(p) / dot(p.xyz, p.xyz);
        d = min(d, (length(p.xy-vec2(0,.01))-.03) / p.w);
        col = max(col, p.xyz);
        p.xyz -= param;
    }
    mat3 colmat = mat3(
        1,0.4,0.,
        0.3,1,0.0,
        -.1,0.03*col.y,1);
    return Kali(colmat*col, d, p.w);
}

vec3 kali_param;
vec3 render_scene(in vec3 ro, in vec3 rd)
{  
    vec3 col = vec3(0.);
    float sum_samples = 0.;
    
    float t = 0.;
    const float max_t = 0.03;
    for (int i=0; i<100; ++i)
    {
        if (t > max_t)
            break;
        float nt = t / max_t;
        vec3 pos = ro + t * rd;
        Kali kali = kali_set(pos, kali_param);
        //Kali kali2 = kali_set(kali.col, param);
        
        float sampling = nt*(1.-nt)-dot(col,col)*.001;
        float surf = smoothstep(.0001, .0, kali.d);
        
        col += sampling * surf * (kali.col+vec3(2.))/3.;
        sum_samples += sampling;
        
        float fwd = pow(kali.d, 1.1);
        fwd = min(fwd, 0.0003);
        fwd = min(fwd, .9/kali.fold);
        fwd = max(fwd, 0.00001);
        t += fwd;
    }
    return col / sum_samples;
}

struct PathParam {
    vec3 freq, amp, offs, param;
};

const PathParam path_f1 = PathParam(vec3(3.,  3.,  1.9),vec3(0.11,  0.04,  0.03), vec3(.0,  0.0,  .213), vec3(.706));
const PathParam path_f2 = PathParam(vec3(3.,  5.,  3.),    vec3(0.13,  0.05, 0.18), vec3(.0,  0.198,  .204), vec3(.7,.7,.69));
const PathParam path_f3 = PathParam(vec3(3.,  5.,  3.),    vec3(-0.13,  0.03, 0.11), vec3(.012,  0.204,  .245), vec3(.8,.6,.69));
const PathParam path_f4 = PathParam(vec3(3.,  4.,  5.),    vec3(0.01,  0.06, -0.04), vec3(0.02,  0.23,  .34), vec3(.5,.7,.5));
const PathParam path_f5 = PathParam(vec3(4.,  5.,  4.),    vec3(0.09,  0.019, 0.08), vec3(.021,  0.305,  .5095), vec3(.7));
//#define FIX_SCENE 4

vec3 path_f(in float t, in PathParam p) {
    t *= 2.;
    return sin(t/p.freq+vec3(0., 1.56, 1.56)) * p.amp / 10. + p.offs;
}

vec3 path(in float t, in float offs) {
    t *= .83;
    t += 42.; // thumbnail image
    float 
#ifdef FIX_SCENE
        scene_t = float(FIX_SCENE) - 1.,
#else        
        scene_t = t / 14.1 + offs/30.,
#endif        
        scene = mod(scene_t, 5.),
        blend = mod(scene_t, 1.);
    
    PathParam p1, p2;
    if (scene < 1.)
        p1 = path_f1, p2 = path_f2;
    else if (scene < 2.)
        p1 = path_f2, p2 = path_f3;
    else if (scene < 3.)
        p1 = path_f3, p2 = path_f4;
    else if (scene < 4.)
        p1 = path_f4, p2 = path_f5;
    else if (scene < 5.)
        p1 = path_f5, p2 = path_f1;
    
    t += offs;
    blend = smoothstep(0.4, 0.6, blend);
    vec3 p = mix(path_f(t, p1), path_f(t, p2), blend);
    kali_param = mix(p1.param, p2.param, blend);
    return p;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) / resolution.y * 2.;
    
    vec3 look = path(time, 5.);
    vec3 pos = path(time, 0.);
    //vec3 dir = normalize(vec3(uv, -1.+.4*length(uv)));
    
    vec3 fwd = normalize(look-pos);
    vec3 rgt = normalize(vec3(fwd.z, (look.y-look.z)*.5, -fwd.x));
    vec3 up = cross(fwd, rgt);
    
    vec3 dir = normalize(fwd * (1.-.5*length(uv)) + (uv.x*rgt + uv.y*up));
    
    vec3 col = render_scene(pos, dir);
    vec2 suv = gl_FragCoord.xy / resolution.xy * 2. - 1.;
    
    col *= 1.-pow(length(suv)*.66, 1.9);
    
    col = pow(col, vec3(1./1.6));
    glFragColor = vec4(col,1.0);
}
