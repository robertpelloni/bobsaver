#version 420

// original https://www.shadertoy.com/view/4lc3D2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2015 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)

mat3 RotZ(float a){return mat3(cos(a),-sin(a),0.,sin(a),cos(a),0.,0.,0.,1.);}    // get rotation matrix near z

float df(vec3 p)
{
    p *= RotZ(p.z*0.1);
    p = mod(p, 4.3)-0.5*4.3;
    float s = 1. - log((abs(p.y)) * 2.) - length(p.xz) ;
    return s;
}

vec3 nor( vec3 pos, float prec )
{
    vec3 eps = vec3( prec, 0., 0. );
    vec3 nor = vec3(
        df(pos+eps.xyy) - df(pos-eps.xyy),
        df(pos+eps.yxy) - df(pos-eps.yxy),
        df(pos+eps.yyx) - df(pos-eps.yyx) );
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
        s += df(surfPoint);
    }
    
    return 1.-s/(ms*float(iter)); // s < 0. => inside df
}

float SubDensity(vec3 p, float s) 
{
    vec3 n = nor(p,s);                             // precise normale at surf point
    return df(p - n * s);                        // ratio between df step and constant step
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec2 si = resolution.xy;
    
    vec2 uv = (g+g-si)/si.y;

    float time = -time;
    
    vec3 ro = vec3(0,0, time*5.);
    vec3 cv = ro + vec3(0,0,.1);
    
    vec3 lp = ro;
    
    vec3 cu = normalize(vec3(0,1,0));
      vec3 z = normalize(cv-ro);
    vec3 x = normalize(cross(cu,z));
      vec3 y = cross(z,x);
      vec3 rd = normalize(z + uv.x*x + uv.y*y);

    const float iter = 250.;
    
    float s = 1., d = 0.;
    for (float i=0.; i<iter; i++)
    {
        if (0.<0.01*log(d*d/s)) break;
        s = df(ro+rd*d);
        d += s * 0.1;
    }
    
    vec3 p = ro + rd * d;                                            // surface point
    vec3 ld = normalize(lp-p);                                         // light dir
    vec3 n = nor(p, 0.1);                                        // normal at surface point
    vec3 refl = reflect(rd,n);                                        // reflected ray dir at surf point 
    float diff = clamp( dot( n, ld ), 0.0, 1.0 );                     // diffuse
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4. );             // fresnel
    float spe = pow(clamp( dot( refl, ld ), 0.0, 1.0 ),16.);        // specular
    vec3 col = vec3(0,0.5,1);
    float sss = df(p - n * 0.2)/0.2;
    
    float sb = SubDensity(p, 0.01, 0.1);                            // deep subdensity (10 iterations)
    vec3 bb = blackbody(200. * sb + 200.);                                // bb
    float sss2 = 1. - SubDensity(p, 4.);                             // one step sub density of df
    
    vec3 a,b;
    a = 1.-(diff + fre + bb * sss2 * .8 + col * sss * .2) * 0.4 + spe;
    b = col * sss;
    
    glFragColor.rgb = mix(a, b, .9-exp(-0.01*d*d));
}

