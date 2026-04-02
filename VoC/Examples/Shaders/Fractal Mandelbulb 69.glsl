#version 420

// original https://www.shadertoy.com/view/sssyDn

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work in any form,
// including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it.
// I share this Work for educational purposes, and you can link to it,
// through an URL, proper attribution and unmodified screenshot, as part
// of your educational material. If these conditions are too restrictive
// please contact me and we'll definitely work it out.

// The source code for these videos from 2009: 
// https://www.youtube.com/watch?v=eKUh4nkmQbc
// https://www.youtube.com/watch?v=erS6SKqtXLY
//
// More info here: http://iquilezles.org/www/articles/mandelbulb/mandelbulb.htm
//
// See https://www.shadertoy.com/view/MdfGRr to see the Julia counterpart

#if HW_PERFORMANCE==0
#define AA 1
#else
#define AA 2  // make AA 1 for slow machines or 3 for fast machines
#endif

// https://iquilezles.org/www/articles/intersectors/intersectors.htm
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

// http://iquilezles.org/www/articles/mandelbulb/mandelbulb.htm
float map( in vec3 p, out vec4 resColor )
{
    vec3 z = p;
     
  //  vec3 c = p;
    float m = dot(z,z);

    vec4 trap = vec4(abs(z),m);
    float dz = 1.0;
    
    for( int i=0; i<4; i++ )
    {
//#if 0
    float tp = dot(z, z);
    
    float r = sqrt(tp);
    tp = tp * tp * tp * r;
    dz = tp * dz * 8.0 + 1.0;
    
    vec3 z2 = z * z;
    vec3 z4 = z2 * z2;
    
    float k3 = z2.x + z2.y;
    tp = k3 * k3;
    tp = tp * tp * tp * k3;
    //float k2 = 1.0f / sqrt(tp);
    float k = 3.0 - (sin(time*.8) + 1.0);
    float k2 = k / sqrt(tp);
    dz *= k;
    tp = z2.x * z2.y;
    float k1 = z4.x + z4.y + z4.z - 6.0f * z2.z * k3 + 2.0 * tp;
    float k4 = k3 - z2.z;
    float k12 = k1 * k2;
    //z.x = 64.0f * z.x * z.y * z.z * k4 * (z2.x - z2.y) * (z4.x - 6.0f * tp + z4.y) * k12;
    
    z.x = 64.0 * z.x * z.y * z.z * k4 * (z2.x - z2.y) * (z4.x - 6.0 * tp + z4.y) * k12;
    z.y = -8.0 * z.z * k4 * (z4.x * z4.x - 28.0 * tp * (z4.x + z4.y) + 70.0 * z4.x * z4.y + z4.y * z4.y) * k12;

    z.z = -16.0 * z2.z * k3 * k4 * k4 + k1 * k1;
     z += p;   
    
/*#else

        // trigonometric version (MUCH faster than polynomial)
        
        // dz = 8*z^7*dz
        dz = 9.0*pow(m,4.0)*dz + 1.0;
      
        // z = z^8+z
        float r = length(w);
                float b = ( w.y/r);
       b = 9.0*mix(acos(b), asin(b),.5*(cos(time*.1) + 1.0));
        float a = 9.0*atan( w.x, w.z );
        float sb = sin(b);
        w = p + pow(r,9.0) * vec3(sb*sin(a), cos(b), sb*cos(a) );
             

    
//#endif  */      
        
        trap = min( trap, vec4(abs(z),m) );

        m = dot(z,z);
        if( m > 256.0 )
            break;
    }

    resColor = vec4(m,trap.yzw);

    // distance estimation (through the Hubbard-Douady potential)
    return 0.25*log(m)*sqrt(m)/dz;
}

// https://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos, in float t, in float px )
{
    vec4 tmp;
    vec2 e = vec2(1.0,-1.0)*0.5773*0.25*px;
    return normalize( e.xyy*map( pos + e.xyy,tmp ) + 
                      e.yyx*map( pos + e.yyx,tmp ) + 
                      e.yxy*map( pos + e.yxy,tmp ) + 
                      e.xxx*map( pos + e.xxx,tmp ) );
}

// https://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float softshadow( in vec3 ro, in vec3 rd, in float k )
{
    float res = 1.0;
    float t = 0.0;
    for( int i=0; i<64; i++ )
    {
        vec4 kk;
        float h = map(ro + rd*t, kk);
        res = min( res, k*h/t );
        if( res<0.001 ) break;
        t += clamp( h, 0.01, 0.2 );
    }
    return clamp( res, 0.0, 1.0 );
}

float raycast( in vec3 ro, in vec3 rd, out vec4 rescol, in float px )
{
    float res = -1.0;

    // bounding sphere
    vec2 dis = isphere( vec4(0.0,0.0,0.0,1.25), ro, rd );
    if( dis.y<0.0 ) return -1.0;
    dis.x = max( dis.x, 0.0 );
    dis.y = min( dis.y, 10.0 );

    // raymarch fractal distance field
    vec4 trap;

    float t = dis.x;
    for( int i=0; i<128; i++  )
    { 
        vec3 pos = ro + rd*t;
        float th = 0.25*px*t;
        float h = map( pos, trap );
        if( t>dis.y || h<th ) break;
        t += h;
    }
    
    if( t<dis.y )
    {
        rescol = trap;
        res = t;
    }

    return res;
}

const vec3 light1 = vec3(  0.577, 0.577, -0.577 );
const vec3 light2 = vec3( -0.707, 0.000,  0.707 );

vec3 refVector( in vec3 v, in vec3 n )
{
    return v;
    float k = dot(v,n);
    //return (k>0.0) ? v : -v;
    return (k>0.0) ? v : v-2.0*n*k;
}

vec3 render( in vec2 p, in mat4 cam )
{
    // ray setup
    const float fle = 1.5;

    vec2  sp = (2.0*p-resolution.xy) / resolution.y;
    float px = 2.0/(resolution.y*fle);

    vec3  ro = vec3( cam[0].w, cam[1].w, cam[2].w );
    vec3  rd = normalize( (cam*vec4(sp,fle,0.0)).xyz );

    // intersect fractal
    vec4 tra;
    float t = raycast( ro, rd, tra, px );
    
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
        col *= 0.5;
        
        // lighting terms
        vec3  pos = ro + t*rd;
        vec3  nor = calcNormal( pos, t, px );
        
        nor = refVector(nor,-rd);
        
        vec3  hal = normalize( light1-rd);
        vec3  ref = reflect( rd, nor );
        float occ = clamp(0.05*log(tra.x),0.0,1.0);
        float fac = clamp(1.0+dot(rd,nor),0.0,1.0);

        // sun
        float sha1 = softshadow( pos+0.001*nor, light1, 32.0 );
        float dif1 = clamp( dot( light1, nor ), 0.0, 1.0 )*sha1;
        float spe1 = pow( clamp(dot(nor,hal),0.0,1.0), 32.0 )*dif1*(0.04+0.96*pow(clamp(1.0-dot(hal,light1),0.0,1.0),5.0));
        // bounce
        float dif2 = clamp( 0.5 + 0.5*dot( light2, nor ), 0.0, 1.0 )*occ;
        // sky
        float dif3 = (0.7+0.3*nor.y)*(0.2+0.8*occ);
        
        vec3 lin = vec3(0.0); 
             lin += 12.0*vec3(1.50,1.10,0.70)*dif1;
             lin +=  4.0*vec3(0.25,0.20,0.15)*dif2;
             lin +=  1.5*vec3(0.10,0.20,0.30)*dif3;
             lin +=  2.5*vec3(0.35,0.30,0.25)*(0.05+0.95*occ);
             lin +=  4.0*fac*occ;
        col *= lin;
        col = pow( col, vec3(0.7,0.9,1.0) );
        col += spe1*15.0;
    }

    // gamma
    col = pow( col, vec3(0.4545) );
    
    // vignette
    col *= 1.0 - 0.05*length(sp);

    return col;
}
    
void main(void)
{
    float time = time*.1;

    // camera
    //float di = 1.4+0.1*cos(.29*time);
    float di = 2.;
    //vec3  ro = di*vec3( cos(.33*time), 0.8*sin(.37*time), sin(.31*time) );
   vec3  ro = di*vec3(0.,1., 0.001 );
    vec3  ta = vec3(0.0,0.1,0.0);
  //float cr = 0.5*cos(0.1*time);
  float cr = 0.0;

    // camera matrix
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cw = normalize(ta-ro);
    vec3 cu = normalize(cross(cw,cp));
    vec3 cv =          (cross(cu,cw));
    mat4 cam = mat4( cu, ro.x, cv, ro.y, cw, ro.z, 0.0, 0.0, 0.0, 1.0 );

    // render
    #if AA<2
    vec3 col = render(  gl_FragCoord.xy, cam );
    #else
    #define ZERO (min(frames,0))
    vec3 col = vec3(0.0);
    for( int j=ZERO; j<AA; j++ )
    for( int i=ZERO; i<AA; i++ )
    {
        col += render( gl_FragCoord.xy + (vec2(i,j)/float(AA)), cam );
    }
    col /= float(AA*AA);
    #endif

    glFragColor = vec4( col, 1.0 );
}
