#version 420

// original https://www.shadertoy.com/view/WltXR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 glow = vec3(0);

#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))

#define pmod(p, x) mod(p, x) - x*0.5
#define pi acos(-1.)

#define time 0.5*(time + 1.*pi/2.)
#define modDist vec2(1.42,1.)

#define xOffs 0.71
#define yOffs 0.7

#define ZOOM 5.
#define mx (0)
#define my (-time + 50.)
float sdBox(vec3 p, vec3 r){
    p = abs(p) - r;
    return max(p.x, max(p.y, p.z));
}

float sdBoxIQ( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdOcta(vec3 p, vec3 s, vec2 id){
    p = abs(p) - s;
    float d = max(p.x, max(p.y, p.z));
    
    d =  dot(p.xz + s.zx*0.5, normalize(vec2(1)));
    
    d = max(d, dot(p.xy + s.xy*0.5, normalize(vec2(1))));
    
    d = max(d, dot(p.yz + s.xy*0.5, normalize(vec2(1))));
    
    return d;
}

float sdRuby(vec3 p, vec3 s){
    p = abs(p) - s*0.9;
    float d = max(p.x, max(p.y, p.z));
    //p = abs(p);
    //p.xy *= rot(0.125*pi);
    d = max(d, dot(p.xz + s.xz*0.5, normalize(vec2(1))));
    
    d = max(d, dot(p.yz + s.zy*0.5, normalize(vec2(1))));
    //d = max(d, dot(p.yz + s.yz*0.5, normalize(vec2(1))));
    
    return d;

}
float sdMain(vec3 p, vec2 idD){
    float d = 10e6;
    
    
    
    //p.xz *= rot(0. + time);
    
    d = sdBox(p, vec3(0.51));
    //p.zy *= rot(-0.2565*pi );
    //p.xy *= rot(-0.25*pi);
    
    #define tau (2.*pi)
    float T = 7.*time/tau;
    
    
    
    vec3 s = vec3(0.5 + sin(time)*0.7);
    
    if(mod(floor(time/tau), 2.) == 1.){
        for(int i = 0; i < 4; i++){
            p = abs(p);

            p.xy  *= rot(1.5*pi + sin(time)*0. + idD.x*pi);
            p.xz *= rot(0.99);
            //p.x -= 0.02;
        }
        s = vec3(0.5 + sin(time)*0.35);
    }
    //p = abs(p);
    
    d = min(d, sdOcta(p, s, idD));
    
    //d = max(d, -sdOcta(p, vec3(0.4 + sin(time)*0.5), idD));
    //d = min(d, sdOcta(p, vec3(0.4 + sin(time)*0.5), idD));
    
    
    
    return d;
}

vec2 id;

float sdIso(vec3 p, vec2 id){
    float d = 10e6;
    //p.z -= 0.;
    vec3 q = p;
    
    // ME
    p.x -= id.y*xOffs;
    p.y += id.y*yOffs;
    p.xz = pmod(p.xz, modDist);
    p.xy *= rot(pi*0.25);
    d = min(d, sdMain(p, id));
    
    vec2 idD = id;
    
    // BOTTOM
    p = q;
    idD.y += 1.;
    p.x -= idD.y*xOffs;
    p.y += idD.y*yOffs;
    p.xz = pmod(p.xz + vec2(0,0. - id.y), vec2(modDist.x,modDist.y*3.));
    
    if (p.x > 0.){
        idD.x -= 1.;
    }
    p.xy *= rot(pi*0.25);
    d = min(d, sdMain(p, idD));
    

    // RIGHT
    p = q;
    idD = id;
    idD.x -= 1.;
    p.x -= idD.y*xOffs;
    p.y += idD.y*yOffs;
    p.xz = pmod(p.xz + vec2(modDist.x*1.- idD.x*modDist.x*1.,0), vec2(modDist.x*3.,modDist.y));
    p.xy *= rot(pi*.25);
    d = min(d, sdMain(p, idD));
    
    // LEFT
    p = q;
    idD = id;
    idD.x += 1.;
    p.x -= idD.y*xOffs;
    p.y += idD.y*yOffs;
    p.xz = pmod(p.xz + vec2(modDist.x*1.- idD.x*modDist.x*1.,0), vec2(modDist.x*3.,modDist.y));
    p.xy *= rot(pi*.25);
    d = min(d, sdMain(p, idD));
    
    // TOP
    idD = id;
    idD.y -= 1.;
    p = q;
    p.x -= idD.y*xOffs;
    p.y += idD.y*yOffs;
    p.xz = pmod(p.xz + vec2(0.,-1. - id.y), vec2(modDist.x,modDist.y*3.));
    if (p.x < 0.){
      idD.x += 1.;
    }
    p.xy *= rot(pi*0.25);
    d = min(d, sdMain(p, idD));
    
    
    return d;
}

vec2 map(vec3 p){
    vec2 d = vec2(10e6);
    p.x += 0.5;
    id = floor(p.xz/modDist);
    id.x = floor((p.x - modDist.x*0.5*id.y)/modDist.x);
    
    d.x = min(d.x, sdIso(p, id));
    
    d.x *= 0.55;
    return d;
}

vec2 march(vec3 ro, vec3 rd, inout vec3 p, inout float t, inout bool hit){
    p = ro;
    vec2 d;
    hit = false;
    for(int i = 0; i < 280 ;i++){
        d = map(p);
        glow += exp(-d.x*6.);
        if(d.x < 0.001){
            hit = true;
            break;
        }
        t += d.x;
        p = ro + rd*t;
    }

    return d;
}

vec3 getNormal(vec3 p){
    vec2 t = vec2(0.0001,0);
    return normalize(map(p).x - vec3(
        map(p - t.xyy).x,
        map(p - t.yxy).x,
        map(p - t.yyx).x
    ));
}

vec3 getRd(inout vec3 ro, vec3 lookAt, vec2 uv){
    vec3 dir = normalize(lookAt - ro );
    vec3 right = normalize(cross(vec3(0,1,0), dir));
    vec3 up = normalize(cross(dir, right));
    ro -= ZOOM*dir;
    return dir + right*uv.x + up*uv.y;
}
vec3 getRdIsometric(inout vec3 ro, vec3 lookAt, vec2 uv){
    vec3 rd = normalize(
        lookAt -
        ro
    );
    
    vec3 right = normalize(cross(vec3(0,1,0), rd));
    vec3 up = normalize(cross(rd, right));
    
    
    ro += right*uv.x*ZOOM;
    ro += up*uv.y*ZOOM;
     return rd;

}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    
    vec3 col = vec3(0.0);
    vec3 lookAt = vec3(0,-1,-2);
    
    
    vec3 ro = vec3(0,8,0);
   
    vec3 rd = getRdIsometric(ro, lookAt, uv); 
    //vec3 rd = getRd(ro, lookAt, uv); 
        
    vec3 p;
    
    ro.x += float(mx);
    ro.z += float(my);
    ro.y -= 0.65;
    ro += rd*5.4;
    
    float t = 0.; bool hit;
    
    vec2 d = march(ro, rd, p, t, hit);
    
    
    if (hit){
        vec3 n =-getNormal(p);
        n.g*=0.4;
        
        col += 0.8 + n*0.5;
        
    } else {
    
    }
    
    
    col += glow*0.02;
    
    col = max(col, 0.);
    
    col = clamp(col, 0., 1.);
    
    
    col = pow(col, vec3(1.7));
    
    
    glFragColor = vec4(col,1.0);
}
