#version 420

// original https://www.shadertoy.com/view/lljyWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2016 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)
// link : https://www.shadertoy.com/view/XlcGzn

float fullAtan(vec2 p)
{
    return step(0.0,-p.x)*3.1415926535 + sign(p.x) * atan(p.x, sign(p.x) * p.y);
}

float fractus(vec2 p, vec2 v)
{
    vec2 z = p;
    vec2 c = v;
    float k = 1., h = 1.0;    
    float t = (sin(time * .5)*.5+.5) * 5.;
    for (float i=0.;i<5.;i++)
    {
        if (i > t) break;
        h *= 4.*k;
        k = dot(z,z);
        if(k > 4.) break;
        z = vec2(z.x * z.x - z.y * z.y, 2. * z.x * z.y) + c;
    }
    float d = sqrt(k/h)*log(k);
    
    // next iteration
    if (k > 4.)
        z = vec2(z.x * z.x - z.y * z.y, 2. * z.x * z.y) + c;
    h *= 4.*k;
    k = dot(z,z);
    float d1 = sqrt(k/h)*log(k);
    
    // df blending
    return mix(d, d1, fract(t));
}

vec2 dfFractus(vec3 p)
{
    float a = fullAtan(p.xz); // axis y
    
    vec2 c;
    c.x = mix(0.2, -0.5, sin(a * 2.));
    c.y = mix(0.5, 0.0, sin(a * 3.));
    
    float path = length(p.xz) - 3.;
    
    vec2 rev = vec2(path, p.y);
    float aa = a + time;
    rev *= mat2(cos(aa),-sin(aa),sin(aa),cos(aa)); // rot near axis y
    
    return vec2(fractus(rev, c) - 0.1, 2);
}

vec2 df(vec3 p)
{
    return dfFractus(p);
}

vec3 nor( in vec3 pos, float prec )
{
    vec3 eps = vec3( prec, 0., 0. );
    vec3 nor = vec3(
        df(pos+eps.xyy).x - df(pos-eps.xyy).x,
        df(pos+eps.yxy).x - df(pos-eps.yxy).x,
        df(pos+eps.yyx).x - df(pos-eps.yyx).x );
    return normalize(nor);
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

// get density of the df at surfPoint
// ratio between constant step and df value
float SubDensity(vec3 surfPoint, float prec, float ms) 
{
    vec3 n;
    float s = 0.;
    const int iter = 10;
    for (int i=0;i<iter;i++)
    {
        n = nor(surfPoint,prec); 
        surfPoint = surfPoint - n * ms; 
        s += df(surfPoint).x*1.5;
    }
    return 1.-s/(ms*float(iter)); // s < 0. => inside df
}

float SubDensity(vec3 p, float s) 
{
    vec3 n = nor(p,s);                             // precise normale at surf point
    return df(p - n * s).x;                        // ratio between df step and constant step
}

// from shane sahders
// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n )
{
    n = max((abs(n) - .2)*7., .001);
    n /= (n.x + n.y + n.z );  
    p = (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
    return p*p;
}

// from shane sahders
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
    vec3 p = ro + rd * d;                                            // surface point
    float sb = SubDensity(p, 0.01, 0.03);                            // deep subdensity (10 iterations)
    vec3 bb = blackbody(80.*sb+320.);                                // bb
    vec3 ld = normalize(lp-p);                                         // light dir
    vec3 n = nor(p, 0.1);                                            // normal at surface point
    //n = doBumpMap(iChannel0, p, n, 0.019);
    vec3 refl = reflect(rd,n);                                        // reflected ray dir at surf point 
    float amb = 0.23;                                                 // ambiance factor
    float diff = clamp( dot( n, ld ), 0.0, 1.0 );                     // diffuse
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4. );             // fresnel
    float spe = pow(clamp( dot( refl, ld ), 0.0, 1.0 ),16.);        // specular
    float sss = 1. - SubDensity(p,8.);                             // one step sub density of df
    return vec4(
        (diff + fre + bb.x * sss * 0.5) * amb * li + spe * 1.2, 
        (diff + fre + bb * sb * 0.8 + sss * 0.5) * amb * li + spe * 1.2     
    );
}

vec3 cam(vec2 uv, vec3 ro, vec3 cv, float t)
{
    vec3 cu = normalize(vec3(0,1,0));
      vec3 z = normalize(cv-ro);
    vec3 x = normalize(cross(cu,z));
      vec3 y= cross(z,x);
      return normalize(z + uv.x*x + uv.y*y);
}

void main(void)
{
    float t = time;
    
    float ca = 0.;
    float cd = 2.4;
    float ce = 2.;
    
    vec2 si = resolution.xy;
    vec2 uv = (2.*gl_FragCoord.xy-si)/si.y;

    vec3 ro = vec3(cos(ca),ce,sin(ca)) * cd;
      vec3 cv = vec3(0,-3,0);
    vec3 rd = cam(uv, ro, cv, t);
       
    float md = 15., s = 1., d = 1.;
    
    const float iter = 250.;
    for(float i=0.;i<iter;i++)
    {      
        if (s<0.2*log(d*d/s/500.)||d>md) break;
        s = df(ro+rd*d).x;
        d += s *0.2;
    }
    
    if (d<md)
        glFragColor.rgb = mix(
            shade(ro, rd, d, ro, 1.2).yzw, 
            vec3(0), 
            1.-exp(-0.02*d*d));
}
