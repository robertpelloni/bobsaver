#version 420

// original https://www.shadertoy.com/view/WtjGDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - @Aiekick/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// coded with NoodlesPlate https://github.com/aiekick/NoodlesPlate/releases

// I searched a way for repeat analytics primitive like we do in raymarched stuff
// I though, i could find a voxel, where i can calculate distance with the 
// voxel center of the current point
// i tried 3 planes intersection at first, very buggy on some hits and camera angle
// after few simplication, i discovered that code :)

// and in the same time i gain understanding of many voxel demo
// available on this site :) finally

// reinvent the weel for gain understanding, is my technic lol
// btw i not understanding all the bugs i have with :

// noise with many reflections and other shapes
// the goursat shape or torus give many noise at 5-6 layer of the eye..
// maybe normal precision but also due to my mixing reduction (transfer var) or other ?

// i would like to create a truchet demo with a maybe 5-6 refraction
// (The interest of the raycasting is the cost, so have many reflections can be cool)
// but i failed to have good shapes when i decentered torus :)

// if you have idea of better lighting, please share :)

// :)

#define AA 1

// try with 5, for seeing the balls appearing :)
#define layers 80

#define primitiveRadius 0.5
#define voxelSize vec3(2.0)

// I got 60 fps with 20 reflections  with AA 1:) but not interesting visually
#define countReflections 3
#define transfer 5.

#define eliRadius primitiveRadius * vec3(sin(vc)*0.25+0.75)
#define torRadius primitiveRadius * vec2(1, 0.2)

// with other primitives than sphere or ellipsoid
// the reflections count cause noise issues (normal precision i thinck)
// so maybe put countReflections at 0 or tune transfer

vec3 camera(vec2 uv, vec3 ro, vec3 tgt)
{
    vec3 z = normalize(tgt-ro);
    vec3 x = normalize(cross(vec3(0,1,0),z));
    vec3 y = cross(z, x);
    return normalize(uv.x*x+uv.y*y+z);
}

vec3 path(float t)
{
    return vec3(0.,cos(t*0.25) * 10.0, t*2.);
}

/////////////////////////////////////////////////////////////////////////////////////////////
//////// sphere related functions from iq // https://www.shadertoy.com/view/lsSSWV //////////
/////////////////////////////////////////////////////////////////////////////////////////////

vec3 sphNormal( in vec3 pos, in vec4 sph )
{
    return normalize(pos-sph.xyz);
}

float sphShadow( in vec3 ro, in vec3 rd, in vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    return step( min( -b, min( c, b*b - c ) ), 0.0 );
}
            
vec2 sphDistances( in vec3 ro, in vec3 rd, in vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    float d = sqrt( max(0.0,sph.w*sph.w-h)) - sph.w;
    return vec2( d, -b-sqrt(max(h,0.0)) );
}

float sphSoftShadow( in vec3 ro, in vec3 rd, in vec4 sph )
{
    float s = 1.0;
    vec2 r = sphDistances( ro, rd, sph );
    if( r.y>0.0 )
        s = max(r.x,0.0)/r.y;
    return s;
}    
            
float sphOcclusion( in vec3 pos, in vec3 nor, in vec4 sph )
{
    vec3  r = sph.xyz - pos;
    float l = length(r);
    float d = dot(nor,r);
    float res = d;

    if( d<sph.w ) res = pow(clamp((d+sph.w)/(2.0*sph.w),0.0,1.0),1.5)*sph.w;
    
    return clamp( res*(sph.w*sph.w)/(l*l*l), 0.0, 1.0 );
}

float sphIntersect( in vec3 ro, in vec3 rd, in vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return -1.0;
    return -b -sqrt( h );
}

/////////////////////////////////////////////////////////////////////////////////

// iq shader: https://www.shadertoy.com/view/4sBGDy

// f(x) = (|x|² + R² - r²)² - 4·R²·|xy|² = 0
float iTorus( in vec3 ro, in vec3 rd, in vec2 tor )
{
    float po = 1.0;

    
    float Ra2 = tor.x*tor.x;
    float ra2 = tor.y*tor.y;
    
    float m = dot(ro,ro);
    float n = dot(ro,rd);
    
    float k = (m - ra2 - Ra2)/2.0;
    float k3 = n;
    float k2 = n*n + Ra2*rd.z*rd.z + k;
    float k1 = k*n + Ra2*ro.z*rd.z;
    float k0 = k*k + Ra2*ro.z*ro.z - Ra2*ra2;
    
    #if 1
    // prevent |c1| from being too close to zero
    if( abs(k3*(k3*k3 - k2) + k1) < 0.01 )
    {
        po = -1.0;
        float tmp=k1; k1=k3; k3=tmp;
        k0 = 1.0/k0;
        k1 = k1*k0;
        k2 = k2*k0;
        k3 = k3*k0;

    }
    #endif

    float c2 = 2.0*k2 - 3.0*k3*k3;
    float c1 = k3*(k3*k3 - k2) + k1;
    float c0 = k3*(k3*(-3.0*k3*k3 + 4.0*k2) - 8.0*k1) + 4.0*k0;

    
    c2 /= 3.0;
    c1 *= 2.0;
    c0 /= 3.0;
    
    float Q = c2*c2 + c0;
    float R = 3.0*c0*c2 - c2*c2*c2 - c1*c1;
    
    
    float h = R*R - Q*Q*Q;
    float z = 0.0;
    if( h < 0.0 )
    {
        // 4 intersections
        float sQ = sqrt(Q);
        z = 2.0*sQ*cos( acos(R/(sQ*Q)) / 3.0 );
    }
    else
    {
        // 2 intersections
        float sQ = pow( sqrt(h) + abs(R), 1.0/3.0 );
        z = sign(R)*abs( sQ + Q/sQ );
    }        
    z = c2 - z;
    
    float d1 = z   - 3.0*c2;
    float d2 = z*z - 3.0*c0;
    if( abs(d1) < 1.0e-4 )
    {
        if( d2 < 0.0 ) return -1.0;
        d2 = sqrt(d2);
    }
    else
    {
        if( d1 < 0.0 ) return -1.0;
        d1 = sqrt( d1/2.0 );
        d2 = c1/d1;
    }

    //----------------------------------
    
    float result = 1e20;

    h = d1*d1 - z + d2;
    if( h > 0.0 )
    {
        h = sqrt(h);
        float t1 = -d1 - h - k3; t1 = (po<0.0)?2.0/t1:t1;
        float t2 = -d1 + h - k3; t2 = (po<0.0)?2.0/t2:t2;
        if( t1 > 0.0 ) result=t1; 
        if( t2 > 0.0 ) result=min(result,t2);
    }

    h = d1*d1 - z - d2;
    if( h > 0.0 )
    {
        h = sqrt(h);
        float t1 = d1 - h - k3;  t1 = (po<0.0)?2.0/t1:t1;
        float t2 = d1 + h - k3;  t2 = (po<0.0)?2.0/t2:t2;
        if( t1 > 0.0 ) result=min(result,t1);
        if( t2 > 0.0 ) result=min(result,t2);
    }

    return result;
}

// df(x)/dx
vec3 nTorus( in vec3 pos, vec2 tor )
{
    return normalize( pos*(dot(pos,pos)- tor.y*tor.y - tor.x*tor.x*vec3(1.0,1.0,-1.0)));
}

vec3 eliNormal( vec3 p, vec3 cen, vec3 rad )
{
    return normalize( (p-cen)/rad );
}

float eliIntersect( vec3 ro, vec3 rd, vec3 cen, vec3 rad )
{
    vec3 oc = ro - cen;
    
    vec3 ocn = oc / rad;
    vec3 rdn = rd / rad;
    
    float a = dot( rdn, rdn );
    float b = dot( ocn, rdn );
    float c = dot( ocn, ocn );
    float h = b*b - a*(c-1.0);
    if( h<0.0 ) return -1.0;
    return (-b - sqrt( h ))/a;
}

// (x4 + y4 + z4) - (r2^2)·(x2 + y2 + z2) + r1^4 = 0;
float iGoursat( vec3 ro, vec3 rd, float ka, float kb )
{
    float po = 1.0;

    vec3 rd2 = rd*rd; vec3 rd3 = rd2*rd;
    vec3 ro2 = ro*ro; vec3 ro3 = ro2*ro;

    // raw quartic
    float k4 = dot(rd2,rd2);
    float k3 = dot(ro ,rd3);
    float k2 = dot(ro2,rd2) - kb/6.0;
    float k1 = dot(ro3,rd ) - kb*dot(rd,ro)/2.0;
    float k0 = dot(ro2,ro2) + ka - kb*dot(ro,ro);

    // make leading coefficient 1
    k3 /= k4;
    k2 /= k4;
    k1 /= k4;
    k0 /= k4;
    
    // reduced cubic
    float c2 = k2 - k3*(k3);
    float c1 = k1 + k3*(2.0*k3*k3-3.0*k2);
    float c0 = k0 + k3*(k3*(c2+k2)*3.0-4.0*k1);

#if 1
    // prevent |c1| from being too close to zero
    // reduced cubic
    if( abs(c1) < 0.1*abs(c2) )
    {
        po = -1.0;
        float tmp=k1; k1=k3; k3=tmp;
        k0 = 1.0/k0;
        k1 = k1*k0;
        k2 = k2*k0;
        k3 = k3*k0;

        c2 = k2 - k3*(k3);
        c1 = k1 + k3*(2.0*k3*k3-3.0*k2);
        c0 = k0 + k3*(k3*(c2+k2)*3.0-4.0*k1);
    }
#endif

    c0 /= 3.0;

    float Q = c2*c2 + c0;
    float R = c2*c2*c2 - 3.0*c0*c2 + c1*c1;
    float h = R*R - Q*Q*Q;
    
    // 2 intersections
    if( h>0.0 )
    {
        h = sqrt(h);

        float s = sign(R+h)*pow(abs(R+h),1.0/3.0); // cube root
        float u = sign(R-h)*pow(abs(R-h),1.0/3.0); // cube root
        
        float x = s+u+4.0*c2;
        float y = s-u;
        float ks = x*x + y*y*3.0;
        float k = sqrt(ks);

        float t = -0.5*po*abs(y)*sqrt(6.0/(k+x)) - 2.0*c1*(k+x)/(ks+x*k) - k3;
        return (po<0.0)?1.0/t:t;
    }
    
    // 4 intersections
    float sQ = sqrt(Q);
    float w = sQ*cos(acos(-R/(sQ*Q))/3.0);
  //float w = sQ*cos(atan(sqrt(-h),-R)/3.0);

    float d2 = -w - c2; if( d2<0.0 ) return -1.0;
    float d1 = sqrt(d2);
    float h1 = sqrt(w - 2.0*c2 + c1/d1);
    float h2 = sqrt(w - 2.0*c2 - c1/d1);

    float t1 = -d1 - h1 - k3; t1 = (po<0.0)?1.0/t1:t1;
    float t2 = -d1 + h1 - k3; t2 = (po<0.0)?1.0/t2:t2;
    float t3 =  d1 - h2 - k3; t3 = (po<0.0)?1.0/t3:t3;
    float t4 =  d1 + h2 - k3; t4 = (po<0.0)?1.0/t4:t4;

    float t = 1e20;
    if( t1>0.0 ) t=t1;
    if( t2>0.0 ) t=min(t,t2);
    if( t3>0.0 ) t=min(t,t3);
    if( t4>0.0 ) t=min(t,t4);
    return t;
}

vec3 nGoursat( in vec3 pos, float ka, float kb )
{
    return normalize( 4.0*pos*pos*pos - 2.0*pos*kb*kb );
}

// not very happy with the lighting :)

float getPrimitive(vec3 ro, vec3 rd, vec3 vc)
{
    return sphIntersect(ro, rd, vec4(vc, primitiveRadius));
    //return eliIntersect(ro, rd, vc, eliRadius);
    //return iGoursat(ro-vc, rd, 0.1, 0.5);
    //return iTorus(ro - vc, rd, torRadius);
}

vec3 getNor(vec3 p, vec3 vc)
{
    return sphNormal(p, vec4(vc, primitiveRadius));
    //return eliNormal(p, vc, eliRadius);
    //return nGoursat(p - vc, 0.1, 0.5);
    //return nTorus(p - vc, torRadius);
}

float getDist(vec3 ro, vec3 rd, vec3 vs, out vec3 vc)
{
    float ds = -1.0;
    
    vec3 p = ro;
    for (int i=0;i<layers;i++)
    {
        vc = (floor(p / vs) + 0.5) * vs; // voxel center
        ds = getPrimitive(ro, rd, vc);     // distance to analytic primitve
        if (ds > 0.0) break;         // hit => exit
        p += rd * vs;            // move point to next voxel along ray if no hit
    }
    
    // for render when no hit after all layers
    if (ds < 0.0)
        ds = float(layers);
    
    return ds;
}

vec3 shade(vec3 ro, vec3 rd, vec3 vc)
{
    vec3 p = ro;
    vec3 n = getNor(p, vc);
    
    vec3 ld = vec3(-0.25, -1, 0.25);
    
    float diff = dot(n, ld) * .5 + .5;
    float spe = pow(max(dot(-rd, reflect(-ld, n)), 0.0), 8.0);
    float fre = pow( clamp( 1. + dot(n,rd),0.0,1.0), 4. );
        
    vec3 c = (n * 0.5 + 0.5) * diff; // basic coloring :)
    c += fre * 0.25 + spe * 0.5;

    return c;    
}

vec3 render(vec2 uv)
{
    vec3 color = vec3(0);
    float t = time;
    
    vec3 ro = path(t);
    float a = atan(ro.x, ro.z) + 3.14159 * 0.5 + time * 0.1;
    vec3 tgt = ro + vec3(cos(a), sin(a), sin(a));
    vec3 rd = camera(uv, ro, tgt);

    vec3 vc = vec3(0); // voxel center
    float ds = getDist(ro, rd, voxelSize, vc);
    float fog = 1.0-exp(-0.0002*ds*ds); // fog with first hit

    vec3 p = ro + rd * ds;
    
    // first coloring
    color = shade(p, rd, vc);
    
    // reflections
    float d = ds; 
    for (int i=0;i<countReflections;i++)
    {
        vec3 n = getNor(p, vc);
        rd = reflect(rd, n);
        ds = getDist(p, rd, voxelSize, vc);
        d *= ds;
        p += rd * ds;
        color = mix(color, shade(p, rd, vc), transfer / d);
    }
    
    return clamp(mix(color, vec3(0), fog),0.,1.);
}

void main(void)
{
    vec3 col = vec3(0);
    
    // AA tech from iq shaders
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 px = gl_FragCoord.xy + vec2(float(m),float(n))/float(AA);
        vec2 p = (-resolution.xy+2.0*px)/resolution.y;
        col += render( p );    
    }
    col /= float(AA*AA);
    
    glFragColor = vec4(col,1);
}
