#version 420

// original https://www.shadertoy.com/view/tlGcWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITER 4
#define MAX_STEPS 200
#define MAX_DIST 20.
#define SURF_DIST 0.0001

float dist(vec2 p, vec2 t){
    float dx = p.x-t.x;
    float dy = p.y-t.y;
    return sqrt(dx*dx+dy*dy);
}

//for 2d mandelbrot
float mandel(vec2 c){

    vec2 z = vec2(0., 0.);
    vec2 zNext = vec2(0., 0.);
    int i = 0;
    
    for(i = 0; i < ITER; i++){
        zNext.x = z.x*z.x - z.y*z.y + c.x;
        zNext.y = 2.*z.y*z.x + c.y;
        z=zNext;
        
        if( dist(vec2(0), z) > 2.){
            break;
        }
    };
    
    float d = float(i/ITER);
    return d;
}

// 3d mandelbulb
float mandel3(vec3 v){
    vec3 r = v;
    vec3 rNext = r;
    int i = 0;
    float d = 1.;
    
    float n =  5.+ 5.*(sin(time*.1)*.5+.5);
    
    for(i=0; i<ITER; i++){
        float cr = length(r);
        float nr = pow(cr, n);
        
        float accos = acos(r.z/cr);
        float actan = atan(r.y/r.x);
        
        d = pow(cr, n-1.) *n * d + 1.0;
        
        rNext.x = nr*sin(accos*n)*cos(n*actan);
        rNext.y = nr*sin(accos*n)*sin(n*actan);
        rNext.z = nr*cos(n*accos);
        r += rNext;
        
        if(cr > 1.5){
            break;
        }
    }
    
    return 0.5 * log(length(r)) * length(r) / d;;
}

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float GetDist(vec3 p){
    float pd =  dot(p, normalize(vec3(0, 1, 0)));
    
    vec4 sp = vec4(0, 1., 0, 1.);
    float sd = length(p-sp.xyz)-sp.w;
    
    vec3 mp = p;
    mp.xz *= Rot(time*.14);
    float md = mandel3(mp);
    
    float d = min(md*1.2, 109.);
    //d = min(d, sd);
    //d = min(d, md);
    
    return d;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d; 
}

float RayMarch(vec3 ro, vec3 rd){
    float dO = 0.;
    
    for(int i=0; i<MAX_STEPS; i++){
        vec3 p = ro+rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO > MAX_DIST || dS<SURF_DIST)break;
    }
    
    return dO;
}
vec3 GetNormal(vec3 p){
    // distance from p to sphere
    float d = GetDist(p);
    // very small number for diff
    vec2 e = vec2(.0001, 0);
    
    // getting vector with very small vector
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx)
    );
    
    return normalize(n);
}
float GetLight(vec3 p){
    vec3 lp = vec3(10, 5, 5);
    lp.xz += vec2(sin(time), cos(time));
    vec3 l = normalize(lp - p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
    //float d = RayMarch(p+n*SURF_DIST*2., l);  
    float d = RayMarch(p+n*SURF_DIST*2., l);    
    
    
    if(d<length(lp - p)) dif *= .3;
    
    return dif;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/(resolution.y);
    //uv *= 2.;
    //uv *= Rot(time);
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0,1, 1.);
    vec3 rd = R(uv, ro, vec3(0,0,0), .7);
    
    float d = RayMarch(ro, rd);
    if(d<MAX_DIST){
        vec3 p = ro+rd*d;
        float dif = GetLight(p);
        
        col = vec3(dif);
    }
    
    //col = vec3(mandel(uv.xy));
    glFragColor = vec4(col, 0);
}
