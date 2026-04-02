#version 420

// original https://www.shadertoy.com/view/wdVczD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdPlane(vec3 p, vec3 n, float h) {
    return dot(p, n) + h;
}

// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

// https://gamedev.stackexchange.com/a/148088
vec3 srgb(vec3 rgb) {
    bvec3 t = lessThan(rgb, vec3(0.0031308));
    vec3 a = 1.055*pow(rgb, vec3(1.0/2.4)) - 0.055;
    vec3 b = 12.92*rgb;
    return mix(a, b, t);
}

// https://www.shadertoy.com/view/Xd3GRf
lowp vec4 permute(in lowp vec4 x){return mod(x*x*34.+x,289.);}
lowp float snoise(in mediump vec3 v){
  const lowp vec2 C = vec2(0.16666666666,0.33333333333);
  const lowp vec4 D = vec4(0,.5,1,2);
  lowp vec3 i  = floor(C.y*(v.x+v.y+v.z) + v);
  lowp vec3 x0 = C.x*(i.x+i.y+i.z) + (v - i);
  lowp vec3 g = step(x0.yzx, x0);
  lowp vec3 l = (1. - g).zxy;
  lowp vec3 i1 = min( g, l );
  lowp vec3 i2 = max( g, l );
  lowp vec3 x1 = x0 - i1 + C.x;
  lowp vec3 x2 = x0 - i2 + C.y;
  lowp vec3 x3 = x0 - D.yyy;
  i = mod(i,289.);
  lowp vec4 p = permute( permute( permute(
      i.z + vec4(0., i1.z, i2.z, 1.))
    + i.y + vec4(0., i1.y, i2.y, 1.))
    + i.x + vec4(0., i1.x, i2.x, 1.));
  lowp vec3 ns = .142857142857 * D.wyz - D.xzx;
  lowp vec4 j = -49. * floor(p * ns.z * ns.z) + p;
  lowp vec4 x_ = floor(j * ns.z);
  lowp vec4 x = x_ * ns.x + ns.yyyy;
  lowp vec4 y = floor(j - 7. * x_ ) * ns.x + ns.yyyy;
  lowp vec4 h = 1. - abs(x) - abs(y);
  lowp vec4 b0 = vec4( x.xy, y.xy );
  lowp vec4 b1 = vec4( x.zw, y.zw );
  lowp vec4 sh = -step(h, vec4(0));
  lowp vec4 a0 = b0.xzyw + (floor(b0)*2.+ 1.).xzyw*sh.xxyy;
  lowp vec4 a1 = b1.xzyw + (floor(b1)*2.+ 1.).xzyw*sh.zzww;
  lowp vec3 p0 = vec3(a0.xy,h.x);
  lowp vec3 p1 = vec3(a0.zw,h.y);
  lowp vec3 p2 = vec3(a1.xy,h.z);
  lowp vec3 p3 = vec3(a1.zw,h.w);
  lowp vec4 norm = inversesqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  lowp vec4 m = max(.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.);
  return .5 + 12. * dot( m * m * m, vec4( dot(p0,x0), dot(p1,x1),dot(p2,x2), dot(p3,x3) ) );
}

struct RM { vec3 p; float t; float d; };

float map(vec3 p) {
    float d = 0.0, da = 0.1, df = 1.0;
    if (length(p) < 1.01)
        for (int i = 0; i < 10; i++, da *= 0.5, df *= 2.0)
            d += da*snoise(df*p);

    return min(
        sdPlane(p, vec3(0.0, 1.0, 0.0), 1.0),
        0.5*(sdSphere(p, 1.0) + d)
    );
}

// https://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p) {
    const vec3 k = vec3(1.0, -1.0, 1e-5);
    return normalize(
        k.xyy*map(p + k.xyy*k.z) +
        k.yyx*map(p + k.yyx*k.z) +
        k.yxy*map(p + k.yxy*k.z) +
        k.xxx*map(p + k.xxx*k.z)
    );
}

bool raymarch(vec3 rc, vec3 ro, vec3 rd, out RM rm) {
    // rayconfig rc: threshold, near, far
    for (rm.t = rc.y; rm.t < rc.z; rm.t += rm.d)
        if ((rm.d = map(rm.p = ro + rm.t*rd)) < rc.x)
            return true;
    return false;
}

vec3 render(vec2 uv) {
    vec3 material = vec3(0.13, 0.11, 0.08);
    vec3 ambient = 0.02*vec3(0.10, 0.15, 0.25);
    vec3 light = 50.0*vec3(1.0);
    vec3 fog = 3.0*ambient;
    
    vec3 rc = vec3(1e-4, 1e-3, 1e+1);
    vec3 rt = vec3(1.3*uv,  0.0);
    vec3 ro = vec3(0.0*uv, -5.0);
    vec3 rd = normalize(rt - ro);
    RM rm, rml;
    
    if (!raymarch(rc, ro, rd, rm))
        return fog;
    
    //if (rm.d < 0.0)
    //    return vec3(1.0, 0.0, 0.0);
    
    vec3 n = normal(rm.p);
    vec3 lp = 2.5*vec3(cos(time), 1.0, sin(time)) - rm.p;
    vec3 ld = normalize(lp);
    float ll = length(lp);
    
    if (raymarch(vec3(rc.xy, ll), rm.p, ld, rml))
        return mix(ambient, fog, rm.t/rc.z);
    
    float diffuse = 4.0*max(0.0, dot(n, ld));
    float specular = 0.2*pow(max(0.0, dot(rd, reflect(ld, n))), 50.0);
    vec3 color = ambient + (material*diffuse + specular)*light/exp(ll);
    return mix(color, fog, rm.t/rc.z);
}

void main(void) {
    vec2 r = vec2(resolution.x/resolution.y, 1.0);
    vec2 uv = 2.0*gl_FragCoord.xy/resolution.xy - 1.0;
    glFragColor = vec4(srgb(render(r*uv)), 1.0);
}
