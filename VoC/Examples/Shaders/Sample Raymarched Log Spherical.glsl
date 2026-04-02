#version 420

// original https://www.shadertoy.com/view/7d33zM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Log Spherical Mapping / Log Polar Coords
    @byt3_m3chanic 08/20/21
    
    Found this post online and started to try some of
    it out in 2D and 3D. I hope I got this kind
    of right.. some guessing about a few of the
    numbers used. (mouseable)

    also I need to branch out into other tile systems,
    truchets are easy to set up - but what are other good
    examples with square tiled grids.
    
    https://www.osar.fr/notes/logspherical/
    
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

#define PI          3.14159265359
#define PI2         6.28318530718

#define MAX_DIST    30.00
#define MIN_DIST    0.001

float hash21(vec2 a){ return fract(sin(dot(a, vec2(27.609, 57.583)))*43758.5453); }
mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

//@iq https://iquilezles.org/www/articles/palettes/palettes.htm
vec3 hue(float t){ 
    vec3 d = vec3(0.110,0.584,0.949);
    return .45+.4*cos( PI2*t*vec3(.95,.97,.88)*d ); 
}

//@iq cylinder    
float box(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

const float sz = 2.;
const float hl = sz*.5;
const vec2 boxSize = vec2(sz*.45,.25);
const float density = 16.;

//global
vec3 hit,ghp;
vec2 cellId,gid;
float lpscale,movement;
mat2 turn;

vec2 map(vec3 q){
    vec2 res = vec2(1e5,0.);

    vec2 p = q.xz;
    p*=turn;
    float r = length(p);
    p = vec2(log(r), atan(p.y, p.x));

    p *= lpscale;
    float mul = r/lpscale;
    p.y -= hl;
    
    p.x += .0 + movement;
    
    vec2 id = floor((p+hl)/sz) - 1.5;
    p = mod(p+hl,sz)-hl;

    vec3 lp = vec3(p.x, max(0.0, q.y/mul), p.y);
    
    float bx = box(lp,boxSize.xyx)-.035;
    if(bx<res.x) {
        res = vec2(bx*mul,2.);
        gid = id;
        ghp = lp;
    }
   
    return res;
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF
vec3 normal(vec3 p, float t)
{
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e).x+
             h.yyx * map(p+h.yyx*e).x+
             h.yxy * map(p+h.yxy*e).x+
             h.xxx * map(p+h.xxx*e).x;
    return normalize(n);
}
vec3 truchet(vec2 vuv) {

    float px = fwidth(length(vuv)/PI);

    vec2 id   = cellId;
    vec2 grid = vuv;
    
    float hs = hash21(id);
    if(hs>.5) grid.x*=-1.;
    
    vec3 h = vec3(0); 
    vec3 bc = vec3(1);
    
    float chk = mod(id.y + id.x,2.) * 2. - 1.;

    vec2 d2 = vec2(length(grid-hl), length(grid+hl));
    vec2 gx = d2.x<d2.y? vec2(grid-hl) : vec2(grid+hl);

    float circle = length(gx)-hl;
    float circle2 = abs(abs(circle)-.125)-(.085+.065*sin(vuv.x*3.25) );
    circle2=smoothstep(-px,px,circle2);
    
    // color flip for every other one and then ones 
    // thats are flipped by the hash
    circle=(chk>0.^^ hs>.5) ? smoothstep(-px,px,circle) : smoothstep(px,-px,circle);
    
    vec2 sx = abs(grid)-hl;
    float cbx = length(sx)-.2;
    cbx=abs(cbx)-.025;
    cbx=smoothstep(px,-px,cbx);
    h = mix(h, bc, min(circle2,circle));
    h = mix(h, bc, cbx);
    return h;
}

void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 F = gl_FragCoord.xy;
    vec4 O = glFragColor;

    // pre-cal
    lpscale = floor(density)/PI;
    movement = time*lpscale * .123;
    turn = rot(T*5.*PI/180.);
    //
    
    
    vec2 uv = (2.* F.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0, 0, 8);
    vec3 rd = normalize(vec3(uv, -1.0));
    
    // mouse //
    float x = 0.0; //M.xy==vec2(0) ? 0. : -(M.y/R.y*.25-.125)*PI;
    float y = 0.0; //M.xy==vec2(0) ? 0. : -(M.x/R.x*.5-.25)*PI;
    mat2 rx =rot((-.75+.2*sin(T*.1))+x);
    mat2 ry =rot((.8*sin(T*.3))+y);
    ro.zy*=rx;rd.zy*=rx;
    ro.xz*=ry;rd.xz*=ry;

    vec3 C = vec3(0);
    float m = 0.;
    float d = 0.;
    vec3 p = ro;
    
    for(int i=0;i<100;i++)
    {
        p = ro + rd * d;
        vec2 ray = map(p);
        if(abs(ray.x)<MIN_DIST*d||d>MAX_DIST)break;
        d += i<64? ray.x*.5: ray.x;
        m  = ray.y;
    } 

    hit = ghp;
    cellId = gid;
    
    float alpha = 0.;
    if(d<MAX_DIST)
    {
        vec3 n = normal(p,d);
        vec3 lpos =  vec3(0,8,.5)*lpscale;
        vec3 l = normalize(lpos-p);

        float diff = clamp(dot(n,l),0.,1.);
        vec3 view = normalize(p - ro);
        vec3 ret = reflect(normalize(lpos), n);
        float spec =  0.75 * pow(max(dot(view, ret), 0.), 24.);

        vec3 h = vec3(.05);
  
        if(m==2.) h = truchet(hit.xz)* hue(cellId.x*.1);

        C = h * diff + spec;
    }
    C = mix(vec3(.0),C,exp(-.0015*d*d*d));
    
    C=pow(C, vec3(.4545));
    // Output to screen
    O = vec4(C,1.0);

    glFragColor = O;
}
