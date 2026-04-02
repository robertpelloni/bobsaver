#version 420

// original https://www.shadertoy.com/view/Ws2yDR

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// The source code for these videos from 2009: 
// https://www.youtube.com/watch?v=eKUh4nkmQbc
// https://www.youtube.com/watch?v=erS6SKqtXLY

// More info here: http://iquilezles.org/www/articles/mandelbulb/mandelbulb.htm

// See https://www.shadertoy.com/view/MdfGRr to see the Julia counterpart

/*
#if HW_PERFORMANCE==0
#define AA 1
#else
#define AA 2  // make AA 1 for slow machines or 3 for fast machines
#endif
*/

vec2 isphere( in vec4 sph, in vec3 ro, in vec3 rd )
{
    vec3 oc = ro - sph.xyz;
    
    float b = dot(oc,rd);
    float c = dot(oc,oc) - sph.w*sph.w;
    float h = b*b - c;
    
    if( h<0.0 ) return vec2(-1.0);

    h = sqrt( h );

    return -b + vec2(-h,h);
}

#define ZERO (min(frames,0))

float map( in vec3 p, out vec4 resColor )
{
    vec3 w = p;
    float m = dot(w,w);

    vec4 trap = vec4(abs(w),m);
    float dz = 1.0;
    
    
    for( int i=0; i<4; i++ )
    {
    
        float potencia=8.0;
        
        dz = potencia*pow(sqrt(m),7.0)*dz + 1.0;
        //dz = 8.0*pow(m,3.5)*dz + 1.0;
        
        float r = length(w);
        float b = potencia*acos( w.y/r);
        float a = potencia*atan( w.x, w.z );
        w = p + pow(r,potencia) * vec3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );

        trap = min( trap, vec4(abs(w),m) );

        m = dot(w,w);
        if( m > 100.0 )
            break;
    }

    resColor = vec4(m,trap.yzw);

    return 0.25*log(m)*sqrt(m)/dz;
}

float intersect( in vec3 ro, in vec3 rd, out vec4 rescol, in float px )
{
    float res = -1.0;

    // bounding sphere
    vec2 dis = isphere( vec4(0.0,0.0,0.0,1.25), ro, rd );
    if( dis.y<0.0 )
        return -1.0;
    dis.x = max( dis.x, 0.0 );
    dis.y = min( dis.y, 10.0 );

    // raymarch fractal distance field
    vec4 trap;

    float t = dis.x;
    
    for( int i=0; i<100; i++  )
    { 
        vec3 pos = ro + rd*t;
        float h = map( pos, trap );
         if(h < 0.0001 || h > 1.){break;}
        t += h;
    }
    
    
    if( t<dis.y )
    {
        rescol = trap;
        res = t;
    }

    return res;
}

float softshadow( in vec3 ro, in vec3 rd, in float k )
{
    float res = 1.0;
    float t = 0.0;
    for( int i=0; i<20; i++ )
    {
        vec4 kk;
        float h = map(ro + rd*t, kk);
        res = min( res, k*h/t );
        if( res<0.001 ) break;
        t += clamp( h, 0.01, 0.2 );
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos, in float t, in float px )
{
    vec4 tmp;
    vec2 e = vec2(1.0,-1.0)*0.1*px;
    
    return normalize( e.xyy*map( pos + e.xyy,tmp ) + 
                      e.yyx*map( pos + e.yyx,tmp ) + 
                      e.yxy*map( pos + e.yxy,tmp ) + 
                      e.xxx*map( pos + e.xxx,tmp ) );
}

const vec3 light1 = vec3(  0.577, 0.577, -0.577 );
const vec3 light2 = vec3( -0.707, 0.010,  0.707 );
//const vec3 light3 = vec3( 0.707, -0.010,  0.707 );
const vec3 light3 = vec3( 0.0, 0.1,  0.0 );

vec3 render( in vec2 p, in mat4 cam )
{
    // ray setup
    const float fle = 3.5;

    vec2  sp = (2.0*p-resolution.xy) / resolution.y;
    float px = 2.0/(resolution.y*fle);

    vec3  ro = vec3( cam[0].w, cam[1].w, cam[2].w );
   
    vec3  rd = normalize( (cam*vec4(sp,fle,0.0)).xyz );
   

    // intersect fractal
    vec4 tra;
    float t = intersect( ro, rd, tra, px );
    
    vec3 col;

    // color sky
    if( t<0.0 )
    {
         col  = vec3(0.8,.9,1.1)*(0.6+0.4*rd.y);
        col += 5.0*vec3(0.8,0.7,0.5)*pow( clamp(dot(rd,light1),0.0,1.0), 32.0 );
    }
    // color fractal
    else
    {
        // color
        col = vec3(0.01);
        col = mix( col, vec3(0.10,0.20,0.30), clamp(tra.y,0.0,1.0) );
         col = mix( col, vec3(0.02,0.10,0.30), clamp(tra.z*tra.z,0.0,1.0) );
        col = mix( col, vec3(0.30,0.10,0.02), clamp(pow(tra.w,6.0),0.0,1.0) );
        
        // lighting terms
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos, t, px );
        vec3 hal = normalize( light1-rd);
        vec3 ref = reflect( rd, nor );
        float occ = clamp(0.05*log(tra.x),0.0,1.0);
        float fac = clamp(1.0+dot(rd,nor),0.0,1.0);

        // sun
        //float sha1 = softshadow( pos+0.001*nor, light1, 32.0 );
        float sha1 =0.55;
        
        float dif1 = clamp( dot( light1, nor ), 0.0, 1.0 )*sha1;
        
        
        float spe1 = pow( clamp(dot(nor,hal),0.0,1.0), 32.0 )*dif1*(0.04+0.96*pow(clamp(1.0-dot(hal,light1),0.0,1.0),5.0));
        // bounce
        float dif2 = clamp( 0.5 + 0.5*dot( light2, nor ), 0.0, 1.0 )*occ;
        
        // sky
        float dif3 = (0.7+0.3*nor.y)*(0.2+0.8*occ);
   
        float dif4 = clamp( dot( light3, nor ), 0.0, 1.0 );
        
        
        vec3 lin = vec3(0.0); 
             lin += 7.0*vec3(1.50,1.10,0.70)*dif1;
             lin += 4.0*vec3(0.25,0.20,0.15)*dif2;
             lin += 1.5*vec3(0.10,0.20,0.30)*dif3;
             lin += 2.5*vec3(0.35,0.30,0.25)*(0.05+0.95*occ); // ambient
   
              lin += 7.0*vec3(1.50,1.10,0.70)*dif4;
        
        col *= lin;
        col = pow( col, vec3(0.7,0.9,1.0) );                  // fake SSS
   
        col += spe1*vec3(1.0)*20.0;
        
    }

    // gamma
    col = sqrt( col );
    
    // vignette
    //col *= 1.0 - 0.05*length(sp);

    return col;
}
    
void main(void)
{
   
    float time = time*0.25;

    
    // camera
    float di = 1.4+0.1*cos(time);
    vec3  ro = di * vec3( cos(.33*time), 0.8*sin(.37*time), sin(.31*time) );
    vec3  ta = vec3(0.0,0.1,0.0);
    float cr = 0.5*cos(0.1*time);

    // camera matrix
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cw = normalize(ta-ro);
    vec3 cu = normalize(cross(cw,cp));
    vec3 cv =          (cross(cu,cw));
    mat4 cam = mat4( cu, ro.x, cv, ro.y, cw, ro.z, 0.0, 0.0, 0.0, 1.0 );
    
   
   vec3 col = render(  gl_FragCoord.xy, cam );
    
   
    glFragColor = vec4( col, 1.0 );
}
