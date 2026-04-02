#version 420

// original https://www.shadertoy.com/view/sd3SWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

#define S smoothstep
#define T time

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float GetDist(vec3 p) {
    p.y *= 0.8;
    float a = atan(p.z,p.x);
    float r1 = 1.;
    float r2 = 0.5;
    float d = length(p.xz) - r1;
    d *= (0.95-0.5 * d);
    float td = length(vec2(cos(5. * min(abs(p.x),abs(p.z))) + p.y + cos(5.* p.y+2.*a+ 2.*time),4. * d)) - r2;
    
    return td * 0.18;
  
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

vec3 Bg(vec3 rd) {
    float a = atan(rd.z, rd.x);
    float k = mix(rd.y , cos(a), .5 + .5 * cos(2. * time)) * .5 + .5;
    vec3 col = mix(vec3(.5,0.05,0.02),vec3(0.),k);
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    //vec3 ro = vec3(3.5, 2., 3.5);
    vec3 ro = vec3(2.5 * cos(0.1 * time ),2. * sin(0.5 * time), 2.5 * sin(0.1 * time));
   // ro.yz *= Rot(-m.y*3.14+1.);
    //ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 1.);
    vec3 col = vec3(0);
    col += Bg(rd);
   
    float d = RayMarch(ro, rd);
    float depth = 0.6; //1.5 + cos(time);
    
    // comment / uncomment me
    d = RayMarch(ro + rd * (1. + depth) * d, -0.5 * depth * rd);
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(1.5*rd, n);
        
        float spec = pow(max(0., -r.y),32.);
        spec = .5 + .5 * cos(0.00001*spec); // <-- absolute fudge but works alright
        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        float a = atan(p.x,p.z);
        // dif = 16. * dif * dif * (1.-dif) * (1.-dif);
       
        col = 0.4 * vec3(dif) + 1.5 * cos(2. * a) * Bg(r);        
        col *= (1. + spec);
       
        // comment / uncomment me
        //col = vec3(dif);
    }
    col = pow(col, vec3(.4545));    // gamma correction
    glFragColor = vec4(col,1.0);
}
