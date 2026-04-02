#version 420

// original https://www.shadertoy.com/view/ftsyDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2013
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org

// Instead of using a pont, circle, line or any mathematical shape for traping the orbit
// of fc(z), one can use any arbitrary shape. For example, a NyanCat :)
//
// I invented this technique more than 10 years ago (can have a look to those experiments 
// here http://www.iquilezles.org/www/articles/ftrapsbitmap/ftrapsbitmap.htm).

#define M_PI 3.1415926
#define RAD90 (M_PI * 0.5)

struct surface {
    float dist;
    vec4 albedo;
    int count;
    bool isHit;
};

// Surface Data Define
#define SURF_NOHIT(d)   (surface(d, vec4(0),              0, false))
#define SURF_BLACK(d)     (surface(d, vec4(0,0,0,1),       0, true))
#define SURF_FACE(d)     (surface(d, vec4(1,0.7,0.6,1),     0, true))
#define SURF_MOUSE(d)     (surface(d, vec4(1,0,0.1,1),       0, true))
#define SURF_CHEEP(d)     (surface(d, vec4(1,0.3,0.4,1),     0, true))

mat2 rot( float th ){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

surface opU(surface d1, surface d2)
{
    if(d1.dist < d2.dist){
        return d1;
    } else {
        return d2;
    }
}

float opU( float d1, float d2 ) {  return min(d1,d2); }

float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

// Distance Function 2D
float sdRoundBox(vec2 p, vec2 size, float r)
{
    return length(max(abs(p) - size * 0.5, 0.0)) - r;
}

float sdArc( in vec2 p, in vec2 sc, in float ra, float rb )
{
    // sc is the sin/cos of the arc's aperture
    p.x = abs(p.x);
    return ((sc.y*p.x>sc.x*p.y) ? length(p-sc*ra) : 
                                  abs(length(p)-ra)) - rb;
}

float sdCapsule(vec2 p, vec2 a, vec2 b, float r)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

float sdEllipsoid( vec2 p, vec2 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

surface opColorOvreWrite(surface a, surface b)
{
    if(b.dist > 0.0){
        return a;
    }else{
        a.albedo = b.albedo;
        return a;
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Mikka Boze Distance Function 2D
/////////////////////////////////////////////////////////////////////////////////////////////////
float sdEar(vec2 p)
{
    p = rot(RAD90+0.25) * p;
    return sdArc(p + vec2(0.05, 0.175), vec2(sin(0.7),cos(0.7)), 0.03, 0.01);
    //return sdCappedTorus(p + vec3(0.05, 0.175, 0), vec2(sin(0.7),cos(0.7)), 0.03, 0.01);
}

#define EYE_SPACE_2D 0.045

vec2 opBendXY(vec2 p, float k)
{
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    return vec2(m*p.xy);
}

float sdMouse(vec2 p, float ms)
{
    vec2 q = opBendXY(p, 2.0);
    ms += 0.00001;
    return sdEllipsoid(q, vec2(0.035, 0.01 * ms));
}

float sdCheep(vec2 p)
{    
    const float x = 0.085;
    const float r = 0.0045;
    const float rb1 = 100.;
    
    //p = rotate(p, M_PI * -0.6 * (p.x - x), vec3(-0.2,0.8,0));
    //p = rotate(p, M_PI * -0.6 * (p.x - x), vec3(-0.2,0.8,0));
    
    float d = sdCapsule(opBendXY(p + vec2(x, -0.02), rb1), vec2(-0.005,0.0), vec2(0.005, 0.), r);
    float d1 = sdCapsule(opBendXY(p + vec2(x+0.01, -0.02), 200.0), vec2(-0.0026,0.0), vec2(0.0026, 0.), r);
    float d2 = sdCapsule(opBendXY(p + vec2(x+0.019, -0.025), -rb1), vec2(-0.01,0.0), vec2(0.0045, 0.), r);
    
    return opU(opU(d, d1), d2);
}

float sdEyeBrow(vec2 p)
{
    const float x = 0.05;
    //p = opBendXZ(p + vec3(0.02,0,-0.02), -6.5);
    return sdRoundBox(p + vec2(EYE_SPACE_2D, -0.14), vec2(0.015,0.004), 0.0);
}

surface sdBoze(vec2 p, vec2 sc, float ms)
{    
    surface result = SURF_NOHIT(1e5);
    
    float minsc = min(sc.x, sc.y);
    p /= sc;
    
    // head
    float d = sdCapsule(p, vec2(0,0.08), vec2(0, 0.11), 0.125);
    
    //float d1 = sdRoundedCylinder(p + vec3(0,0.025,0), 0.095, 0.05, 0.0);
    //float d1 = sdRoundBox(p + vec2(0, 0.025), vec2(0.25,0.03), 0.03);
    float d1 = sdCapsule(p, vec2(-0.1, 0.0075), vec2(0.1, 0.0075), 0.06); 
    
    d = smin(d, d1, 0.025);
    //d = d1;
    
    vec2 mxp = vec2(-abs(p.x), p.y);
    
    // ear
    float d2 = sdEar(mxp);
    d = opU(d, d2);

    surface head = SURF_FACE(d);
    
    // eye
    float d4 = sdCapsule(mxp, vec2(-EYE_SPACE_2D, 0.07), vec2(-EYE_SPACE_2D, 0.09), 0.0175);
    surface eye = SURF_BLACK(d4);
    
    // mouse
    float d6 = sdMouse(p, ms);
    surface mouse = SURF_MOUSE(d6);
    
    result = opColorOvreWrite(head, mouse);
    
    
    // cheep
    float d7 = sdCheep(mxp);
    surface cheep = SURF_CHEEP(d7);
    
    result = opColorOvreWrite(result, cheep);
    
    
    // eyebrows
    float d9 = sdEyeBrow(mxp);
    eye.dist = opU(eye.dist, d9);
    
    result = opColorOvreWrite(result, eye);
    
    result.dist *= minsc;
    
    return result;
}
/////////////////////////////////////////////////////////////////////////////////////////////////
// End of Mikka Boze 2D
/////////////////////////////////////////////////////////////////////////////////////////////////

vec4 getSDBoze2D(vec2 p)
{
    float ms = sin(time*5.) * 0.5 + 0.5;
    surface mat = sdBoze(p+vec2(0.2+sin(time*0.7)*0.2,0.1+cos(time)*0.3), vec2(1), ms);
    
    // outline
    mat.albedo.xyz *= abs(mat.dist) <= 0.002 ? 0. : 1.;
    
    return (mat.dist <= 0.0) ? mat.albedo : vec4(0);
}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    float time = max( time, 0.0 );
    
    // zoom    
    p = vec2(0.5,-0.05)  + p*0.75 * pow( 0.9, 20.0*(0.5+0.5*cos(0.25*time)) );
    
    vec4 col = vec4(0.0);
    vec3 s = mix( vec3( 0.2,0.2, 1.0 ), vec3( 0.5,-0.2,0.5), 0.5+0.5*sin(0.5*time) );

    // iterate Jc    
    vec2 c = vec2(-0.76, 0.15);
    float f = 0.0;
    vec2 z = p;
    for( int i=0; i<100; i++ )
    {
        if( (dot(z,z)>4.0) || (col.w>0.1) ) break;

        // fc(z) = z² + c        
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        
        //col = getNyanCatColor( s.xy + s.z*z, time );
        col = getSDBoze2D(s.xy + s.z*z);
        f += 1.0;
    }
    
    vec3 bg = 0.5*vec3(1.0,0.5,0.5) * sqrt(f/100.0);
    
    col.xyz = mix( bg, col.xyz, col.w );
    
    
    glFragColor = vec4( col.xyz,1.0);
}
