#version 420

// original https://www.shadertoy.com/view/tlySD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 128
#define E 0.001
#define gamma vec3(2.2)

const vec3 AMBIENT = vec3(0.2, 0.4, 0.64);
const vec3 LC1 = vec3(0.3, 0.6, 0.8);
const vec3 LC2 = vec3(0.6, 0.4, 0.3);
const vec3 FOG = vec3(0.64, 0.62, 0.6);

struct Material{
    vec3 lambertian;
    vec3 specular;
    float shininess;
    bool reflective;
    bool refractive;
};

Material getGroundMaterial(){
    Material mat;
    mat.lambertian = vec3(0.1, 0.4, 0.5);
    mat.specular = FOG;
    mat.shininess = 4.0;
    mat.reflective = true;
    mat.refractive = false;
    
    return mat;
}

Material getBlockMaterial(in vec2 id){
    vec2 s = smoothstep(vec2(0.2), vec2(0.8), id);
    
    Material mat;
    mat.lambertian = vec3(s.x, s.y, s.x);
    mat.specular = vec3(s.y, id.x, s.x);
    mat.shininess = 40.0;
    mat.reflective = mod(id.x, 2.0) == 0.0;
    mat.refractive = false;
    
    return mat;
}

// 3D noise function (IQ)
float noise(vec3 p){
    vec3 ip = floor(p);
    p -= ip;
    vec3 s = vec3(7.0,157.0,113.0);
    vec4 h = vec4(0.0, s.yz, s.y+s.z)+dot(ip, s);
    p = p*p*(3.0-2.0*p);
    h = mix(fract(sin(h)*43758.5), fract(sin(h+s.x)*43758.5), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float scene(in vec3 p, out Material mat){
    
    float pl = dot(p, normalize(vec3(0.0, 1.0, 0.0)))-cos(time*0.1)*0.5;
    pl -= sin(noise(p*(sqrt(5.0)*0.5 + 0.5)*0.2+time*0.2));
    
    vec3 pp = p;
    vec2 n = vec2(2.7, 8.0);
    vec2 dif = n*0.5;
    pp.xz = mod(p.xz+dif, n)-dif;
    vec2 id = abs(floor((p.xz+dif)/n));
    float idx = 1.0+sin(id.x);
    float y = abs(cos(idx)+sin(id.y))+0.5;
    
    vec3 d = abs(pp-vec3(0.0, y, 0.0))-vec3(1.0, y, 1.0);
    float sp = length(max(max(d.x, d.y), d.z));
    
    vec3 gd = abs(pp)-vec3(n.x, 10.0, n.y)*0.5;
    
    float guard = -length(max(max(gd.x, gd.y), gd.z));
    guard = abs(guard) + n.x*0.1;
    
    if(pl < sp){
        
        mat = getGroundMaterial();
    }
    else{
        mat = getBlockMaterial(id);
    }
    
    return min(min(sp, guard), pl);
}

float march(in vec3 o, in vec3 d, in float far, in bool inside, out vec3 p, out bool hit, out Material mat){
    float t = 0.0;
    float dir = inside ? -1.0 : 1.0;
    hit = false;
    for(int i = 0; i < STEPS; ++i){
        p = o + d*t;
        float dist = dir*scene(p, mat);
        
        if(abs(dist) < E || t > far){
            if(abs(dist) < E ){
                hit = true;
            }
            break;
        }
        t += dist;
    }
    
    return t;
}

vec3 normal(in vec3 p){
    vec3 eps = vec3(E, 0.0, 0.0);
    Material mat;
    return normalize(vec3(
        scene(p+eps.xyy, mat) - scene(p-eps.xyy, mat),
        scene(p+eps.yxy, mat) - scene(p-eps.yxy, mat),
        scene(p+eps.yyx, mat) - scene(p-eps.yyx, mat)
    ));
}

vec3 phong(in vec3 n, in vec3 d, in vec3 ld, in Material mat){
    float lamb = max(dot(n,ld), 0.0);
    vec3 angle = reflect(n, ld);
    float spec = pow(max(dot(d, angle), 0.0), mat.shininess);
    
    return (lamb*mat.lambertian*0.5 + spec*mat.specular*0.8);
}

vec3 fog(in vec3 col, in vec3 p, in vec3 ro, in vec3 rd, in vec3 ld, in vec3 lc){
    float d = length(p-ro);
    float sa = max(dot(rd, -ld), 0.0);
    float fa = 1.0-exp(-d*0.05);
    vec3 fc = mix(FOG, lc, pow(sa, 4.0));
    return mix(col, fc, fa);
}

vec3 shade(in vec3 p, in vec3 d, in vec3 ld, in vec3 lp, in Material mat){
    
    vec3 n = normal(p);
    
    vec3 col = phong(n, d, ld, mat);
    
    float l = distance(p, lp);
    bool hit = false;
    vec3 sp = vec3(0.0);
    Material mats;
    float st = march(p+E*n*2.0, ld, 40.0, false, sp, hit, mats);
    vec3 s = vec3(1.0);
    if(hit){
        s = vec3(0.1, 0.2, 0.3);
    }
    
    vec3 reflected = vec3(0.0);
    if(mat.reflective){
        hit = false;
        vec3 refd = reflect(d, n);
        float rt = march(p+E*n*2.0, refd, 20.0, false, sp, hit, mats);
        if(hit){
            vec3 nr = normal(sp);
            reflected = phong(nr, refd, ld, mats);
        }
        else if(rt >= 20.0){
            reflected = FOG*0.2;
        }
        col = mix(col, reflected, 0.5);
        
    }
    
    return col*s;
}

mat3 camera(in vec3 o, in vec3 t, in vec3 up){
    
    vec3 z = normalize(t-o);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    
    return mat3(x, y, z);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 q = uv*2.0-1.0;//scaling from -1 to 1
    q.x *= (resolution.x/resolution.y);
    
    vec3 ro = vec3(3.0, 4.5, time-30.0);
    vec3 rt = vec3(0.0, -4.0, ro.z+10.0);
    vec3 up = vec3(0.0, 1.0, 0.0);
    
    mat3 cam = camera(ro, rt, up);
    vec3 rd = normalize(cam*vec3(q, radians(60.0)));
    
    vec3 p = vec3(0.0);
    bool hit = false;
    Material mat;
    float t = march(ro, rd, 40.0, false, p, hit, mat);
    vec3 col = AMBIENT * 0.6;
    
    vec3 lp = vec3(20.0*sin(time*0.25)+ro.x, -10.0, 10.0*cos(time*0.25)+ro.z-20.0);
    vec3 lt = ro;
    vec3 ld = normalize(lt-lp);
    vec3 ld2 = normalize(rt-ro);
    
    if(hit){
        vec3 c = shade(p, rd, ld, lp, mat);
        c += shade(p, rd, -ld2, ro, mat);
        c *= 0.5;
        col += c;
    }
    
    col = fog(col, p, ro, rd, ld, LC1);
    col += fog(col, p, ro, rd, -ld2, LC2);
    col *= 0.5;
    
    col = pow(smoothstep(0.08, 1.1, col)*smoothstep(0.8, 0.005*0.799, 
          distance(uv, vec2(0.5))*(0.8 + 0.005)), 1.0/gamma);

    // Output to screen
    glFragColor = vec4(col,1.0);
    
}
