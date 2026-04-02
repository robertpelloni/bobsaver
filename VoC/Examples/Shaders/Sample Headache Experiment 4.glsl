#version 420

// original https://www.shadertoy.com/view/MslyWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2017 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)

vec2 df(vec3 p)
{
    p.y -= sin(p.z*0.05)*4.;
    float a = p.z * 0.01 * atan(p.x,p.y)/3.14159;
    p.xy *= mat2(cos(a),-sin(a),sin(a),cos(a));
    p = mod(p,6.)-3.;
    p += sin(p*3.)*1.2;
    float cyl = min(min(length(p.xy),length(p.xz)),length(p.yz));
    return vec2(cyl-0.4, 0);
}

vec3 nor( vec3 p, float prec )
{
    vec2 e = vec2( prec, 0. );
    vec3 n = vec3(
        df(p+e.xyy).x - df(p-e.xyy).x,
        df(p+e.yxy).x - df(p-e.yxy).x,
        df(p+e.yyx).x - df(p-e.yyx).x );
    return normalize(n);
}

// from Dave Hoskins // https://www.shadertoy.com/view/Xsf3zX
vec3 GetSky(in vec3 rd, in vec3 sunDir, in vec3 sunCol)
{
    float sunAmount = max( dot( rd, sunDir), 0.0 );
    float v = pow(1.0-max(rd.y,0.0),6.);
    vec3  sky = mix(vec3(.1, .2, .3), vec3(.32, .32, .32), v);
    sky = sky + sunCol * sunAmount * sunAmount * .25;
    sky = sky + sunCol * min(pow(sunAmount, 800.0)*1.5, .3);
    return clamp(sky, 0.0, 1.0);
}

float SubDensity(vec3 p, float ms) 
{
    return df(p - nor(p,0.0001) * ms).x/ms;
}

vec2 shade(vec3 ro, vec3 rd, float d, vec3 lp, vec3 ldo, float li)
{
    vec3 p = ro + rd * d;
    vec3 n = nor(p, 0.1);
    vec3 ldp = normalize(lp-n*1.5-p);
    vec3 refl = reflect(rd,n);
    float amb = 0.6;
    float diff = clamp( dot( n, ldp ), 0.0, 1.0);
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4.);
    float spe = pow(clamp( dot( refl, ldo ), 0.0, 1.0 ), 16.);
    float sss = 1. - SubDensity(p, 0.1);
    return vec2(
        (diff + fre + spe) * amb * li,
        (diff + fre + sss) * amb * li + spe
    );
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    float t = time * 15.;

    vec3 ld = vec3(0.,1., .5);
    
    vec3 ro = vec3(0,sin(t*0.05)*4.,t);
    vec3 cu = vec3(0,1,0);
    vec3 tg = ro + vec3(0,0,.1);
    
    float fov = .5;
    vec3 z = normalize(tg - ro);
    vec3 x = normalize(cross(cu, z));
    vec3 y = normalize(cross(z, x));
    vec3 rd = normalize(z + fov * (uv.x * x + uv.y * y));
    
    float s = 1., d = 1.;
    float dm = 50.;
    
    for (float i=0.; i<250.; i++)
    {
        if (log(d*d/s/1e5)>0. || d>dm) break;
        d += (s = df(ro + rd * d).x) * .3;
    }
    
    glFragColor.rgb = GetSky(rd, ld, vec3(1.5));
    
    if (d<dm)
    {
        vec2 sh = shade(ro, rd, d, ro, ld, 1.);
        glFragColor.rgb = mix( 
            vec3(.49,1,.32) * sh.y * .6 + vec3(.45,0,.72) * sh.x * 1.2, 
            glFragColor.rgb, 
            1.0 - exp( -0.001*d*d ) ); 
    }
}
