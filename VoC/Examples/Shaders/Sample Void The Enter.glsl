#version 420

// original https://www.shadertoy.com/view/wlBGW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi (atan(-1.))
#define time (time + 16.)

mat2 rot(float d){return mat2(cos(d),-sin(d),sin(d),cos(d));}
    

vec2 pmod(vec2 p, float r) {
    float a = atan(p.x, p.y) + pi/r;
    float n = (pi*2.) / r;
    a = floor(a/n)*n;
    return p*rot(-a);
}
float sdBox(vec3 p, vec3 s){
    p = abs(p);
    return max(p.x - s.x, max(p.y - s.y, p.z - s.z));
}
vec3 path(vec3 p){
    return vec3(p.x + sin(p.z*0.5),p.y + cos(p.z*0.5),p.z);
}
vec2 map(vec3 p){
    vec2 d = vec2(200.);
    
    float sep = 4.;
    float id = floor(p.z/sep);
    p.xy = pmod(p.xy, 32.);

    p.z = mod(p.z, sep) - sep/2.;
    //p = path(p); 
    
    for (int i = 0; i < 4; i ++){
        p.y -= 0.4;
        p.xy -= 0.1 + float(i) * 0.03;
           p.x -= 0.4;
        //p.xy *= rot(0.9 + id);
        p = abs(p);
    }
    
    d = min(d, sdBox(p-vec3(0,0,2), vec3(0.4)));
    
    
    return d/3.;
}

#define glow(h) (0.4 + (sin(h*(vec3(0.4,0.7,0.3)))))
vec3 render(vec2 uv){
    vec3 c = vec3(0);
    
    vec3 ro = vec3(0,0, -1. + 8.*mouse*resolution.xy.x/resolution.y + time);
    //o = path(ro);
    vec3 rd = normalize(vec3(ro.x + uv.x,ro.y + uv.y,ro.z + 1.) - ro);
    

    vec3 p = ro; vec2 t = vec2(0); vec2 h = vec2(0);
    float side = 1.;
    float accum = 0.3;
    for (int i = 0; i < 200; i++){
        h = map(p)*side;
        t.x += h.x;
        c += glow(p.z)*0.005;
        if (h.x < 0.001){
            
            c += t.x*0.1*accum;
            accum *= 0.5;
            side = -side;
            t.x = 0.003;
            ro = p;
        }
        if (t.x > 10.) break;
        p = ro + rd*t.x;
    }
    if (c.g > 0.3) c.g = 0.2;
    return c;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    
    vec3 col = render(uv);

    glFragColor = vec4(col,1.0);
}
