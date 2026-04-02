#version 420

// original https://www.shadertoy.com/view/tllBzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//TRASHTRASH
//still WIP 
//so much to figure out lol
//if anyone has ideas on why the specular is off on the mod copies I'd appreciate it cheers!

//Learning RayMarching from CharStiles, BigWIngs, evvvvil, Patricio Gonzalez Vivo, iq 

//added camera rot
//added fog from pjkarlik
//thanks to you all this is mostly hacked from examples
//I am getting the concepts though

#define MAX_STEPS 128
#define MAX_DIST 100.0
#define SURF_DIST 0.001

#define MAX_HEIGHT 2.3
#define SPH_RAD 1.25
#define BLOB_SIZE 3.

//simplex noise from Patricio Gonzalez Vivo
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0);} 

float snoise(vec2 v) {
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}
//i think this is from a book about shaders or something like that
float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

//iq im pretty sure
float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

//geo                      
float map(vec3 p) {
       float pl = 10.0;
    float gr = p.y + sin((time*2.0) + p.x * pl)/pl*0.5 + snoise(vec2((time*5.)+p.x,100.)/pl) + cos((-time*4.0)+p.z*pl)/pl+1.;
    float n1 = abs(snoise(vec2(time*0.8,666.0)));
    float znoise = snoise(vec2(time*0.25,558.0))*3.0;
    float d = 0.0;
    vec2 size = vec2(10.);
    vec2 c = floor((p.xz + size * 0.5)/size);
    p.xz  = mod(p.xz + size * 0.5, size)-size*0.5;
    vec2 r1 = vec2(random(c));
    n1 = abs(snoise(vec2(time * r1.x * 0.15, 556.)));
    vec4 sphere = vec4(cos((time+r1.x*0.0012)), abs(sin(-time*4.+(r1.x+0.03)))*MAX_HEIGHT*n1, znoise, 1.0)*SPH_RAD/2.0;
    float distSphere = length(p-r1.x - sphere.xyz)-(sphere.w);
     float s1 = smin(gr, distSphere, BLOB_SIZE);
    return s1;
}
//marcher
float RM(vec3 ro, vec3 rd) {
     float or = 0.;
    for(int i=0;i<MAX_STEPS;++i){
         vec3 p = ro + rd * or;
        float sc = map(p);
        or += sc;
        if(or>MAX_DIST || abs(sc)<SURF_DIST) break;
    }
    return or;
}
//BigWIngs
vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

vec3 norm(vec3 p) {
     float d = map(p);
    vec2 e = vec2(.001, 0.);
    vec3 n = d - vec3(map(p-e.xyy), map(p-e.yxy), map(p-e.yyx));
    return normalize(n);
}

float shade(vec3 p, vec3 rd) {
     vec3 lp = vec3(-5.,6.,-2.);
    vec3 l = normalize(lp-p);
    vec3 n = norm(p);
    float col = 0.;
    float dif = clamp(dot(n,l)*.5+.5,0.,1.);
    float d = RM(p+n*SURF_DIST*2., l);
    float fr = pow(1.0+dot(n, rd),4.0);
    float sp = pow(max(dot(reflect(-l, n),-rd),0.0),80.);
       float ao = (1.0 - fr);
       float fd = 1.0 - dif;
    col = sp + max(fr, 0.5) + dif * ao;
    return col;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
       vec3 col = vec3(0.0);
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    vec3 ro = vec3(0.,1., 6.);
     ro.yz *= Rot(-m.y*.2);
    ro.xz *= Rot(time*.2-m.x*.2);
    vec3 rd = R(uv, ro, vec3(0,0,0),1.);
    float d = RM(ro, rd);
    float n1 = snoise(((time/2.)+uv)*4.);
    vec3 c1 = vec3(118./255.,220./255.,220./255.);
    vec3 fog = mix(vec3(.0001),c1+0.2*sin(n1),(uv.y+.58));
    if(d<MAX_DIST) {
       vec3 p = ro + rd * d;
       float dif = shade(p, rd);
       c1*=c1*c1;
       vec3 c = vec3(c1.x + sin(p.y), c1.y, c1.y + cos(p.y));
       col = vec3(dif)*c;
       col *= col;
    } else {
    col += fog;
   
    }
    col = mix(col, fog, 1.-exp(-0.000025*d*d*d));
    col = pow(col, vec3(.4545));
   
    glFragColor = vec4(col,1.0);
}
