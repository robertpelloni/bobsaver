#version 420

// original https://www.shadertoy.com/view/tdsGWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on this tutorial: https://www.youtube.com/watch?v=PGtv-dBi2wE
// 3D simplex noise from: https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83 (by Ian McEwan)
// Arbitraty axis rotation from: http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/ (blarg)

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

    vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

    i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return (42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) )) * 0.5 + 0.5;
}

mat3 rotAxis(vec3 axis, float a) {
    float s=sin(a);
    float c=cos(a);
    float oc=1.0-c;
    vec3 as=axis*s;
    mat3 p=mat3(axis.x*axis,axis.y*axis,axis.z*axis);
    mat3 q=mat3(c,-as.z,as.y,as.z,c,-as.x,-as.y,as.x,c);
    return p*oc+q;
}

float planetHeightHD(vec3 n, vec3 pseed) {
    return 
        snoise(n*2.5 + pseed * 1234.1) * 0.5 +
        snoise(n*2.5*2. + pseed * 1234.1) * 0.25 +
        snoise(n*2.5*4. + pseed * 1234.1) * 0.125 +
        snoise(n*2.5*8. + pseed * 1234.1) * 0.125*0.5 +
        snoise(n*2.5*16. + pseed * 1234.1) * 0.125*0.25;
}

float planetHeight(vec3 n, vec3 pseed) {
    return 
        snoise(n*0.5 + pseed * 1234.1) +
        snoise(n*0.5*4. + pseed * 1234.1) * 0.25 +
        snoise(n*0.5*16. + pseed * 1234.1) * 0.125 * 0.5;
}

float distPlanetHD(vec3 p, vec3 pc, float pr, vec3 pseed, float hd, mat3 rot) {
    
    float d0 = length(p - pc);
    float r = pr - pr * hd * planetHeightHD(normalize(rot * (p - pc)), pseed);
    
    return d0 - r;    
    
}

float distPlanet(vec3 p, vec3 pc, float pr, vec3 pseed, float hd, mat3 rot) {
    
    float d0 = length(p - pc);
    float r = pr + pr * hd * planetHeight(normalize(rot * (p - pc)), pseed);
    
    return d0 - r;    
    
}

float getDist(vec3 p) {
    
    mat3 p1r = rotAxis(normalize(vec3(.5, -.2, 1.)), time * 0.1);
    mat3 p1r2 = rotAxis(normalize(vec3(-1, -.1, 0.05)), -time * 0.2);
    mat3 p2r = rotAxis(normalize(vec3(.1, .5, -1.)), -time * 0.5);
    
    return min(
        min(
            distPlanetHD(p, vec3(0., 0., 0.), 5., vec3(.4315, .3415, .141561), 0.1, p1r),
            distPlanet(p, p1r2 * vec3(1., 3., 7.) * 1., 0.5, vec3(.1315, .7615, .5341561), 1., p2r)
        ), 99.9);
    
}

vec3 getNormal(vec3 p) {
    vec2 eps = vec2(0.1 * 1e-1, 0.);
    return normalize(
        getDist(p) - vec3(
            getDist(p - eps.xyy),
            getDist(p - eps.yxy),
            getDist(p - eps.yyx)
        )
    );
}

float rayMarch(vec3 r0, vec3 rd) {
    float ds = 0.;
    for (int i=0; i<32; i++) {
        vec3 p = r0 + rd * ds;
        float dist = getDist(p);
        ds += dist;
        if (dist < (1e-5)) {
            return ds;
        }
        if (ds > 200.) {
            break;
        }
    }
    return min(ds, 200.);
}

float getLight(vec3 p) {
    
    vec3 light = vec3(0., 15., -1.);
    
    vec3 n = getNormal(p);
    vec3 ld = normalize(light - p);
    
    float l = clamp(dot(n, ld), 0., 1.);
    
    float ldist = 0.02 + rayMarch(p+n*0.02, ld);
    
    if (ldist < length(light - p)) {
        l *= 0.1;
    }
    
    return l;
}

void main(void)
{
     vec2 uv = (gl_FragCoord.xy/resolution.xy - vec2(0.5, 0.5)) * vec2(1., resolution.y / resolution.x);
    
    vec3 r0 = vec3(0., 0., -40.);
    vec3 rd = normalize(vec3(uv.xy + vec2(.0, 0.), 1.));
    
    float id = rayMarch(r0, rd);
    vec3 rp = r0 + rd * id;

    glFragColor = vec4(vec3(getLight(rp)), 1.0);
}
