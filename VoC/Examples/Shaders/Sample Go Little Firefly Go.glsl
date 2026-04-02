#version 420

// original https://www.shadertoy.com/view/WdsSR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - @Aiekick/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://www.shadertoy.com/view/WdsSR7

// click for have persistent light near the cam

const vec3 _smooth = vec3(0.1,0.1,0.1);
const float dist = 5.0;
const mat4 light = mat4(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1);
const vec3 pointColor = vec3(0.7,0.6,0.4);
const float pointLight = 0.001;
const float pointRadius = 3.;

//https://www.shadertoy.com/view/llj3Rz
float sphDistance( in vec3 ro, in vec3 rd, in vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float h = dot( oc, oc ) - b*b;
    return sqrt( max(0.0,h)) - sph.w;
}

//https://www.shadertoy.com/view/llj3Rz
float shpIntersect( in vec3 ro, in vec3 rd, in vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( rd, oc );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h>0.0 ) h = -b - sqrt( h );
    return h;
}

mat3 getRotXMat(float a){return mat3(1.,0.,0.,0.,cos(a),-sin(a),0.,sin(a),cos(a));}
mat3 getRotYMat(float a){return mat3(cos(a),0.,sin(a),0.,1.,0.,-sin(a),0.,cos(a));}
mat3 getRotZMat(float a){return mat3(cos(a),-sin(a),0.,sin(a),cos(a),0.,0.,0.,1.);}

// https://iquilezles.org/www/articles/smin/smin.htm
// polynomial smooth min (k = 0.1);
float sminPoly( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smin( float a, float b, float k )
{
    return sminPoly(a,b,k);
}

vec2 path(float t)
{
    return vec2(cos(t*0.08), sin(t*0.12)) * 4.;
}

// return color from temperature 
//http://www.physics.sfasu.edu/astro/color/blackbody.html
//http://www.vendian.org/mncharity/dir3/blackbody/
//http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html
vec3 blackbody(float Temp)
{
    vec3 col = vec3(255.);
    col.x = 56100000. * pow(Temp,(-3. / 2.)) + 148.;
       col.y = 100.04 * log(Temp) - 623.6;
       if (Temp > 6500.) col.y = 35200000. * pow(Temp,(-3. / 2.)) + 184.;
       col.z = 194.18 * log(Temp) - 1448.6;
       col = clamp(col, 0., 255.)/255.;
    if (Temp < 1000.) col *= Temp/1000.;
       return col;
}

float pattern(vec3 p)
{
    p = fract(p) - 0.5;
    return smin(smin(abs(p.x), abs(p.y), _smooth.y), abs(p.z), _smooth.y) + 0.56;
}

vec3 effect(vec3 p) 
{
    float time = 0.52;
    mat3 mx = getRotXMat(-7.*(sin(time*2.)*.5+.5));
    mat3 my = getRotYMat(-5.*(sin(time*1.5)*.5+.5));
    mat3 mz = getRotZMat(-3.*(sin(time)*.5+.5));
    
    mat3 m = mx*my*mz;
    
    float d = smin(smin(pattern(p*m), pattern(p*m*m), _smooth.x), pattern(p*m*m*m), _smooth.x);
    
    return vec3(d/0.94); 
}

vec4 displacement(vec3 p)
{
    vec3 col = 1.-clamp(effect(p*0.24),0.,1.);
       float dist = dot(col,vec3(1.));
    col = step(col, vec3(0.395));
    return vec4(dist,col);
}

vec4 map(vec3 p)
{
    p.xy -= path(p.z);
    
    p *= getRotZMat(p.z * 0.1);
    
    vec4 disp = displacement(p);
    float di = mix(0.8 + disp.x, 2.8 - disp.x, sin(p.z*0.3)*.5+.5);
    float sp = di - mix(length(p.xy), abs(p.y), sin(p.z*0.1)*.5+.5);
    return vec4(sp, disp.yzw);
}

///////////////////////////////////////////
//FROM IQ Shader https://www.shadertoy.com/view/Xds3zN
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos, float prec)
{
    vec3 eps = vec3( prec, 0., 0. );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

float SubDensity(vec3 surfPoint, float prec, float ms) 
{
    vec3 n;
    float s = 0.;
    const int iter = 10;
    for (int i=0;i<iter;i++)
    {
        n = calcNormal(surfPoint,prec); 
        surfPoint = surfPoint - n * ms; 
        s += map(surfPoint).x;
    }
    return 1.-s/(ms*float(iter));
}

float SubDensity(vec3 p, float s) 
{
    vec3 n = calcNormal(p,s);
    return map(p - n * s).x;
}

// from shane shaders
// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n )
{
    n = max((abs(n) - .2)*7., .001);
    n /= (n.x + n.y + n.z );  
    p = (texture2D(tex, p.yz)*n.x + texture2D(tex, p.zx)*n.y + texture2D(tex, p.xy)*n.z).xyz;
    return p*p;
}

// from shane shaders
// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to 
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 doBumpMap( sampler2D tx, in vec3 p, in vec3 n, float bf)
{
    const vec2 e = vec2(0.001, 0);
    mat3 m = mat3( tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
}

vec4 shade(vec3 ro, vec3 rd, float d, vec3 lp, float li)
{
    vec3 p = ro+rd*d;
    vec3 n = calcNormal(p, 0.1);
    float ao = calcAO(p, n);
    float sha = softshadow(p, normalize(lp-p), 0.8, 1.0);
    float sb = SubDensity(p, 0.01, 0.04);
    float sss = 1. - SubDensity(p, 8.);     
    float ks = map(lp).x;
    float kp = 0.0;
    const float nIter = 10.;
    for (float i=0.;i<nIter;i++)
        kp += (map(mix(lp,p,i/nIter/nIter)).x);
    float dCoef = dist;
    if (ks < 0.0)
    {
        dCoef *= clamp(kp/nIter*1.5,0.,1.);
        sha = 1.0;
    }
    else
    {
        dCoef *= 1.0;
    }
    float atten = clamp(dCoef-length(lp-p),0.0,10.0);
    vec3 bb = blackbody(80.*sb+320.);
    vec3 ld = normalize(lp-p);     
    n = vec3(0.0);//doBumpMap(iChannel0, p, n, 0.019);
    vec3 refl = reflect(rd,n);        
    float amb = 0.23;                                 
    float diff = clamp( dot( n, ld ), 0.0, 1.0 ) * sha + ao * 0.5; 
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4. ); 
    float spe = pow(clamp( dot( refl, ld ), 0.0, 1.0 ),16.);
    vec4 c = vec4(
        (diff + fre + bb.x * sss) * amb * li + spe, 
        (diff * pointColor + (1.-map(p).yzw*3.) + fre + bb * sb * 0.8 + sss * 0.4) * amb * li + spe * 0.6     
    );
    return c * atten;
}

float march(vec3 ro, vec3 rd, float rmPrec, float maxd, float mapPrec)
{
    float s = rmPrec;
    float d = 0.;
    for(int i=0;i<100;i++)
    {      
        if (d*d/s>1e5||s>maxd) break;
        s = map(ro+rd*d).x*mapPrec;
        d += s;
    }
    return d;
}

vec3 DrawPointLight(vec3 ro, vec3 rd, float d, vec3 lp, vec3 lc, float r)
{
    vec3 res = vec3(0);
    float pld = sphDistance( ro, rd, vec4(lp, r) );
    float plhit = shpIntersect( ro, rd, vec4(lp, r) );
    if (plhit > 0.0)
    {
        vec3 p = ro+rd*pld;
        float len = length(lp-p);
            
        if (d>len)
        {
            vec3 k = rd - normalize(lp-ro);
            res += lc * pointLight * (1.-pld / dot(k, k));
        }
    }
    return res;
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec2 s = resolution.xy;
    
    float t = time * 3.;
    vec3 ro = vec3(path(t),t);
    vec3 cu = vec3(0,1,0);
      vec3 cv = vec3(path(t+1.),t + 1.);
    
    vec3 col = vec3(0.);
    
    vec2 uv = (g+g-s)/s.y;
    
      vec3 rov = normalize(cv-ro);
    vec3 u = normalize(cross(cu,rov));
      vec3 v = cross(rov,u);
      vec3 rd = normalize(rov + uv.x*u + uv.y*v);
    
    float d = march(ro, rd, 0.01, 50., 0.6);
    
    float a = time * 1.5;
    vec3 lp0 = ro + vec3(cos(a),0.,sin(a) + 2.) * 2.;
    
    col += shade(ro, rd, d, lp0, 0.25).yzw;
    col += DrawPointLight(ro, rd, d, lp0, pointColor, pointRadius);
    
    glFragColor.rgb = mix(col, 1.-pointColor, 1.0-exp(-0.01*d*d));;
}
