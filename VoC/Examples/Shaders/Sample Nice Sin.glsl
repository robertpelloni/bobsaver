#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WlsBWr

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Raymarching part from "Sphere Gears - Step 1" by iq. https://shadertoy.com/view/ws3GD2
// 2020-08-03 19:04:37

// Created by curiousper 04/08/2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// set AA 2 if you have beafy pc
#define AA 0

float hash( in float n )
{
    return fract(sin(n)*43758.5453);
}

float sdSphere( in vec3 p, in float r )
{
    return length(p)-r;
}
float sdBox( in vec3 p, in vec3 r )
{
    vec3 d = abs(p)-r;
    return length(max(d,0.));
}
float displacement(in vec3 p, in float force){
    return (sin(force*p.z*1.0)/2.) / force;
}

vec4 map( in vec3 p, float time )
{
    vec3 boxSize = vec3(0.03, 0.2, 0.4);
    vec3 start = vec3(0.32,-0.1,0.0);
    vec3 dif = vec3(0.08,0.0,-0.015);
    
    //float t = mod(time, 60.)*1.75;
    float t = time*1.75;
    float an1 = smoothstep(0.0,1.0,(sin(t+10.26)*.5+.6));
    an1 *= an1;
    float an2 = smoothstep(0.0,1.0,(sin(t+0.6)*.5+.6));
    an2 *= an2;
    float an3 = smoothstep(0.0,1.0,(sin(t+42.745)*0.5+0.6));
    an3 *= an3;
    float an4 = smoothstep(0.0,1.0,(sin(t+0.345)*0.5+0.6));
    an4 *= an4;
    float an5 = smoothstep(0.0,1.0,(sin(t+142.745)*0.6+0.6));
    an5 *= an5;
    float an6 = smoothstep(0.0,1.0,(sin(t+2.135)*0.6+0.6));
    an6 *= an6;
    float an7 = smoothstep(0.0,1.0,(sin(t+3.956)*0.7+0.6));
    an7 *= an7;
    float an8 = smoothstep(0.0,1.0,(sin(t+1.3)*0.7+0.6));
    an8 *= an8;
    
    p -= start;
    p.z = p.z*0.8;
    vec3 q = p;
    
    
    vec3 qd = q+vec3(0.,0.,4.2);
    q.y += displacement(q, 40.)*0.8;
    float dis = displacement(qd+vec3(0.,0.,1.), 30.)*1.0;
    q.y += dis+dis*an1;
    q.y += displacement(qd+vec3(0.,0.,0.2), 60.)*1.0 * an3;
    float v = smoothstep(0.8,1.2,abs(q.z+dif.z)/boxSize.z)/10.; // edges
    q.y += v/1.0;
    float d = sdBox( q, boxSize);
    

    for(float i=1.01; i<13.; i+=1.){
        q=p+dif*i;
        float h = hash(i*i/3.);
        float h2 = hash(h*i/3.);
        qd = q+vec3(0.,0.,0.1)*h;
        float c2 = mod(i-0.01, 2.);
        float c3 = mod(i-0.01, 3.);
        float c4 = mod(i-0.01, 4.);
        float c5 = mod(i-0.01, 5.);
        float c6 = mod(i-0.01, 6.);
        q.y += (displacement(qd+vec3(0.,0.,1.2*h2), 20.)*0.9) ;
        q.y += (displacement(qd+vec3(0.,0.,1.1*h), 20.)*an4*1.8) * c2 ;
        q.y += (displacement(qd+vec3(0.,0.,1.9*h2), 20.)*an5*0.5) * c3;
        q.y += (displacement(qd+vec3(0.,0.,1.5*h), 30.)*an6*0.93) * c4;
        q.y += (displacement(qd+vec3(0.,0.,6.2*h), 30.)*an7*0.4) * c5;
        q.y += (displacement(qd+vec3(0.,0.,2.2*h), 40.)*an8*0.3) * c6;
        
        float v = smoothstep(0.9,1.1,abs(q.z+dif.z)/boxSize.z)/10.; // edges
        q.y += v/1.;
        float d2 = sdBox( q, boxSize);
        d = min(d, d2);
    }

    //d = sdSphere(p, 0.2);
    return vec4( d, p );
}

#define ZERO min(frames,0)

vec3 calcNormal( in vec3 pos, in float time )
{
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e,time).x;
    }
    return normalize(n);
}

float calcAO( in vec3 pos, in vec3 nor, in float time )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map( pos+h*nor, time ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float k, in float time )
{
    float res = 1.0;
    
    float tmax = 2.0;
    float t    = 0.001;
    for( int i=0; i<64; i++ )
    {
        float h = map( ro + rd*t, time ).x;
        res = min( res, k*h/t );
        t += clamp( h, 0.012, 0.2 );
        if( res<0.001 || t>tmax ) break;
    }
    
    return clamp( res, 0.0, 1.0 );
}

vec4 intersect( in vec3 ro, in vec3 rd, in float time )
{
    vec4 res = vec4(-1.0);
    
    float t = 0.001;
    float tmax = 5.0;
    for( int i=0; i<128 && t<tmax; i++ )
    {
        vec4 h = map(ro+t*rd,time)/2.0;            //hack
        if( h.x<0.001 ) { res=vec4(t,h.yzw); break; }
        t += h.x;
    }
    
    return res;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(gl_FragCoord.xy+o)-resolution.xy)/resolution.y;
        float d = 0.5*sin(gl_FragCoord.xy.x*147.0)*sin(gl_FragCoord.xy.y*131.0);
        float time = time;
        #else    
        vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
        float time = time;
        #endif

        // camera    
        float an = 1.0;// 6.2831*time/40.0;
        vec3 ta = vec3( 0.0, 0.1, 0.0 )*1.9;
        vec3 ro = vec3(1., 1.2, 2.);// ray origin (camera pos)
        //vec3 ro = ta + vec3( 0.5*cos(an), 0.2, 0.5*sin(an) );
        
        // camera-to-world transformation
        mat3 ca = setCamera( ro, ta, 0. );
        
        // ray direction
        float fl = 4.0;
        vec3 rd = ca * normalize( vec3(p,fl) );
        
    #if 1
    float f = 0.56;
    #else
    float f = mouse*resolution.xy.x/resolution.x;
    #endif
        
    vec3 rd_orth = setCamera(ro, ta, 0.)*normalize(vec3(0., 0., 1.0));// ray direction via orthographic projection
    rd = mix(rd, rd_orth, f);

    #if 0
    float orthRectSize = .0 + 3.0*mouse*resolution.xy.y/resolution.y;
    vec3 ro_orth = ro + vec3(p * orthRectSize, 0.);// ray origin 
    ro = mix(ro, ro_orth, f);
    #endif
        

        // background
        vec3 bcol = vec3(0.01, 0.7, 1.0);
        vec3 tcol = vec3(0.71, 0.35, 0.87)-0.25;
        vec3 col = mix(bcol, tcol, p.y*.5+0.5 /*1.0+rd.y*/);//vec3(1.0+rd.y)*0.03;
        
        // raymarch geometry
        vec4 tuvw = intersect( ro, rd, time );
        
        if( tuvw.x>0.0 )
        {
            // shading/lighting    
            vec3 pos = ro + tuvw.x*rd;
            vec3 nor = calcNormal(pos, time);
            vec3 l = vec3(2.0,1.0,-1.);
            float ndl = dot(nor,l)*.4+.6;
            vec3 amb = col*.5;
            float rim = (dot(rd,nor)*.5+.5);
            rim = clamp(0.0,1.0,(pow(rim,1.)));
            float invRim = 1.0-rim;
            invRim*=invRim*invRim*invRim;
            
            float ao = calcAO( tuvw.yzw, nor, time )*1.2;
            ao += 2.0*ao*(1.-nor.y); // top
            ao += nor.x*(1.-ao)*.2;  // side
                        
            float y = tuvw.y;
            y = y*y*8.5;
            y += 2.0;
            y /= 3.0;
            tcol = vec3(0.823, 0.686, 0.992)*0.8;
            col = mix(bcol, tcol, y);
            
            col = col*ndl+amb;
            col *= col + sin(tuvw.yyy*3000.)*col*0.9*invRim * nor.y + rim;
            
            col = mix(col,col*ao/.9,0.6);
            
            // color correction
            col *= 0.5;
            col *= col + nor.y*0.4;
        }
        
        
        // gamma        
        tot += pow(col,vec3(0.45) );
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    // cheap dithering
    tot += sin(gl_FragCoord.xy.x*114.0)*sin(gl_FragCoord.xy.y*211.1)/512.0;

    glFragColor = vec4( tot, 1.0 );
}
