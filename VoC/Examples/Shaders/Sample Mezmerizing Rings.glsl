#version 420

// original https://www.shadertoy.com/view/NlsfWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A set of metallic torus rotating aroung 
// a sphere in an interesting way.
//
// The effect comes from accumulating the rotations from the smallest
// to the largest ring.
// ----------------------------------------

#define MAX_MARCH_STEPS 128
#define MAX_MARCH_DIST 100.
#define MIN_MARCH_DIST 0.001

#define PI 3.14159265359
#define COLOR vec3(227./255.,147./255.,64./255.)
#define COLOR2 vec3(.01,0.01,.05)

vec3 rayDir(vec3 ro, vec3 origin, vec2 uv) {
    
    vec3 d = normalize(origin - ro);
    
    vec3 r = normalize(cross(vec3(0.,1.,0.), d));
    vec3 u = cross(d, r);
    
    return normalize(d + r*uv.x + u*uv.y); 
}

mat2 rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

bool intersectSphere(vec3 ro, vec3 rd, vec3 p, float r) {
    vec3 oc = ro - p;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - r*r;
    float h = b*b - c;
    if( h<0.0 ) return false;
    return true;
}

/* ----- Distance functions ---------- */
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdTorus( vec3 p, vec2 t)
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

vec4 sdScene(vec3 p);

vec4 rayMarch(vec3 ro, vec3 rd) {
    
    vec4 res = vec4(-1.); // color = xyz, distance = w 
    
    float t = 0.001f;
    for (int i = 0; i < MAX_MARCH_STEPS; ++i) {
        
        vec4 ds = sdScene(ro + rd*t);   
        if(ds.w < MIN_MARCH_DIST) {
            res = vec4(ds.xyz, t);
            break;
        }        
        
        t += ds.w;
    }
    
    return res;
}

vec4 sdScene(vec3 p) {
     
    float t = sdSphere(p, 1.);;
    float ds;
    
    p.yz *= rot(PI/2.);
    
    float mrgs = 23.;
    float rgs = floor((mrgs - 5.) / 2.);
    
    for (float i = 5.; i < mrgs; i++) {
        
        if (mod(i,2.) == 0.) {
            p.xz *= rot(pow(sin(time * .07),2.) * sin(time * .01) * 10.);
            ds = sdTorus(p, vec2(i * .3,.1 * min(3.,i/rgs))); if (ds < t) t = ds; 
        } else {
            p.zy *= rot(pow(cos(time * .07),2.) * cos(time * .01) * 10.);
        }
    }
        
    return vec4(vec3(0.), t);
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal(vec3 p) // for function f(p)
{
    const float h = 0.0001; // replace by an appropriate value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*sdScene( p + k.xyy*h ).w + 
                      k.yyx*sdScene( p + k.yyx*h ).w + 
                      k.yxy*sdScene( p + k.yxy*h ).w + 
                      k.xxx*sdScene( p + k.xxx*h ).w );
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    vec3 origin = vec3(0.);
    
    vec3 ro = vec3(0., 0., -7.);
    ro.z -= (sin(time) * .5 + .5) * 2.;
    vec3 rd = rayDir(ro, origin, uv);
    
    vec4  obj = vec4(0.);
    if (intersectSphere(ro, rd, vec3(0.), 6.93)) {
        obj = rayMarch(ro, rd);
    }
    
    vec3 col;
    if (obj.w > 0.) {
        
        vec3 p = ro + rd*obj.w;
        vec3 n = calcNormal(p);
       
        float R0 = pow((1. - 0.46094)/(1. + 0.46094),2.);        
        
        // Bottom Light
        {
            float dif = -n.y*.5 + .5;
            float spe = -reflect(rd, n).y;
           
            spe = smoothstep(0.3,0.9, spe); 
            spe *= R0 + (1. - R0)*pow(1. - dot(rd, n), 5.) * 0.3;
            
            col += COLOR * dif * 0.02;
            col += COLOR * spe * dif * .8;
        }
        
        // Top Light
        {
            float dif = n.y*.5 + .5;
            float spe = reflect(rd, n).y;
            
            spe = smoothstep(0.3,0.9, spe); 
            spe *= R0 + (1. - R0)*pow(1. - dot(rd, n), 5.) * 10.;
            
            col += COLOR2 * dif;
            col += COLOR2 * spe * dif * .8;
        }
        
        // Right Light
        {
            vec3 ld = normalize(vec3(1.0, -0.4, 0.3));
            float dif = max(0., dot(n, ld));
            
            vec3 hlf = normalize(-rd + ld);
            float spe = pow(max(0., dot(n, hlf)), 16.);
            spe *= R0 + (1. - R0)*pow(1. - dot(rd, n), 5.);
            
            col += dif * COLOR * .5;
            col += spe * COLOR * dif * .8;
        }
        
        // Left Light
        {
            vec3 ld = normalize(-vec3(1.0, -0.7, 0.3));
            float dif = max(0., dot(n, ld));
            
            vec3 hlf = normalize(-rd + ld);
            float spe = pow(max(0., dot(n, hlf)), 16.);
            spe *= R0 + (1. - R0)*pow(1. - dot(rd, n), 5.);
            
            col += dif * COLOR2 * .5;
            col += spe * COLOR2 * dif * 6. * .8;
        }
        
    } else {
        col = COLOR2 * min(gl_FragCoord.xy.y/resolution.y + .15, 1.);
    }
     
    // Gamma correct ^(1/2.2)
    col = pow(col, vec3(.4545));
    
    col = clamp(col, 0., 1.);
    col = smoothstep(0., 1., col);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
