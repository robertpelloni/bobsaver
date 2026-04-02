#version 420

// original https://www.shadertoy.com/view/XlVSDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2016 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)

mat3 RotZ(float a){return mat3(cos(a),-sin(a),0.,sin(a),cos(a),0.,0.,0.,1.);}

vec3 path(vec3 p)
{
    p *= RotZ(p.z * 0.1);
    p += sin(p.zxy * 0.5) * 0.5;
    p *= RotZ(p.z * 0.2);
    p *= RotZ(p.z * 0.01);
       return sin(p.zxy * 0.2) * 2.;
}

float wireShape(vec3 p, float df, float size, float thick, vec3 space) 
{
    return length(
        min(
            min(
                vec2(df - size,abs(p.y)-space.y),
                vec2(df - size,abs(p.z)-space.z)
            ),
            vec2(df - size,abs(p.x)-space.x)
        )
    ) - thick;
}

float thick = 0.05;
float space = 0.5;
float radius = 2.;
float dist = 0.;
    
float df(vec3 p)
{
    p += path(p);
    p.z = mod(p.z,space)-space*.5;
    dist = max(abs(p.x),abs(p.y));
    dist += length(p);
    dist += max(abs(p.y)+p.x,-p.x);
    dist += abs(p.y);
    return wireShape(p, dist, radius, thick, vec3(0.15));
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
    const int iter = 3;
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
    return df(p - n * s)/s;                        // ratio between df step and constant step
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec2 si = resolution.xy;
    
    vec2 uv = (g+g-si)/si.y;

    float time = time*2.5*(sin(time*0.01)*.5+.5);
    
    vec3 ro = vec3(0,0, time*5.);
    ro -= path(ro);
    
    vec3 cv = ro + vec3(0,0,4); // cam view
    
    //cv -= path(cv);
    
    vec3 lp = ro;    // light pos
    
    vec3 cu = normalize(vec3(0,1,0));
      vec3 z = normalize(cv-ro);
    vec3 x = normalize(cross(cu,z));
      vec3 y = cross(z,x);
      vec3 rd = normalize(z + uv.x*x + uv.y*y);

    float s = 1., d = 0.;
    for (int i=0; i<100; i++) 
    {
        if (log(d*d/s/1e6)>0.|| d > 100.) break; 
        d += (s = df(ro+rd*d))*0.2;
    }
    
    vec3 p = ro + rd * d;                                            // surface point
    vec3 ld = normalize(lp-p);                                         // light dir
    vec3 n = nor(p, 0.1);                                            // normal at surface point
    vec3 refl = reflect(rd,n);                                        // reflected ray dir at surf point 
    float diff = clamp( dot( n, ld ), 0.0, 1.0 );                     // diffuse
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4. );             // fresnel
    float spe = pow(clamp( dot( refl, ld ), 0.0, 1.0 ),16.);        // specular
    vec3 col = vec3(0.8,0.5,0.2);
    float sss = df(p - n*0.001)/0.01;                                // quick sss 0.001 of subsurface
    
    float sb = SubDensity(p, 0.01, 0.01);                            // deep subdensity 
    vec3 bb = clamp(blackbody(100. * sb),0.,1.);                    // blackbody color
    float sss2 = 1.0 - SubDensity(p, 1.5);                             // one step sub density of df of 1.5 of subsurface
    
    vec3 a = (diff + fre + bb * sss * .8 + col * sss * .2) * 0.35 + spe;
    vec3 b = col * sss2;
    
    glFragColor.rgb = mix(a, b, .8-exp(-0.005*d*d));
    glFragColor.a = 1.;
}

