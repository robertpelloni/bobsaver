#version 420

// original https://www.shadertoy.com/view/tdlyD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-------------------------------------------------------------------
// Trying out ShaderToy and trying to get to grips with ray marching.
// Inspired by the amazing creations of Evvvvil, Nusan and Shane
//-------------------------------------------------------------------

#define MD 30.        // max distance
#define SD 0.0001    // surface distance
#define MS 250      // max number of steps to march
#define EPS 0.0001   // distance used for sampling the gradient

// always handy to have PI available
const float PI = acos(-1.);
const float TWOPI = 2.*PI;

// fog color.
const vec3 fog = vec3(.05,.25, .05);

// always need some glow!
float glw = 0.;

// sphere SDF
float sph(vec3 p, float r){return length(p)-r;}

// min and max which preserve material
vec2 mmin(vec2 a, vec2 b) {return a.x < b.x ? a:b;}
vec2 mmax(vec2 a, vec2 b) {return a.x > b.x ? a:b;}

// 2d rotation
void rot(inout vec2 p, float a) {
    float c=cos(a), s=sin(a);
    p *= mat2(c,-s,s,c);
}

// I was going to do something complicated here,
// but ended up doing a sphere!
vec2 prim(vec3 p) {
    return vec2(sph(p, .5), 5);
}

// the SDF for the scene
vec2 map(vec3 p) {
    
    // wiggle x
    p.x += sin(p.z + time*.2)*.5;
    // spiral
    rot(p.xy, sin(p.z / 3.));
    // scroll along z
    p.z -= time/3.;
    
    // repeat everything
    vec3 mp;
    mp.x = mod(p.x, 2.3)-1.15;
    mp.y = mod(p.y, 2.3)-1.15;
    mp.z = mod(p.z,.6)-.3;
    
    // fractal (ish)
    vec4 ap = vec4(mp,1.);
    // big purple sphere
    vec2 a=prim(mp);
    a.x *= .6;
    // smaller black spheres
    int n=4;
    for(int i=1; i<=n; ++i) {
        ap *= 2.5; // scale
        ap.xyz = abs(ap.xyz)-vec3(.8); // symmetry
        rot(ap.xy, ap.z*.1 + time*.5); // movement
        vec2 b = prim(ap.xyz); // sphere
        b.x /= ap.w; // correct for scaling
        b.x *= .6;   // patch up the SDF
        b.y= 1.;     // paint it black
        a=mmin(a, b);
        
    }
    
    // Sparkles. Lots of them.
    rot(p.xy, time*.3);
    vec2 b = vec2(length(cos(p*1.+vec3(1.5+p.z*.05*sin(time),1.7+sin(time)*.2,time*2.)))-.001 ,6.);
    glw += .1/(.1*b.x*b.x*10000.);
    b.x *= .6;
    
    // final distance
    vec2 d=mmin(a,b);
    return d;
}

// determine the normal at point p by sampling the gradient of the SDF
vec3 normal(vec3 p) {
     vec2 off = vec2(EPS, 0.);
    return normalize(map(p).x - vec3(map(p-off.xyy).x,map(p-off.yxy).x,map(p-off.yyx).x));
}

//-------------------------------------------------------------
// lighting and colour,
// heavily based on Evvvvil's Micro Lighting Engine Broski (TM)
//-------------------------------------------------------------

// shortcuts for calculating fake ambient occlusion and subsurface scattering
#define aoc(d) clamp(map(p + n * d).x/d, 0., 1.)
#define sss(d) smoothstep(0.,1.,map(p+ld*d).x/d)

vec3 surface(vec3 ro, vec3 rd, vec2 hit) {
    float d=hit.x;         // distance from ray origin
    float m = hit.y;       // materialID
    
    // albedo, or base color, based on material ID    
    vec3 al = m < 5. ? vec3(0) : 
            m > 5. ? vec3(1) :
            vec3(.1,.1,.4);
    
    vec3 p = ro + rd * d;  // the point in space
    vec3 n = normal(p);    // normal of the SDF at point p
    
    vec3 ld = normalize(vec3(-1));     // light direction
    float diff = max(0., dot(n, -ld)); // diffuse illumination
    
    vec3 lr = reflect(ld, n);          // reflected light ray
    float spec = pow(max(0., dot(lr,-rd)),32.); // specular component
 
    float frz = pow(max(0.1, 1. - dot(n,-rd)),4.)*.5; // freznel)
    
    float ao = aoc(.1); // fake AO
    float ss = sss(1.); // fake subsurface scattering
    
    vec3 col =  al * ao * (diff + ss) + spec; // combine it all together
    col = mix(col, fog, frz);         // fog the edges
    
    return col; // the final color
}

// ray marching loop
vec3 march(vec3 ro, vec3 rd) {
    float dd=0.1;        // start with a slight z offset
    vec3 col=vec3(0);   // no color initially
    vec3 p=ro + rd * dd;// current point
    
    for(int i=0; i<MS; ++i) {  // start marching
         vec2 d = map(p);  // distance to SDF
        
        if(d.x < SD) { // close to a surface
            // get the color of the surface
            col += d.y > 0. ? surface(ro, rd, vec2(dd, d.y)) : vec3(0.);
            break; // we're done
        }
        
        if(dd > MD) { // we've reached the max draw distance,
            dd = MD;
            break;    // and we're done
        }
        
        dd += d.x;     // track the total distance
        p += rd * d.x; // and update the current position
    }
    
    // blend in some distance-based fog and return
    return mix(fog * pow(max(0., dot(rd, vec3(0,0,-1))),20.), col, exp(-0.003*dd*dd*dd));
}

// given the ray origin, lookat point and uv's, calculate the ray direction
vec3 raydir(vec3 ro, vec3 la, vec2 uv) {
    // x,y and z axes
    vec3 cz = normalize(la-ro);
    vec3 cx = normalize(cross(cz,vec3(0,1,0)));
    vec3 cy = normalize(cross(cx,cz));
    // project and normalize
    return normalize(cx*uv.x + cy*uv.y + cz);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    // make sure that the pixels are square
    uv /= vec2(resolution.y / resolution.x, 1);

    // get rid of some artifacts
    //time = mod(time, 62.39);
    
    // setup the ray
    vec3 ro = vec3(0,0,1);
    vec3 rd = raydir(ro, vec3(0)-ro, uv);
    
    // march
    vec3 col = march(ro, rd);

    col += glw;
    // exposure
    col = vec3(1) - exp(-col * 1.1);
    // gamma
    col = pow(col, vec3(1./2.2));
    // final color
    glFragColor = vec4(col,1.0);
}
