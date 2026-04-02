#version 420

// original https://www.shadertoy.com/view/Nsc3W8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All the distance functions from:http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// raymarching based from https://www.shadertoy.com/view/wdGGz3
#define MAX_STEPS 100
#define MAX_DIST 80.
#define SURF_DIST .001
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define matRotateX(rad) mat3(1,0,0,0,cos(rad),-sin(rad),0,sin(rad),cos(rad))
#define matRotateY(rad) mat3(cos(rad),0,-sin(rad),0,1,0,sin(rad),0,cos(rad))
#define matRotateZ(rad) mat3(cos(rad),-sin(rad),0,sin(rad),cos(rad),0,0,0,1)

const float Epsilon = 1e-10;

// noise function from https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
vec2 fade(vec2 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}

float cnoise(vec2 P){
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);
  vec4 norm = 1.79284291400159 - 0.85373472095314 * 
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

vec3 path(float z)
{
    vec3 p = vec3(sin(z) * .6, cos(z * .5), z);
    return p;
}

vec4 combine(vec4 val1, vec4 val2 ){
    return (val1.w < val2.w)?val1:val2;
}

float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

vec4 GetDist(vec3 p) {
    p.xy -= path(p.z).xy;

    float d = -length(p.xy) + 1.;
    
    p.z+=time*3.0;
    float nn = cnoise(p.xy*6.0+p.z);
    vec3 col = vec3(.3,0.0,0.8);
    col += nn*5.0;
    
    vec4 model = vec4(col,d);
    
    p.z = 0.0;
    
    vec3 prevP = p;
    
    p.xy*=Rot(radians(time*50.0));
    
    col = vec3(.7,0.0,0.5);
    nn = cnoise(p.xy*10.0);
    col += nn*3.0;
    
    float c = 0.06;
    p.xy = mod(p.xy,c)-0.5*c;
    d = sdOctahedron(p,0.02);
    p = prevP;
    float d2 = length(p)-0.5;
    d = max(d2,d);

    vec4 model2 = vec4(col,d);
    
    return combine(model,model2);
}

vec4 RayMarch(vec3 ro, vec3 rd) {
    vec4 r = vec4(0.0,0.0,0.0,1.0);
    
    float dist;
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*r.w;
        vec4 dS = GetDist(p);
        dist =  dS.w;
        r.w += dS.w;
        r.rgb = dS.xyz;
        
        if(r.w>MAX_DIST || dS.w<SURF_DIST) break;
    }
    
    return r;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).w;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).w,
        GetDist(p-e.yxy).w,
        GetDist(p-e.yyx).w);
    
    return normalize(n);
}

vec2 GetLight(vec3 p) {
    vec3 lightPos = vec3(3,5,0);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l).w;
    
    float lambert = max(.0, dot( n, l))*0.2;
    
    return vec2((lambert+dif),0.9) ;
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

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float t = time*2.0;
    vec3 col = vec3(0);
    vec3 ro = path(t+1.5);
    vec3 rd = R(uv, ro, vec3(0,0.0,0), 0.6);
    vec4 r = RayMarch(ro, rd);
    
    if(r.w<MAX_DIST) {
        vec3 p = ro + rd * r.w;
        vec3 n = GetNormal(p);
        vec2 dif = GetLight(p);
        col = vec3(dif.x)*r.rgb;
        col *= dif.y;
    }

    glFragColor = vec4(col,1.0);
}
