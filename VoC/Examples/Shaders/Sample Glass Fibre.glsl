#version 420

// original https://www.shadertoy.com/view/tljczV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
//
// Glass Fibre
// -> my attempt of an abstract, glass-looking field 
//
//
// references
// "Glass Field" by Kali
// from https://www.shadertoy.com/view/4ssGWr
// https://www.shadertoy.com/view/XlsGWl
//
// Sound via soundcloud - Holon: As far as possible
//
// Shane´s sky
// https://www.shadertoy.com/view/MscXRH        
//
// Shane´s mist/dust
// https://www.shadertoy.com/view/4ddcWl 
//
// Shane´s electric charge
// https://www.shadertoy.com/view/4ttGDH    
//
//

#define lightcol1 vec3(2.,.95,.85)
#define lightcol2 vec3(1.,1.,1.)
#define offset1 -1.85
#define offset2 -1.75
#define att 12.

float time2;
float id;
vec3 glow;
vec3 sync;

vec3 rotate_x(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +1.0, +.0, +.0,
        +.0, +ca, -sa,
        +.0, +sa, +ca);
}

vec3 rotate_y(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +ca, +.0, -sa,
        +.0,+1.0, +.0,
        +sa, +.0, +ca);
}

float n3D(vec3 p){
    
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); 
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

float getMist(in vec3 ro, in vec3 rd, in vec3 lp, in float t){

    float mist = 0.;

    float t0 = 0.;
    
    for (int i = 0; i<24; i++){
        
        if (t0>t) break; 
        
        float sDi = length(lp-ro)/120.; 
        float sAtt = 1./(1. + sDi*.25);
        
        vec3 ro2 = (ro + rd*t0)*2.5;
        float c = n3D(ro2)*.65 + n3D(ro2*3.)*.25 + n3D(ro2*9.)*.1;

        float n = c;
        mist += n*sAtt;
        
        t0 += clamp(c*.25, .1, 1.);
        
    }
    
    return max(mist/48., 0.);

}

//Smooth min by IQ
float smin( float a, float b )
{
    float k = 0.5;
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);

    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
       length(p.xy - vec2(clamp(p.x, -k.z*h.x, k.z*h.x), h.x))*sign(p.y - h.x),
       p.z-h.y );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 rotZ(float a, vec3 v)
{
   return vec3(cos(a) * v.x + sin(a) * v.y, cos(a) * v.y - sin(a) * v.x, v.z);
}

//////////////////////////////////////////////////////////////////////////////////////
// distance field
//////////////////////////////////////////////////////////////////////////////////////

float map(vec3 pos) {    

    float t = -time;
   
    vec3 sp = pos;
    vec3 np  = pos + vec3( 0.0, 0.0, 5.5);
 
    t = -time;
    np.z += sin(t) * 3.6;

    
    vec3 A=vec3(6.);
    vec3 B=vec3(6.);
    vec3 p = abs(A-mod(sp,2.0*A));  //tiling fold by Syntopia
    vec3 p1 = abs(B-mod(np,2.0*B)); //tiling fold by Syntopia

    float cyl   = length(p.xy)-.24;
    float cyl1  = length(p.zy)-.24;
    float cyl2  = length(p.xz)-.24;
    
    float prism = sdHexPrism( p1, vec2(0.75,2.05) );

    for (int i=0; i<21; i++)
    {

        float intensity = 1. / ( 1. + pow(abs(prism*att),2.3));
        if(i == 2 && id == 0.) {
            glow += vec3(1.,1.,0.) * intensity;
        }
        
    }    
  
    return min( prism, smin( smin( cyl, cyl1 ), cyl2 ) );

}

//////////////////////////////////////////////////////////////////////////////////////
// normals
//////////////////////////////////////////////////////////////////////////////////////

vec3 normal(vec3 pos) {
    vec3 e = vec3(0.0,0.001,0.0);
    
    return normalize(vec3(
            map(pos+e.yxx)-map(pos-e.yxx),
            map(pos+e.xyx)-map(pos-e.xyx),
            map(pos+e.xxy)-map(pos-e.xxy)
            )
    );    
}

void main(void)
{
    time2 = time*.285; 

    
    //////////////////////////////////////////////////////////////////////////////////////
    // setup: uv, ray
    //////////////////////////////////////////////////////////////////////////////////////

    float fft = 0.0;//texture(iChannel0, vec2(.4, .25)).r * 2.; 
    sync = vec3( fft, 4.0*fft*(1.0-fft), 1.0-fft ) * fft;
    
    vec2 uv      = gl_FragCoord.xy / resolution.xy *2. - vec2(1.);
    uv.y        *= resolution.y / resolution.x;
    float fov    = min(( time*.2+.05),0.6 ); //animate fov at start
    vec3 ro      = vec3(cos(time2)*12.0,sin(time2*.5)*10., time2 * 18.0);
    vec3 rd      = normalize(vec3(uv.xy*fov,1.)); 
    rd.z -= length(rd) * 0.86; //lens distort
    rd = normalize(rd);
    
    
    /*
    rd.z -= length(rd) * 0.18; //lens distort
    rd = normalize(vec3(rd.xy, sqrt(max(rd.z*rd.z - dot(rd.xy, rd.xy)*.000001, 0.))));
    
    vec2 m = sin(vec2(1.57079632, 0) + time/4.);
    rd.xy = rd.xy*mat2(m.xy, -m.y, m.x);
    rd.xz = rd.xz*mat2(m.xy, -m.y, m.x);    
    */

    //////////////////////////////////////////////////////////////////////////////////////
    // setup: raymarching params
    //////////////////////////////////////////////////////////////////////////////////////
    
    float total     = 0.5;
    float distfade  = 1.0;
    float glassfade = 1.0;
    float intens    = 1.0;
    float maxdist   = 120.0;
    float vol       = 0.0;
    vec3 spec       = vec3( 0.0 );
    

    

    //////////////////////////////////////////////////////////////////////////////////////        
    // setup
    // mouse interaction(s)   
    ////////////////////////////////////////////////////////////////////////////////////// 
    
    vec3 mouse = vec3(0.0); //vec3(mouse*resolution.xy.xy/resolution.xy - 0.5,mouse*resolution.xy.z-.5);
    
    rd = rotate_y(rd,mouse.x * 9.0 + offset2);
    if( mouse.y != 0. )  rd = rotate_x(rd,mouse.y*9.0+offset1); 

    
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////        
    // sky based on
    // Shane´s
    // https://www.shadertoy.com/view/MscXRH        
    //////////////////////////////////////////////////////////////////////////////////////  
    
    vec3 sky = mix(vec3(0., 0., .5), vec3(0., 0., .7), rd.x*0.5 + 0.5);
    sky *= sqrt(sky); 
    vec3 cloudCol = mix(sky, vec3(1, .9, .8), 0.26);

    
    float ref    = 0.;
    vec3 light1  = normalize(vec3( -0.25,  0.25, 0.20 ) );
    vec3 light2  = normalize(vec3( -0.25,  -0.15, 0.10 ) );

    vec3 p;
     float d;
    vec3 preCol = vec3(0.);
    glow = vec3(.0);

    for ( int r=0; r<64; r++ ) {
          
          p = ro + total * rd;
          d = map(p);

          float distfade = exp(-1.5*pow(total/maxdist,1.5));
          
          intens=min(distfade,glassfade);

        // refraction
        if (d>0.0 && ref>.5) {
            ref=0.;
            vec3 n=normal(p);
            if (dot(rd,n)<-.5) rd=normalize(refract(rd,n,1./.87));
            vec3 refl=reflect(rd,n);
            spec+=lightcol1*pow(max(dot(refl,light1),0.0),40.)*intens*.3;
            spec+=lightcol2*pow(max(dot(refl,light2),0.0),40.)*intens*.3;

        }
        if (d<0.0 && ref<.05) {
            ref=1.;
            vec3 n=normal(p);
            if (dot(rd,n)<-.05) rd=normalize(refract(rd,n,.87));
            vec3 refl=reflect(rd,n);
            glassfade*=.45;
            spec+=lightcol1*pow(max(dot(refl,light1),0.0),40.)*intens*0.3;
            spec+=lightcol2*pow(max(dot(refl,light2),0.0),40.)*intens*0.3;
        }
        
        total+=max(0.001,abs(d)); //advance ray 
        if (total > maxdist) break; 

        //vol+=intens; //accumulate current intensity
        vol+=max(0.,0.5-d)*intens; //glow
        
        
        //////////////////////////////////////////////////////////////////////////////////////        
        // based on
        // Shane´s
        // https://www.shadertoy.com/view/4ttGDH          
        //////////////////////////////////////////////////////////////////////////////////////          
        
        float hi = abs(mod(total/1. + time/3., 8.) - 8./2.)*2.;
        vec3 cCol = vec3(.01, .05, 1)*vol*1./(.0006 + hi*hi*.2);
        preCol += mix(cCol.yxz, cCol, n3D(p*3.));
        
       
        rd.xy = cos(0.009  *d)*rd.xy + sin(0.009 * d)*vec2(-rd.y, rd.x);

        
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////        
    // mist/dust based on
    // Shane´s
    // https://www.shadertoy.com/view/4ddcWl          
    //////////////////////////////////////////////////////////////////////////////////////  
 
    float dust = getMist(ro, rd, vec3(-0.5,  1.5, -0.5), total)*(1. - smoothstep(0., 1., -rd.x - 0.35));//(-rd.y + 1.);
    

    

    vol=pow(vol,0.4)*0.12;

    vec3 col=vec3(vol)+vec3(spec)*1.4+vec3(.05);
    col += glow*0.0065 *sync.r * 0.55;

    col *= min( 1.0, time ); //fade in
    col *= mix( col, sky, glassfade );
    col  = mix( col, preCol, 0.000006 );

    col += mix( col, sky, 0.1);
    //col = mix(col, sky, smoothstep(0., 6.85, total/maxdist));
    col = mix(col, sky*sky*2., 1. - 1./(1.+ total*total*.00001));//
 
    
    // More postprocessing. Adding some very subtle fake warm highlights.
    vec3 fCol = mix(pow(vec3(1.3, 1, 1)*col, vec3(1, 2, 10)), sky, .5);
    col = mix(fCol, col, dot(cos(rd*6. +sin(rd.yzx*6.)), vec3(.333))*.1 + .9);
    
        
    vec3 mistCol = vec3(0, 1.1, 1.9); // Probably, more realistic, but less interesting.
    col += (mix(col, mistCol, 0.66)*0.46 + col*mistCol*5.)*dust;

    
    // Vignette
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 0.11);

         
    glFragColor = vec4(col,1.0);

}
