#version 420

// original https://www.shadertoy.com/view/4td3WS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITERATIONS 256
#define MAX_DISTANCE 256.

#define EPSILON .001
#define SHADOW_BIAS .01
#define PI 3.1415926535897932384626433832795028841971

#define LIGHT_COL vec3(1.,1.,1.)
#define LIGHT_AMB .15
#define LIGHT_DIR normalize(vec3(45.,30.,-45.))

#define POINT_COL vec3(1.,1.,0.)

// Distance functions and smooth minimum by the incredible iq
// Source: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
// Source: http://www.iquilezles.org/www/articles/smin/smin.htm
float sdPlane( vec3 p, vec4 n )
{
  return dot(p,n.xyz) + n.w;
}
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 rot2D(vec2 p, float angle) {
    angle = radians(angle);
    float s = sin(angle), c = cos(angle);
    return mat2(c,s,-s,c) * p;
}

float dstScene(vec3 p) {
    
    float disp = sin(p.x*10.+time*3.)*.1;
    disp += cos(p.y*5.-time*5.)*.1;    
    
    float dst = length(p) - 1. + disp;
    dst = smin(dst, sdPlane(p, vec4(0.,0.,-1.,1.)), 1.);
    
    return dst;
    
}

float raymarch(vec3 ori, vec3 dir) {
 
    float t = 0.;
    for(int i = 0; i < MAX_ITERATIONS; i++) {
        vec3  p = ori + dir * t;
        float d = dstScene(p);
        if(d < EPSILON || t > MAX_DISTANCE) {
            break;
        }
        t += d * .75;
    }
    return t;
    
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(EPSILON,0.);
    vec3 n = vec3(dstScene(p+e.xyy)-dstScene(p-e.xyy),
                  dstScene(p+e.yxy)-dstScene(p-e.yxy),
                  dstScene(p+e.yyx)-dstScene(p-e.yyx));
    return normalize(n);
}

vec3 getPointLightVector(vec3 p) {
    
    float a = time * 2.5;
    vec3 lp = vec3(cos(a),sin(a),.015)*4.5;
    
    return lp - p;
   
}

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax, in float hardness )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<32; i++ )
    {
        float h = dstScene( ro + rd*t );
        res = min( res, hardness*h/t );
        t += clamp( h, 0.06, 0.30 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );

}

// Shadows by the incredible iq
// Source: https://www.shadertoy.com/view/Xds3zN
vec3 calcLighting(vec3 col, vec3 p, vec3 n, vec3 r, float sp) {
 
    vec3 d = vec3(0.);
    vec3 s = vec3(0.);
    
    for(int i = 0; i < 2; i++) {

        vec3 lv = i == 0 ? LIGHT_DIR : getPointLightVector(p);
        vec3 ld = normalize(lv);
        
        float diff = max(dot(ld,n),0.);
        float spec = 0.;
    
        diff *= softshadow(p, ld, SHADOW_BIAS, MAX_DISTANCE, 128.);
        if(i == 1)
            diff *= 1.-smoothstep(2.,10.,length(lv));
            
        if(diff > 0. && sp > 0.)
            spec = pow(max(dot(ld,r),0.), sp);
    
        vec3 lc = i == 0 ? LIGHT_COL : POINT_COL;
        d += (col*lc*(LIGHT_AMB+diff));
        s += (lc*spec);
        
    }
    
    return (col*d)+s;
    
}

vec3 shadeObjects(vec3 p, vec3 n, vec3 r) {
    
    vec3 col = vec3(0.);
    vec2  uv = mod(asin(n.xy) / PI + .5, 1.);
        
    if(p.z > .9)
        uv = mod(p.xy / 3.5, 1.);
        
    col = vec3(1.,0.,0.);
    float sp = 3.;
    vec2 ch = mod(uv * 5., 1.);
    if((ch.x > .5 || ch.y > .5) && !(ch.x > .5 && ch.y > .5)) {
        col *= .5;
        sp = 60.;
    }
     
    col = calcLighting(col, p, n, r, sp);
    
    return col;
    
}

vec3 shade(vec3 ori, vec3 dir) {
 
    float  t = raymarch(ori, dir);
    vec3 col = vec3(0.);
    
    if(t < MAX_DISTANCE) {

        vec3  p = ori + dir * t;
        vec3  n = calcNormal(p);
        vec3  r = normalize(reflect(dir, n));
        col = shadeObjects(p,n,r);
        
        vec3  rc = vec3(0.);
        float rt = raymarch(p+r*SHADOW_BIAS,r);
        if(rt < MAX_DISTANCE) {
            vec3 rp = p + r * rt;
            vec3 rn = calcNormal(rp);
            vec3 rr = normalize(reflect(r,rn));
            rc = shadeObjects(rp,rn,rr);
        }
        
        float f = 1. - pow(max(-dot(dir, n), 0.), .25);
        col = mix(col, rc, f);
        
    }
    
    vec3 lv = getPointLightVector(ori);
    vec3 ld = normalize(lv);
    float f = pow(max(dot(dir,ld), 0.), 30.);
    f   *= softshadow(ori, ld, 0., length(lv), 64.);
    col += POINT_COL * f;
    
    return col;
    
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / resolution.y;
    
    vec3 ori = vec3(0.,0.,-4.);
    vec3 dir = vec3(uv, 1.);
    
    vec2 m = ((mouse*resolution.xy.xy - resolution.xy * .5) / resolution.y) * -vec2(2.,-2.);
    if(mouse*resolution.xy.xy == vec2(0.)) m = vec2(0.);
    ori.xy += m;
    
    vec3 f = normalize(-ori);
    vec3 u = normalize(cross(f,vec3(0.,1.,0.)));
    vec3 v = normalize(cross(u,f));
    dir = mat3(u,v,f) * dir;
    
    glFragColor = vec4(shade(ori,normalize(dir)),1.);
}
