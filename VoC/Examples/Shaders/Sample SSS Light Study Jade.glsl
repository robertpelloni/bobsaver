#version 420

// original https://www.shadertoy.com/view/3lsXzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2019 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via NoodlesPlate (https://github.com/aiekick/NoodlesPlate/releases)

mat3 RotZ(float a){return mat3(cos(a),-sin(a),0.,sin(a),cos(a),0.,0.,0.,1.);}

vec2 path(float t)
{
    return vec2(cos(t*0.2), sin(t*0.2)) * 2.;
}

float coefFromRGB(vec3 rgb)
{
    vec3 wl = vec3(564.,533.,437.);
    return length(wl * rgb) / length(wl);
}

vec2 df(vec3 p)
{
    p *= RotZ(p.z*0.4);
    p += (sin(p.zxy * 0.8) + sin(p.xzy * 0.9)) * 2.5;
    return vec2(length(p)-3., 2.);
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
        s += df(surfPoint).x;
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

vec3 shade(vec3 ro, vec3 rd, float d, vec3 lp, float li)
{
    vec3 p = ro + rd * d;                                            // surface point
    float sb = SubDensity(p, 0.01, 0.076);                            // deep subdensity (10 iterations)
    vec3 bb = blackbody(100.*sb+100.).brg;                                // bb
    vec3 ld = normalize(lp-p);                                         // light dir
    vec3 n = nor(p, 0.1);    // normal at surface point
    
    // derived from bumpmap func from shane
    const vec2 e = vec2(0.1, 0);
    mat3 m = mat3(0,0,0,0,0,0,0,0,0);//mat3( tex3D(iChannel0, e.xyy, n), tex3D(iChannel0, e.yxy, n), tex3D(iChannel0, e.yyx, n));
       vec3 g = vec3(1) * m * 20.;
    g -= n * dot(n, g);
    n =  normalize( n + g );
    
    vec3 refl = reflect(rd,n);                                        // reflected ray dir at surf point 
    float amb = 0.1242;                                                 // ambiance factor
    float diff = clamp( dot( n, ld ), 0.0, 1.0 );                     // diffuse
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4. );             // fresnel
    float spe = pow(clamp( dot( refl, ld ), 0.0, 1.0 ),16.);        // specular
    float sss = 1. - SubDensity(p, 7.8);                             // one step sub density of df
    vec3 col = (diff + fre + bb * sb * 0.608 + sss * 0.352) * amb * li + spe * 0.612;
    
    return mix(col, vec3(1), vec3(coefFromRGB(bb*0.8+0.1*diff + 0.1 *spe)));
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
    float t = -time*2.;

    vec2 si = resolution.xy;
    vec2 uv = (2.*gl_FragCoord.xy-si)/si.y;
    
    vec3 col = vec3(1);
    
    float ca = time;
    float ce = 0.5;
    float cd = 10.;
    
    vec3 ro = vec3(cos(ca), sin(ce), sin(ca)) * cd;
      vec3 cv = vec3(0);
    vec3 rd = cam(uv, ro, cv, t);
       
    float md = 20.;
    float s = 1.;
    float d = 1.;
    float ac = 0.0;
    
    const float iter = 250.;
    for(float i=0.;i<iter;i++)
    {      
        if (abs(s)<d*d*1e-6||d>md) break;
        s = df(ro+rd*d).x;
        s = max(s, 0.01);
        d += s * 0.1;
    }
    
    if (d<md)
    {
        vec3 p = ro+rd*d;

        col = shade(ro, rd, d, ro, 1.0);
    }
    else
    {
        col = vec3(0);
    }   
    
    col = mix(col, vec3(0), 1.-exp(-0.005*d*d));
    
    glFragColor.rgb = col;
}
