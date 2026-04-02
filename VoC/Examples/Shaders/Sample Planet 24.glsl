#version 420

// original https://www.shadertoy.com/view/Ws3fRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 200
#define MAX_DIST 30.
#define SURF_DIST 0.001

float N31(vec3 p) {
    return fract(cos(p.x*25013.+p.y*3539.+p.z*751.)*39863.);
}

float SmoothNoise3D(vec3 p) {
    vec3 lv = fract(p);
    vec3 id = floor(p);
    
    lv = lv*lv*(3.-2.*lv);
    
    float fbl = N31(id+vec3(0,0,0));
    float fbr = N31(id+vec3(1,0,0));
    float fb = mix(fbl, fbr, lv.x);
    
    float ftl = N31(id+vec3(0,1,0));
    float ftr = N31(id+vec3(1,1,0));
    float ft = mix(ftl, ftr, lv.x);
    
    float bbl = N31(id+vec3(0,0,1));
    float bbr = N31(id+vec3(1,0,1));
    float bb = mix(bbl, bbr, lv.x);
    
    float btl = N31(id+vec3(0,1,1));
    float btr = N31(id+vec3(1,1,1));
    float bt = mix(btl, btr, lv.x);
    
    float f = mix(fb, ft, lv.y);
    float b = mix(bb, bt, lv.y);
    
    return mix(f,b, lv.z);
}

float SmoothNoise3DDetail(vec3 p) {
    float c = SmoothNoise3D(p*4.);
    c += SmoothNoise3D(p*8.)*.5;
    c += SmoothNoise3D(p*16.)*.25;
    c += SmoothNoise3D(p*32.)*.125;
    c += SmoothNoise3D(p*64.)*.0625;
    c += SmoothNoise3D(p*128.)*.03125;
    return c/(2.-0.03125);
}

float sdSphere(vec3 p, float r) {
    
  float ns = length(p) - r + SmoothNoise3DDetail(p)*0.175*r;
  float ws = length(p) - r + 0.1 + SmoothNoise3D(p*64.)*.0005 + SmoothNoise3D(p*128.)*.00025;
  return min(ns, ws);
}

vec3 spherePos() {
    return vec3(0,sin(time/2.)*.15,0);
}

float GetDist(vec3 p) {
  float t = time/15.;
  p.xz = vec2(p.x * cos(t) - p.z * sin(t),
              p.x * sin(t) + p.z * cos(t));
  float d = sdSphere(spherePos()-p, 1.);
  return d;
}

float RayMarch(vec3 ro, vec3 rd) {
  float d = 0.;
  for (int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro+d*rd;
    float dS = .9*GetDist(p);
    d += dS;
    if (dS < SURF_DIST || d > MAX_DIST) break;
  }

  return d;
}

vec3 GetNormal(vec3 p) {
    vec2 e = vec2(.001, 0);
    float d = GetDist(p);
    return normalize(d - vec3(
      GetDist(p-e.xyy),
      GetDist(p-e.yxy),
      GetDist(p-e.yyx)));
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/3.0;
        float d = GetDist(pos+h*nor);
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

float shadow(vec3 ro, vec3 rd)
{
    rd = normalize(rd);
    float mint = 0.1;
    float maxt = 200.0;
    
    float res = 1.0;

    for( float t=mint; t<maxt; )
    {
        float h = GetDist(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        res = min(res, 4.*h/t);
        t += h;
    }
    return res;
}

vec3 GetLight(vec3 rd, vec3 p, vec3 n, vec3 m) {
    vec3 lo = normalize(vec3(10, 10, -8));
    
    float occ = 0.05 + 0.95*calcAO(p,n);
    float dif = 0.05 + 0.95*smoothstep(-0.2, 0.3, dot(n, lo));
    float sha = 0.05 + 0.95*shadow(p, lo);
          sha *= occ;
    float spe = dot(normalize((lo-p)-2.*dot(lo-p, n)*n), normalize(rd));
    spe = 1.+5.*smoothstep(0.7, 1.0, spe*smoothstep(0.8, 0.81, m.z));
    
    vec3 col = 1.2*vec3(1.0, 0.9, 0.9)*sha*dif*spe;
    
    return col;
}

vec3 materialComponents(vec3 p, vec3 n) {
    vec2 e = vec2(0, 1);
    vec3 coreN = normalize(p-spherePos());
    float steepness = dot(coreN,n);
    float height = length(p-spherePos());
    float st = 0.85;
    float sh = 0.925;
    float wh = 0.903;
    vec3 comp = mix(e.yxx, e.xyx, smoothstep(st,st+0.1, steepness));
          comp = mix(comp, e.yxx, smoothstep(sh, sh+0.01, height));
          comp = mix(comp, e.xxy, smoothstep(wh, wh-0.002, height));
    return comp;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 ro = vec3(0, 0, -3);
    vec3 rd = vec3(vec3(uv, 1));
    
    vec3 col = vec3(0);
    
    float d = RayMarch(ro, rd);
    
    if (d < MAX_DIST) {
        vec3 p = ro+d*rd;
        vec3 n = GetNormal(p);
        vec3 m = materialComponents(p,n);
        
        vec3 l = .95*vec3(0.5, 0.7, 0.7)*GetLight(rd, p, n, m);
        vec3 grass = vec3(0.5, 0.9, 0.2);
        vec3 stone = 1.2*vec3(0.8, 0.3, 0.1);
        vec3 water = vec3(0.2, 0.2, 0.9);
        
        col = m.x*stone + m.y*grass + m.z*water;
        
        col *= l;
    } else {
        col = vec3(smoothstep(0.998, 1., N31(vec3(uv, 0.))));
    }

    col = pow(col, vec3(0.4545));
    
    glFragColor = vec4(col, 1.0);
}
