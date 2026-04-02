#version 420

// original https://www.shadertoy.com/view/ltG3Rm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - @Aiekick/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)

float shape,camd;
    
mat3 RotX(float a){a = radians(a); return mat3(1.,0.,0.,0.,cos(a),-sin(a),0.,sin(a),cos(a));}
mat3 RotY(float a){a = radians(a); return mat3(cos(a),0.,sin(a),0.,1.,0.,-sin(a),0.,cos(a));}
mat3 RotZ(float a){a = radians(a); return mat3(cos(a),-sin(a),0.,sin(a),cos(a),0.,0.,0.,1.);}

const mat3 mx = mat3(0,0,0,0,2.6,0,0,0,2.6);
const mat3 my = mat3(2.6,0,0,0,0,0,0,0,2.6);
const mat3 mz = mat3(2.6,0,0,0,2.6,0,0,0,0);

// base on shane tech in shader : One Tweet Cellular Pattern
float func(vec2 p)
{
    p/=21.952;
    // One Tweet Cellular Pattern : https://www.shadertoy.com/view/MdKXDD
    return length(fract(p*=mat2(20., -10., 10., 20.)*.1) - .5);
}

vec3 effect(vec3 p)
{
    return vec3(min(min(func((p*mx).yz), func((p*my).xz)), func((p*mz).xy))/0.57);
}

vec4 displacement(vec3 p)
{
    vec3 col = 0.2-clamp(effect(p*2.),0.,1.);
       float dist = dot(col,vec3(0.1));
    col = step(col, vec3(0.));
    return vec4(dist,col);
}

vec4 df(vec3 p)
{
    vec4 plane = vec4(p.y + 8., vec3(0));
    p *= RotX(time * 100.) * RotY(time * 75.) * RotZ(time * 50.);
    vec4 disp = displacement(p);
    p = abs(p);
    float cube = max(p.x, max(p.y, p.z));
    float sp = length(p);
    vec4 obj = vec4(mix(cube, sp, shape) - 4.5 + disp.x, disp.yzw);
    if (obj.x < plane.x)
        return obj;
    return plane;
}

//FROM IQ Shader https://www.shadertoy.com/view/Xds3zN
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<80; i++ )
    {
        float h = df( ro + rd*t ).x;
        res = min( res, 8.*h/t );
        t += clamp( h, 0.01, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 nor( vec3 pos, float prec )
{
    vec3 eps = vec3( prec, 0., 0. );
    vec3 nor = vec3(
        df(pos+eps.xyy).x - df(pos-eps.xyy).x,
        df(pos+eps.yxy).x - df(pos-eps.yxy).x,
        df(pos+eps.yyx).x - df(pos-eps.yyx).x );
    return normalize(nor);
}

vec3 shade(vec3 ro, vec3 rd, float d, vec3 lp, vec3 lc, float li)
{
    vec3 p = ro + rd * d;
    vec3 ld = normalize(lp-p);
    vec3 n = nor(p, 0.1);
    vec3 refl = reflect(rd,n);
    float amb = 0.6;
    float diff = clamp( dot( n, ld ), 0.0, 1.0 );
    float sha = softshadow( p, ld, 0.01, 50. );
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4. );
    float spe = pow(clamp( dot( refl, ld ), 0.0, 1.0 ),16.);
    return ((diff * sha + fre + spe) * amb * lc * li + spe) * sha;
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec2 si = resolution.xy;
    vec2 uv = (g+g-si)/si.y;

    shape = 0.3;
    camd = 13.;
    //if (mouse*resolution.xy.z > 0.)
    //{
        shape = mouse.x*resolution.x / si.x * 2. - 1.;
        camd = 20. * mouse.y*resolution.y / si.y; // distance to origin axis
    //}
    
    vec3 ro = vec3(cos(4.4), sin(2.2), sin(4.4)) * camd;
      vec3 rov = normalize(vec3(0)-ro);
    vec3 u = normalize(cross(vec3(0,1,0),rov));
      vec3 v = cross(rov,u);
      vec3 rd = normalize(rov + uv.x*u + uv.y*v);
    
    float s = 1.;float d = 0.;
    for(int i=0;i<30;i++)
    {      
        if (0.<log(d/s/1e3)) break;
        s = df(ro+rd*d).x;
        d += s;
    }
   
    vec3 lp0 = vec3(cos(time), 10., sin(time)); lp0.xz *= 20.;
    vec3 lp1 = vec3(cos(time + 1.6), 10., sin(time + 1.6)); lp1.xz *= 15.;
    vec3 lp2 = vec3(cos(time + 3.12), 10., sin(time + 3.12)); lp2.xz *= 10.;
    
    vec3 ca = shade(ro, rd, d, lp0, vec3(1,0.49,0.22), 5.);
    vec3 cb = shade(ro, rd, d, lp1, vec3(0,0.33,0.56), 5.);
    vec3 cc = shade(ro, rd, d, lp2, vec3(0,0.69,0.31), 5.);

    glFragColor.rgb = mix((ca+cb+cc)/3., df(ro+rd*d).yzw, 0.5);
}
