#version 420

// original https://www.shadertoy.com/view/lsBBW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2017 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)

const vec3 ld = vec3(0.,1., .5);

float t = 0.;

vec2 m;

float fullAtan(vec2 p)
{
    return step(0.0,-p.x)*3.14159 + sign(p.x) * atan(p.x, sign(p.x) * p.y);
}

float shape(vec2 p)
{
    vec2 q = p;
    
    vec2 s = vec2(0.01,2); // 2d box size
    
    q.x += sin(q.y*5.)*.2 + sin(q.y*20.)*.1; // preturb box thickness along height
    
    return length(max(abs(q) - s, 0.)); // 2d iq box shape
}

vec2 df(vec3 p)
{
    float a = fullAtan(p.xz)*floor(m.x*10.) + time;
    
    vec2 rev = vec2(length(p.xz), p.y) - 2.5;
    
    rev *= mat2(cos(a),-sin(a),sin(a),cos(a));
    
    vec2 res = vec2(abs(shape(rev))-0.032, 0);
    //if (mouse*resolution.xy.z > 0.)
    //    if (p.z+m.y*10.-5. > res.x) 
    //        res = vec2(p.z+m.y*10.-5., 1);
    
    float plane = p.y+1.;
    if (plane < res.x)
        return vec2(plane,2);
        
    return res; 

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

// from iq code
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<1; i++ )
    {
        float h = df( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += h*.25;
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0., 1. );
}

// from iq code
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<10; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = df( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

//--------------------------------------------------------------------------
// Grab all sky information for a given ray from camera
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

void main(void)
{
    m = vec2(0.0);//mouse*resolution.xy.xy/resolution.xy;
    if (m.x == 0.) m.x = .1;
    
    glFragColor = vec4(1);
    
    vec2 g = gl_FragCoord.xy;
    vec2 si = resolution.xy;
    vec2 uv = (2.*g-si)/min(si.x, si.y);
    
    vec2 camp = vec2(.73,.37) * 5.;
    vec3 rayOrg = vec3(cos(1.57),sin(camp.y),sin(1.57)) * camp.x * 2.;
    vec3 camUp = vec3(0,1,0);
    vec3 camOrg = vec3(0,1.2,0);
    
    float fov = .5;
    vec3 axisZ = normalize(camOrg - rayOrg);
    vec3 axisX = normalize(cross(camUp, axisZ));
    vec3 axisY = normalize(cross(axisZ, axisX));
    vec3 rayDir = normalize(axisZ + fov * uv.x * axisX + fov * uv.y * axisY);
    
    float s = 0.;
    float d = 0.;
    vec3 p = rayOrg + rayDir * d;
    float dMax = 20.;
    
    for (float i=0.; i<250.; i++)
    {
        if (log(d*d/s/1e5)>0. || d>dMax) break;
        s = df(p).x;
        d += s * 0.2;
        p = rayOrg + rayDir * d;    
    }
    
    vec3 sky = GetSky(rayDir, ld, vec3(1.5));
    
    if (d<dMax)
    {
        vec3 n = nor(p, 0.001);
        
        // iq lighting
        float occ = calcAO( p, n );
        float amb = clamp( 0.5+0.5*n.y, 0.0, 1.0 );
        float dif = clamp( dot( n, ld ), 0.0, 1.0 ) * (df(p+n*1.16).x);
        float spe = pow(clamp( dot( rayDir, ld ), 0.0, 1.0 ),16.0);

        dif *= softshadow( p, ld, 0.1, 10. );

        vec3 brdf = vec3(0.0);
        brdf += 1.20*dif*vec3(1.00,0.90,0.60);
        brdf += 1.20*spe*vec3(1.00,0.90,0.60)*dif;
        brdf += 0.30*amb*vec3(0.50,0.70,1.00)*occ;
        brdf += 0.02;
        glFragColor.rgb *= brdf;

        glFragColor.rgb = mix( glFragColor.rgb, sky, 1.0-exp( -0.01*d*d ) ); 
    }
    else
    {
        glFragColor.rgb = sky;
    }
}
