#version 420

// original https://www.shadertoy.com/view/lsXcRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - @Aiekick/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)

float camd;
    
mat3 RotX(float a){a = radians(a); return mat3(1.,0.,0.,0.,cos(a),-sin(a),0.,sin(a),cos(a));}
mat3 RotY(float a){a = radians(a); return mat3(cos(a),0.,sin(a),0.,1.,0.,-sin(a),0.,cos(a));}
mat3 RotZ(float a){a = radians(a); return mat3(cos(a),-sin(a),0.,sin(a),cos(a),0.,0.,0.,1.);}
    
/* original
float fullAtan(vec2 p)
{
    float a = 0.;
    if (p.x >= 0.) a = atan(p.x, p.y);
    if (p.x < 0.) a = 3.14159 - atan(p.x, -p.y);
    return a;
}*/

/* thanks to 4onen */
float fullAtan(vec2 p)
{
    return step(0.0,-p.x)*3.1415926535 + sign(p.x) * atan(p.x, sign(p.x) * p.y);
}

float shape(vec2 p)
{
    return length(p); // cylindric revolute
    //return max(abs(p.x), abs(p.y)); // quad revolute
    //return max(abs(p.x)+p.y,-p.y); // trianular revolute
}

vec2 Whorl(vec3 p)
{
    float a = fullAtan(p.xz)*16.; // axis y
    
    vec2 q = vec2(shape(p.xz),p.y) + vec2(-2., -0.25); // torus base space formula
    
    q *= mat2(cos(a),-sin(a),sin(a),cos(a)); // rot near axis y
    
    float interior = length(q-vec2(mix(0.32,1.,sin(time * .5)*.5 + .5), 0)) - .72;
    vec2 res = vec2(interior, 1.);
    
    float exterior = length(q) -.38;
    if (res.x < exterior)
        res = vec2(exterior, 2.);
    
    return res;
}

vec2 df(vec3 p)
{
    float plane = p.y + 8.;
    vec2 res = vec2(plane, 0.);
    p *= RotX(time * 75.) * RotY(time * 50.) * RotZ(time * 25.);
    vec2 obj = Whorl(p);
    if (obj.x < res.x)
        res = obj;
    return res;
}

//FROM IQ Shader https://www.shadertoy.com/view/Xds3zN
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<100; i++ )
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
    vec3 n = nor(p, 0.01);
    vec3 refl = reflect(rd,n);
    float diff = clamp( dot( n, ld ), 0.0, 1.0 );
    float sha = softshadow( p, ld, 0.5, 50. );
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4. );
    float spe = pow(clamp( dot( refl, ld ), 0.0, 1.0 ),16.);
    return ((diff * sha + fre + spe) * lc * li + spe) * sha;
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec2 si = resolution.xy;
    vec2 uv = (g+g-si)/si.y;

    
    camd = 3.;
    //if (mouse*resolution.xy.z > 0.)
    //{
    //    camd = 20. * mouse*resolution.xy.y / si.y; // distance to origin axis
    //}
    
    vec3 ro = vec3(cos(4.4), sin(2.2), sin(4.4)) * camd;
      vec3 rov = normalize(vec3(0)-ro);
    vec3 u = normalize(cross(vec3(0,1,0),rov));
      vec3 v = cross(rov,u);
      vec3 rd = normalize(rov + uv.x*u + uv.y*v);
    
    float s = 1.;float d = 0.;
    for(int i=0;i<100;i++)
    {      
        if (0.<log(d/s/1e5)) break;
        s = df(ro+rd*d).x;
        d += s * 0.5;
    }
   
    vec3 lp0 = ro;
    
    vec3 lc = vec3(0);
    float mat = df(ro+rd*d).y;
    if (mat < 2.5) lc = vec3(0.5,0.2,0.8);
    if (mat < 1.5) lc = vec3(0.2,0.5,0.8);
    if (mat < 0.5) lc = vec3(0.8,0.5,0.2);

    glFragColor.rgb = shade(ro, rd, d, lp0, lc, 2.);
}
