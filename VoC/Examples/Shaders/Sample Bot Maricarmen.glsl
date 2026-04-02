#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WlGXzz

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by genis sole - 2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International.

// Visuals are based on a desing by LabRat (https://twitter.com/Lab___Rat) 

#define ZERO min(0, frames)
#define AA 0

const int REFLECTION_SAMPLES = 40;

const float PI = 3.1415926536;

//from https://www.shadertoy.com/view/4djSRW
vec2 hash23(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec2 cylIntersect( vec3 ro, vec3 rd, float r )
{
    float a = 1.0 - rd.y*rd.y;
    float b = dot(ro, rd) - ro.y*rd.y;
    float c = dot(ro, ro) - ro.y*ro.y - r*r;
    float h = b*b - a*c;
    
    if( h < 0.0 ) return vec2(-1.0);
    
    h = sqrt(h);
    
    return vec2(-b-h,-b+h)/a;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// http://iquilezles.org/www/articles/smin/smin.htm
vec2 smin( vec2 a, vec2 b, float k )
{
    float h = clamp( 0.5+0.5*(b.x-a.x)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdEllipsoid( vec3 p, vec3 r )
{
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCone( in vec3 p, in vec3 c )
{
    vec2 q = vec2( length(p.xz), p.y );
    float d1 = -q.y-c.z;
    float d2 = max( dot(q,c.xy), q.y);
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdRoundCone( vec3 p, float r1, float r2, float h )
{
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

//https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float ndot(vec2 a, vec2 b ) { return a.x*b.x - a.y*b.y; }
float sdRhombus( in vec2 p, in vec2 b ) 
{
    vec2 q = abs(p);
    float h = clamp((-2.0*ndot(q,b)+ndot(b,b))/dot(b,b),-1.0,1.0);
    float d = length( q - 0.5*b*vec2(1.0-h,1.0+h) );
    return d * sign( q.x*b.y + q.y*b.x - b.x*b.y );
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdTriPrism( vec3 p, vec2 h )
{
    const float k = sqrt(3.0);
    h.x *= 0.5*k;
    p.xy /= h.x;
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x+k*p.y>0.0 ) p.xy=vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    float d1 = length(p.xy)*sign(-p.y)*h.x;
    float d2 = abs(p.z)-h.y;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float sdHeadRivetes(vec3 p, float d)
{
    p.x -= 0.2;
    vec2 xp = vec2(length(p.yz), atan(p.z, p.y));
    float tp = mod(xp.y + 0.05, 2.0*PI/15.) - PI/15.;
    
    vec3 tpp = vec3(p.x, sin(tp)*xp.x, cos(tp)*xp.x);

       return smax(length(tpp.yx) - 0.07, (d - 0.04), 0.03);
}

float sdArmsOverlay(vec3 p, float d)
{
    p.x = abs(p.x);
    float o = sdEllipsoid(p - vec3(0.5, 1.1, 0.0), vec3(0.3, 1.0, 0.5));
    
    return smax((abs(d) - 0.02), o, 0.05);
}

float sdBodyOverlay(vec3 p, float d)
{
    float o = sdEllipsoid(p - vec3(2.0, -4.9, -0.5), vec3(1., 1.8, 1.5));
       //float o = sdEllipsoid(p - vec3(1.9, -4.9, -0.5), vec3(1., 1.8, 1.9));
    return smax((abs(d) - 0.02), o, 0.05);
}

float sdArmsRivetes(vec3 p, float d)
{
    float c = abs(p.y-1.1) - 1.0;
    p.y = mod(p.y - 0.2, 0.6) - 0.5*0.6;
    float rivetes = length(p.yz) - 0.085;
    rivetes = smax((d - 0.05), rivetes, 0.05);
    rivetes = max(c, rivetes);

    return rivetes;
}

float sdBodyRivetes(vec3 p, float d)
{ 
    float c = p.y-1.5;
    
    p.z = -abs(p.z + 0.4);
    p.xz = (mat2(4, -3, 3, 4) / 5.0) * p.xz;
     p.z += 0.15;
    
    p.y = mod(p.y + 0.3, 0.7) - 0.5*0.5;
    float r = length(p.yz) - 0.085;
    r = smax(d - 0.05, r, 0.05); 
    
    return max(c, r);
}

float sdHeadBase(vec3 p)
{
    float skull = sdEllipsoid(p - vec3(0.0, -1.1, 0.0), vec3(2.15, 1.5, 1.8));
    skull = smin(sdEllipsoid(p - vec3(0.0, -0.35, 0.0), vec3(2.07, 2.07, 1.8)), skull,  0.5);
    skull = smax(-p.y-1.8, skull, 1.0) - 0.505;
    
    return skull;
}

vec3 transformHeadSeam(vec3 p)
{
    p = p - vec3(0.8, -0.8, 0.0);
    p.xz = (mat2(15,-8,8, 15) / 17.0) * p.xz;
    p.x = abs(p.x);
    return p;
}

float sdHeadSeam(vec3 p, float d)
{
    return max(p.x - 0.025, abs(d) - 0.1);
}

float sdMouthGap(vec3 p, float d)
{
    vec2 mp = p.xy - vec2(0.38, -0.64);
    float mouth = abs(abs(mp.x - 0.45)) - 0.015;
    mouth = max(mp.y + 0.05, mouth);
    mouth = smax(abs(d) - 0.2, mouth, 0.15);

    float tmouth = max(abs(p.z + 4.5) - 4.9, abs(length(mp.xy) - 0.45) - 0.03);
    tmouth = smax(mp.y - 0.05, tmouth, 0.02);
    tmouth = smax(min(-(p.x + 0.45), p.y + 0.4), tmouth, 0.05);
    
    tmouth = smax(abs(d) - 0.4, tmouth, 0.05);
    return min(tmouth, mouth);
}

float sdHead(vec3 p, float d)
{
    vec3 bs = p - vec3(0.0, -1., 2.5);
    bs.yz = (mat2(15,-8,8, 15) / 17.0) * bs.yz;
    
    d = smax(bs.z + 0.2, d, 0.7); 

    return d;
}

float sdEars(vec3 p)
{
    vec3 eap = p - vec3(0.9, 2.15, 0.0);
    eap.xy = (mat2(3, 4, -4, 3) / 5.0) * eap.xy;
    float ears = sdEllipsoid(eap, vec3(1.98, 1.4, 0.8)*1.17);
    ears = smax(-length(eap.xy + vec2(12.38, 0.12)) + 12.5, ears, 0.6);
    
    float f = sdEllipsoid(eap - vec3(-4.5, 0., 0.15), vec3(5.0, 5.0, 0.3));
    f = smax(ears, f, 0.2) - 0.03;
    
    
    ears = smax(-eap.z, abs(ears - 0.05) - 0.08, 0.35);
    ears = smin(f, ears, 0.02);
    
    return ears;
    /*
    vec3 pe = eap - vec3(1.3, -0.6, 0.3); 
    pe.xy = (mat2(187, -84, 84, 187)/ 205.0) * pe.xy;
    
    float pr1 = sdTriPrism(pe, vec2(1.5, 0.01));
      pr1 = smax(pe.x, pr1, 0.05);
    
    float pr2 = sdTriPrism(pe - vec3(0.15, 0.0, 0.0), vec2(1.2, 0.01));
    pr2 = smax(pe.x - 0.15, pr2, 0.05);
    
    return smin(ears, smin(pr1, pr2, 0.01) - 0.04, 0.01);*/
}

float sdCollar(vec3 p)
{
    vec3 cp = p - vec3(0.0, -1.4, -0.1);
    float collar = smax(abs(cp.y) - 0.01, length(cp.xz) - 1.3, 0.1) - 0.15;
    return collar;
}

float sdMedallion(vec3 p)
{
      vec3 mp = p - vec3(0.0, -2.0, -1.45);
    mp.z = abs(mp.z);
    float medallion = length(mp.xy) - 0.6;
    medallion = max(medallion, (length(mp - vec3(0.0,0.0,-1.25)) - 1.5));//, 0.03);
    
    
    float g = (length(mp.xy) - 0.23);
    g = min(max(mp.y, abs(mp.x) - 0.03), g);
    g = max((abs(medallion) - 0.1), g) - 0.01;
    medallion = smax(-g, medallion, 0.05);
    
    return medallion;
}

vec3 transformTail(vec3 p)
{
    p -= vec3(0.0, -3.7, 1.65);
    p.yz = (mat2(4, 3, -3, 4) / 5.0) * p.yz;
    return p;
}

float sdTailRod(vec3 p)
{
    return max(abs(p.z + 0.1) - 0.3, length(p.xy) - 0.06);
}

float sdTailSphere(vec3 p)
{
    return length(p - vec3(0.0, 0.0, 0.1)) - 0.3;
}

float sdFeet(vec3 p, float d)
{
    float s = abs(max(p.z, d)) - 0.1;
    s = max(abs(abs(p.x -0.7) - 0.2) - 0.0325, s);
    s = smax(p.y + 6., s, 0.05);
  
    return smax(-s, d, 0.02);
}

vec3 transformArms(vec3 p)
{
    vec3 ap = p - vec3(2.4, -4.2, -0.3);
    ap.xy = (mat2(187, -84, 84, 187)/ 205.0) * ap.xy;
    ap.xz = (mat2(4, 3, -3, 4) / 5.0) * ap.xz;
    
    const float k = -0.07;
    float c = cos(k*(p.y));
    float s = sin(k*(p.y));
    
    mat2  m = mat2(c,s,-s,c);
     ap = vec3(m*ap.yx,ap.z).yxz;
    
    return ap;
}
    
float sdArms(vec3 p)
{
       return sdRoundCone(p, 0.6, 0.3, 3.3);
}

float sdBodyBase(vec3 p)
{
    vec3 ubp = p - vec3(0.0, -4., -0.2);

    vec2 q = vec2(length(ubp.xz), ubp.y);  
    
    return sdRhombus(q, vec2(1.17, 6.0)) - 0.5;
}

float sdBody(vec3 p, float d)
{
    vec3 ubp = p - vec3(0.0, -4.2, -0.2);

    float body = d;
    float ls =  (length(ubp.xy - vec2(+6.2, -1.7)) - 5.975);
    ls = smin(-(ubp.y + 0.2), ls, 0.2);
   
    body = smax(ls, body, 0.2);

    body = smax(length(ubp.zy - vec2(5.8, 1.5)) - 7.0, body, 0.5);
    body = smax(-(length(ubp.zy - vec2(4.0, -2.5)) - 3.5), body, 0.5);
    body = smax((length(ubp.xy - vec2(-5.1, 0.3)) - 7.0), body, 0.5);
    //body = smax((length(ubp - vec3(-5.0, 0.3, 0.0)) - 7.0), body, 0.5);

    body = smax(-(ubp.y + 2.2), body, 0.1);
    
    return body;
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

//from http://iquilezles.org/www/articles/palettes/palettes.htm
vec3 color_palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 background(vec3 p)
{    
    vec2 uv = vec2((atan(p.z, p.x) + PI) * (21.0/(2.0*PI)), (21.0 * p.y) / (2.0*PI*20.0));
       vec2 id = vec2(floor(uv.x/1.5), 0.0);
    
    float ry = (hash23(vec3(id.x, 388.0, 342.0)).x - 0.5) * 2.0;
    
    uv.y += time*ry;
    id.y = floor(uv.y/1.5);

    vec2 t = hash23(vec3(id, 321.0));
    
    uv = vec2(mod(uv.x, 1.5) - 0.75, mod(uv.y, 1.5) - 0.75);
     
       float d0 = max(sdBox(uv, vec2(0.2, 0.4)) - 0.2, -(sdBox(uv, vec2(0.1, 0.3)) - 0.14));
    float d1 = sdBox(uv - vec2(0.0, 0.0), vec2(0.1, 0.6));
    
    float d = mix(d0, d1, step(t.x, 0.5));
    
    vec3 c = color_palette(t.x /** 0.5 + 1.52*/,
                        vec3(1.0), vec3(0.7), vec3(1.0), vec3(0.0, 0.333, 0.666));
    c *= smoothstep(0.1, 0.0, d);
    return (c*c)*0.8 + 0.1;
}

vec4 material(vec3 p)
{
    if (dot(p.xz, p.xz) > 19.0*19.0) return vec4(background(p), -1.0);
    
    p.x = abs(p.x);
    
    if (p.y+6.4 < 0.002) return vec4(0.56, 0.57, 0.58, 0.1)*0.5;
    
    if (p.y < -1.2) {
        if (p.z > 1.2) {
            if (sdTailSphere(transformTail(p)) < 0.002) {
                return vec4(0.93, 0.2, 0.3, 0.6);
            }
        }
           
        if (p.y > -2.6) {
            float collar = sdCollar(p);
            float medallion = smax(-collar, sdMedallion(p), 0.05);
            if (medallion < 0.002) return vec4(1.00, 0.71, 0.29, 0.05);
        
            if (collar < 0.002) return vec4(0.95, 0.2, 0.2, 0.7);
        }
        
        vec3 ap = transformArms(p);
        float arms = sdArms(ap);
        if (arms < 0.1) {
            float aoverlay = sdArmsOverlay(ap, arms);
            float arivetes = sdArmsRivetes(ap, aoverlay);;

            if (aoverlay < 0.002) return vec4(0.56, 0.57, 0.58, 0.1);
            if (arivetes < 0.002) return vec4(0.56, 0.57, 0.58, 0.3) *0.6;
        }
        
        vec3 lp = p - vec3(0.925, -5.1, 0.0);
        lp.xy = (mat2(-144, 17, 17, 144) / 145.0) * lp.xy;

        float body = sdBody(p, sdBodyBase(p));
        if (body < 0.1) {
            
            float feet = smax(lp.y + 0.3, body, 0.05);
            if (feet < 0.002) return vec4(0.56, 0.57, 0.58, 0.5);
            
            body = max(-(lp.y + 0.3), body);
            float boverlay = sdBodyOverlay(p, body);
            float brivetes = sdBodyRivetes(lp, boverlay);
            
            if (boverlay < 0.002) return vec4(0.56, 0.57, 0.58, 0.1);
            if (brivetes < 0.002) return vec4(0.56, 0.57, 0.58, 0.3) *0.6;
        }
    }
 
    if (p.y > -1.5 && p.z < 0.0) {
        vec3 hp = p - vec3(0.0, 1.0, 0.0);
        float head = sdHeadBase(hp);
        vec3 hrp = transformHeadSeam(hp);
        
        if (hrp.x - 0.3 < 0.0) {
            //return vec4(1.0);
            if (sdHeadRivetes(hrp, head) < 0.002) {
                return vec4(0.56, 0.57, 0.58, 0.3*0.6);
            }
        }
    }
    
    return vec4(0.91, 0.92, 0.92, 0.35);
}

float map(vec3 p)
{
    p.x = abs(p.x);
    
    float head = -(p.y + 1.3);
    if (head < 0.1) {
        vec3 hp = p - vec3(0.0, 1.0, 0.0);
        head = sdHeadBase(hp);
    
        if (head < 0.1 ) {
            head = sdHead(hp, head);
            if (p.z < 0.0) {
                vec3 st = transformHeadSeam(hp);
                float front = max(p.z + 0.15, head);
                if (st.x < 0.3) {
                    float hs = sdHeadSeam(st, front);
                    float hr = sdHeadRivetes(st, front);
                    head = smax(head, -hs, 0.02);
                    head = min(head, hr);
                }
                if (p.x < 1.0 && p.y < 0.5) {
                    float hm = sdMouthGap(hp, front);
                    head = smax(head, -hm, 0.02);
                }
            }
        }
    }
    
    float ears = length(p - vec3(2.2, 2.6, 0.0)) - 1.5;
    
    if (ears < 0.1) {
       ears = smin(head, sdEars(p - vec3(0.0, 1.0, 0.0)), 0.05);
    }
    
    head = min(head, ears);
    
    float bodys = -min( -(p.y + 1.2), p.y + 6.4) ;
    if (bodys < 0.1) {
          float bbody = sdBodyBase(p);
        float body = bbody;
        
        if (bbody < 0.1) {
            body = sdBody(p, bbody);
            if (body < 0.1) {
                vec3 lp = p - vec3(0.925, -5.1, 0.0);
                lp.xy = (mat2(-144, 17, 17, 144) / 145.0) * lp.xy;

                float feet = 1000.0;
                if (lp.y < 0.3) {
                    feet = smax((lp.y + 0.3), body, 0.06);
                    feet = max(sdFeet(p, feet), feet);
                }
                
                body = smax(-(lp.y + 0.3), body, 0.06);

                float boverlay = sdBodyOverlay(p, body);
                
                if (boverlay < 0.1) {
                    body = smax(-(boverlay - 0.03), body, 0.03);
                    body = min(boverlay, body);
                    body = min(sdBodyRivetes(lp, body), body);
                }
                
                body = min(feet, body);
            }
        }
        
        float collar = max(-p.y - 2.5, bbody - 0.3);
        if(collar < 0.1) {
               collar = sdCollar(p);
            float medallion = sdMedallion(p);
            collar = min(collar, smax(-collar, medallion, 0.05));
        }
        
        float tail = max(-(p.z - 1.3), body - 0.6);
        if (tail < 0.1) {
            vec3 tp = transformTail(p);
            tail = smin(body, sdTailRod(tp), 0.08);
            tail = min(tail, sdTailSphere(tp));
        }
        
        float arms = max(abs(p.z + 0.3) - 0.7, max(-(body + 0.1), bbody - 1.3));
        if (arms < 0.2) {
            vec3 ap = transformArms(p);
            arms = sdArms(ap);
            if (arms < 0.2) {
                float aoverlay = sdArmsOverlay(ap, arms);
                arms = smax(-(aoverlay - 0.02), arms, 0.02);
                arms = min(aoverlay, arms);
                   arms = min(arms, sdArmsRivetes(ap, arms)); 
            }
        }
        
        bodys = min(tail, min(arms, min(body, collar)));
    }
    
    
    float base = p.y + 6.4;
    if (base < 0.1) {
         base = smax(base, length(p.xz) - 3.4, 0.1);
    }
    
    return min(head, min(base, bodys));

}

vec4 eyes(vec2 uv)
{       
    float l = length(uv);
    vec2 uvw = fwidth(uv);
    float duv = max(uvw.x, uvw.y);
    
    
    if (l > 1.0 + duv + 0.02) return vec4(0.0);
    
    vec4 oc = vec4(vec3(0.0), smoothstep(0.01,duv+0.02, -l + 1.0));
    vec4 ic = vec4(vec3(1.0), smoothstep(0.01, duv+0.1, -l + 0.56));
    
    uv -= 0.5;
    
    float v = uv.y*10.0;
    const float k = 2.;
    float x = mod(time*35.0 + v, 45.)*0.01 + 1.5;
    float h = (2.0*sqrt(k)*x/(1.0+k*x*x)) * (((abs(sin(uv.y*40.0 + time*1.0))) * 0.25)) ;
    
    return vec4(mix(oc.rgb, ic.rgb, ic.a), min(1.0, oc.a*(h + 0.8)));
}

vec3 normal(vec3 p)
{
    const float e = 0.0001;
    const vec2 s = vec2(1.0, -1.0);
    
    return normalize( 
        s.xyy * map(p + s.xyy*e) + 
        s.yyx * map(p + s.yyx*e) + 
        s.yxy * map(p + s.yxy*e) + 
        s.xxx * map(p + s.xxx*e));
}

float ambient_occlusion(vec3 ro, vec3 n)
{   
    float occ = 0.0;
    float ff = 1.0;
    
    for( int i = 0; i < 5; ++i ){
        float d = 0.1 + 0.03*float(i);
        
        float sd = map(ro + n*d);
        
        occ += (sd - d)*-ff;
        ff *= 0.4;
    }
    
    return clamp(1.0 - 2.0*occ, 0.0, 1.0);    
}

float shadow_traversal(vec3 ro, vec3 rd)
{   
    float ci = cylIntersect(ro, rd, 3.5).y;
    
    float d = 0.0;
    float s = 1.0;
    
    for( int i = ZERO; i < 1 << 7; ++i ){
        float sd = map(ro + rd*d);
        
        if (sd < 0.001) return 0.0;
        
        d += sd;
        s = min(s, sd*64.0/d);
        
        if (d > ci || d > 10.) break;
    }
    
    return s;
}

float traversal(vec3 ro, vec3 rd)
{
    vec2 ci = cylIntersect(ro, rd, 3.5);
    
       float sd = max(0.0, ci.x);
    
    float d = 1000.0;
    for( int i = ZERO; i < 1 << 8; ++i ){
        if (d < 0.001 || sd > ci.y) break;
        
        d = map(ro + rd*sd);
        sd += d;
    }
    
    if (d < 0.001) return sd;
    
    return cylIntersect(ro, rd, 20.).y;
}

//from http://jcgt.org/published/0007/04/01/paper.pdf
vec3 ggx_vndf_normal(vec3 v, float alpha, vec2 xi)
{
    v = normalize(vec3(alpha*v.xz, v.y).xzy);

    vec3 t1 = v.y < 0.999 ? normalize(cross(v, vec3(0.0, 1.0, 0.0))) : vec3(0.0, 0.0, 1.0);
    vec3 t2 = cross(t1, v);
    
    float a = 1.0 / (1.0 + v.y);
    float r = sqrt(xi.x);
    float phi = (xi.y < a) ? (xi.y/a) * PI : PI + ((xi.y-a)/(1.0-a)) * PI; 
    
    float p1 = r*cos(phi);
    float p2 = r*sin(phi) * ((xi.y < a) ? 1.0 : v.y);

    vec3 n = p1*t1 + p2*t2 + sqrt(max(0.0, 1.0 - p1*p1 - p2*p2))*v;
    
    return normalize(vec3(alpha * n.xz, max(0.0, n.y)).xzy);
}

vec3 ggx_sample(vec3 ro, vec3 rd, vec3 n, vec4 mat)
{
    float a2 = mat.a*mat.a;
    
    mat3 b;
    b[0] = (abs(n.y) < 0.999) ? normalize(cross(n, vec3(0.0, 1.0, 0.0))) : vec3(0.0, 0.0, 1.0);
    b[1] = n;
    b[2] = normalize(cross(n, b[0]));

    vec3 v = rd*b;
    vec3 c = vec3(0.0);
    
    ro += n*0.01;
    for (int i = ZERO; i < REFLECTION_SAMPLES; ++i){
        
        vec2 xi = hash23( ro*500.0 + float(i));
        vec3 m = ggx_vndf_normal(-v, mat.a, xi.xy);
 
        vec3 r = reflect(v, m);
        
        float rdotm = max(0.0, dot(r, m)); 
    
        vec3 fr = mat.rgb;
        
        float g = (2.0 * rdotm) / (sqrt(1.0 + (a2*dot(r.xz, r.xz) / (r.y*r.y))) + 1.0); 
        
        vec3 sd = b*r;
        float d = abs(traversal(ro + sd*0.01, sd));
       
        vec3 p = ro + sd*(d+0.01);
        
        vec4 smat = material(p);
        
        if (smat.a > 0.0) {
            smat.rgb *= 0.25*ambient_occlusion(p, normal(p)) - xi.x*0.02; 
        }
        c += vec3(smat.rgb*g*fr);
    }
    
    return c.rgb/float(REFLECTION_SAMPLES);
}    
    
vec3 shade(vec3 p, vec3 rd, float d)
{
    const vec3 l = normalize(vec3(0.0, 2.0, -2.0));
    
    vec4 mat = material(p);
    if (mat.a < 0.0) return mat.rgb + pow(max(0.0, dot(l, rd)), 20.0);
    
    vec3 n = normal(p);
    
    vec3 h = normalize(l - rd);
    
    float ndotv = max(0.0, dot(n, -rd));
    float ndotl = max(0.0, dot(n, l));
    float ndoth = max(0.0, dot(n, h));
    
    float a = mat.a;
    float a2 = a*a;
    float dd = (ndoth*ndoth * (a2 - 1.0) + 1.0);
    float ggx_d = a2 / (PI * dd * dd);
    
    float r = a + 1.0;
    float k = (r*r) / 8.0;
    
    float ggx1 = ndotv / (ndotv * (1.0 - k) + k);
    float ggx2 = ndotl / (ndotl * (1.0 - k) + k);
 
    vec3 fr = mat.rgb;
       //vec3 fr = f0 + (max(vec3(1.0 - a), f0) - f0) * pow(1.0 - ndoth, 5.0);
    //fr = f0;
    
    vec3 spec = (ggx_d * ggx1 * ggx2 * fr) / 
        max(0.001, (4.0 * ndotv * ndotl));
    
    float s = shadow_traversal(p + l*0.05, l);
    float ao = ambient_occlusion(p, n);
    
    vec3 refc = ggx_sample(p, rd, n, mat); 
    
    return 0.6*spec*s*ndotl + ao*fr*0.25 + refc;
}

mat3 camera(vec3 p, vec3 t)
{
    vec3 uu = normalize(p - t);
    vec3 vv = normalize(vec3(uu.z, 0.0001, -uu.x));
    return mat3(vv, cross(uu, vv), uu);
}

void main(void)
{
    float e = 1.0/resolution.x;
    vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5) * e;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    vec3 t = vec3(0.0);
    vec3 ro = vec3(0.0);
   
    
    if (dot(m, m) < 0.001) {
        float k = time*0.8;
        
         m.xy = vec2(sin(k*0.5)*0.02 + 0.5, cos(k*0.4)*0.05 +  0.35);    
    }
    
    m.x = (m.x - 0.5)*(3.0*PI) + PI;
    
    ro = vec3(sin(m.x), sin(m.y)*0.75 - 0.2, cos(m.x))*25.0;
    mat3 cam = camera(ro, t);
    
    vec3 rd0 = cam * normalize(vec3(uv, -0.8));
    
    float d0 = traversal(ro, rd0);
    vec3 c = shade(ro + rd0*abs(d0), rd0, abs(d0));

#if AA > 0
        for (int i = ZERO; i < 1 << (AA << 1); ++i)
        {
            vec2 so = vec2(i & ((1 << AA) - 1), i >> AA) / float(1 << AA) - 0.5;
            vec3 rd = cam * normalize(vec3(uv + so * e, -0.8));

            float d = traversal(ro, rd);
            c += shade(ro + rd*d, rd, d);
        }
    
        c /= float((1 << (AA << 1)) + 1);
    }
#endif
   
    float ed = -(ro.z + 2.23)/rd0.z;
    vec2 ep = (ro + rd0*ed).xy;
    ep.x = abs(ep.x);
    ep = (ep * 1.38) - vec2(1.9, 1.75);
    vec4 ec = eyes(ep);
    c.rgb = mix(c.rgb, ec.rgb, step(ed, d0) * ec.a); 
        
    vec2 v = uv*0.5;
    c.rgb = clamp(c.rgb * (1.0 - dot(v, v)*10.0) , 0.0, 1.0);
    c.rgb += hash23(vec3(uv * 500.0, 221.0)).x * 0.005;
    
    glFragColor = vec4(pow(c.rgb, vec3(0.4545)), 1.0);
}
