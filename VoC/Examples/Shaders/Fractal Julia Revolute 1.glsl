#version 420

// original https://www.shadertoy.com/view/4sXczN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2017 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)

vec3 mat = vec3(28,250,43)/255.;                                    

const vec3 ld = vec3(0.,1., .5);

float t = 0.;

float fullAtan(vec2 p)
{
    return step(0.0,-p.x)*3.1415926535 + sign(p.x) * atan(p.x, sign(p.x) * p.y);
}

float fractus(vec2 p, vec2 v)
{
    vec2 z = p;
    vec2 c = v;
    float k = 1., h = 1.0;    
    for (float i=0.;i<20.;i++)
    {
        h *= 4.*k;
        k = dot(z,z);
        if(k > 4.) break;
        z = vec2(z.x * z.x - z.y * z.y, 2. * z.x * z.y) + c;
    }
    return sqrt(k/h)*log(k);   
}

vec2 df(vec3 p)
{
    float a = fullAtan(p.xz)*0.5 + time * 0.5;
    
    vec2 rev = vec2(length(p.xz),p.y) - 1.7;
    rev *= mat2(cos(a),-sin(a),sin(a),cos(a));
    
    float ftus = fractus(rev, vec2(-0.2,-0.688));
    vec2 res = vec2(ftus, 0);
    
    if (p.z > res.x)
        res = vec2(p.z, 1);
        
    return res;
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

vec3 nor( vec3 p , vec3 e)
{
    return normalize(vec3(                                            
        df(p+e.xyy).x - df(p-e.xyy).x,                                
        df(p+e.yxy).x - df(p-e.yxy).x,                                
        df(p+e.yyx).x - df(p-e.yyx).x ));                            
}

float SubDensity(vec3 p, float s) 
{
    vec3 n = nor(p,vec3( 0.0001, 0, 0));                             
    return df(p - n * s).x/s;                                        
}

vec2 shade(vec3 ro, vec3 rd, float d, vec3 lp, float li)
{
    vec3 p = ro + rd * d;                                            
    vec3 ld = normalize(lp-p);                                         
    vec3 n = nor(p, vec3( 0.0001, 0, 0));                            
    vec3 refl = reflect(rd,n);                                        
    float amb = 0.132;                                                 
    float diff = clamp( dot( n, ld ), 0.0, 1.0 );                     
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4. );             
    float spe = pow(clamp( dot( refl, ld ), 0.0, 1.0 ),16.);        
    float sss = 1. - SubDensity(p, 1.);                             
    return vec2(
        (diff + fre + spe) * amb * li,                                 
        (diff + fre + sss) * amb * li + spe                         
    );
}

void main(void)
{
    glFragColor = vec4(1);
    
    vec2 g = gl_FragCoord.xy;
    vec2 si = resolution.xy;
    vec2 uv = (2.*g-si)/min(si.x, si.y);
    
    t = 1.57;
    
    vec2 camp = vec2(.74,.55) * 5.;
    vec3 rayOrg = vec3(cos(t),sin(camp.y),sin(t)) * camp.x;
    vec3 lpi = vec3(-cos(t),sin(camp.y),-sin(t)) * camp.x;

    vec3 camUp = vec3(0,1,0);
    vec3 camOrg = vec3(0,1.76,0);
    
    float fov = .5;
    vec3 axisZ = normalize(camOrg - rayOrg);
    vec3 axisX = normalize(cross(camUp, axisZ));
    vec3 axisY = normalize(cross(axisZ, axisX));
    vec3 rayDir = normalize(axisZ + fov * uv.x * axisX + fov * uv.y * axisY);
    
    float s = 1.;
    float d = 0.;
    vec3 p = rayOrg + rayDir * d;
    float dMax = 20.;
    
    for (float i=0.; i<150.; i++)
    {
        if (log(d*d/s/1e5)>s || d>dMax) break;
        s = df(p).x;
        d += s * 0.2;
        p = rayOrg + rayDir * d;    
    }
    
    if (d<dMax)
    {
        vec3 p = rayOrg + rayDir * d;
        float m = df(p).y;
        if (m < 0.5)
        {
            vec3 n = nor(p, vec3( 0.1, 0, 0));    
            glFragColor.rgb = GetSky(reflect(n,rayDir), ld, vec3(50)) * .2 + vec3(73,28,94)/255. * .8;
        }
        else if (m < 1.5)
        {
            glFragColor.rgb = mix(
                shade(p, rayDir, 1., lpi, 5.).y * mat,                         
                shade(rayOrg, rayDir, d, rayOrg, 1.).x * (mat+0.5),                 
            .5);
        }
    }
    else
    {
        glFragColor.rgb = GetSky(rayDir, ld, vec3(50));
    }
}
