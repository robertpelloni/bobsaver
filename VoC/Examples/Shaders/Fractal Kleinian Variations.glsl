#version 420
#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ldSyRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by sebastien durand - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------
// Text - Thanks to Andre [Shadertext]
// Andre - https://www.shadertoy.com/view/lddXzM 
//-----------------------------------------------------
// Music - Yann Tiersen - Summer 78 (10dens remix) (2010)
//-----------------------------------------------------

#define DE_RAY pseudoKleinianSlider
#define DE_COLOR pseudoKleinianSliderColor

#define WITH_SHADOWS

#define WITH_AO
#define M_PI_F 3.141592
#define WITH_VIGNETING

#define BACK_COLOR vec3(.08, .16, .34) 

#define PRECISION_FACTOR 4.5e-4
#define MIN_DIST_RAYMARCHING .01
#define MAX_DIST_RAYMARCHING 5.
#define MAX_RAYMACING_ITERATION 164 

#define MIN_DIST_SHADOW 10.*PRECISION_FACTOR
#define MAX_DIST_SHADOW .5
#define PRECISION_FACTOR_SHADOW 3.*PRECISION_FACTOR

#define MIN_DIST_AO 3.*PRECISION_FACTOR
#define MAX_DIST_AO .05
#define PRECISION_FACTOR_AO PRECISION_FACTOR

#define LIGHT_VEC normalize(vec3(.2,.7, 1.6) )

#define NB_ITERATION 8

//-----------------------------------------------
//                 TEXT by Andre
//-----------------------------------------------
// Andre - https://www.shadertoy.com/view/lddXzM 
//-----------------------------------------------

#define line1 k_ l_ e_ i_ n_ i_ a_ n_ crlf

//======Start shared code for state
#define pz_stateYOffset 0.0
#define pz_stateBuf 0
//#define pz_stateSample(x) texture(iChannel0,x)

vec2 pz_realBufferResolution;
vec2 pz_originalBufferResolution;
float pz_scale;

vec2 pz_nr2vec(float nr) {
    return vec2(mod(nr, pz_originalBufferResolution.x)
                      , pz_stateYOffset+floor(nr / pz_originalBufferResolution.x))+.5;
}

//======End shared code for state

// line function, used in k, s, v, w, x, y, z
float line(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

//These functions are re-used by multiple letters
float _u(vec2 uv,float w,float v) {
    return length(vec2(
                abs(length(vec2(uv.x,
                                max(0.0,-(.4-v)-uv.y) ))-w)
               ,max(0.,uv.y-.4))) +.4;
}
float _i(vec2 uv) {
    return length(vec2(uv.x,max(0.,abs(uv.y)-.4)))+.4;
}
float _j(vec2 uv) {
    uv.x+=.2;
    float t = _u(uv,.25,-.15);
    float x = uv.x>0.?t:length(vec2(uv.x,uv.y+.8))+.4;
    return x;
}
float _l(vec2 uv) {
    uv.y -= .2;
    return length(vec2(uv.x,max(0.,abs(uv.y)-.6)))+.4;
}
float _o(vec2 uv) {
    return abs(length(vec2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;
}

// Here is the alphabet
float aa(vec2 uv) {
    uv = -uv;
    float x = abs(length(vec2(max(0.,abs(uv.x)-.05),uv.y-.2))-.2)+.4;
    x = min(x,length(vec2(uv.x+.25,max(0.,abs(uv.y-.2)-.2)))+.4);
    return min(x,(uv.x<0.?uv.y<0.:atan(uv.x,uv.y+0.15)>2.)?_o(uv):length(vec2(uv.x-.22734,uv.y+.254))+.4);
}
float bb(vec2 uv) {
    float x = _o(uv);
    uv.x += .25;
    return min(x,_l(uv));
}
float cc(vec2 uv) {
    float x = _o(uv);
    uv.y= abs(uv.y);
    return uv.x<0.||atan(uv.x,uv.y-0.15)<1.14?x:length(vec2(uv.x-.22734,uv.y-.254))+.4;
}
float dd(vec2 uv) {
    uv.x *= -1.;
    return bb(uv);
}
float ee(vec2 uv) {
    float x = _o(uv);
    return min(uv.x<0.||uv.y>.05||atan(uv.x,uv.y+0.15)>2.?x:length(vec2(uv.x-.22734,uv.y+.254))+.4,
               length(vec2(max(0.,abs(uv.x)-.25),uv.y-.05))+.4);
}
float ff(vec2 uv) {
    uv.x *= -1.;
    uv.x += .05;
    float x = _j(vec2(uv.x,-uv.y));
    uv.y -= .4;
    x = min(x,length(vec2(max(0.,abs(uv.x-.05)-.25),uv.y))+.4);
    return x;
}
float gg(vec2 uv) {
    float x = _o(uv);
    return min(x,uv.x>0.||uv.y<-.65?_u(uv,0.25,-0.2):length(vec2(uv.x+0.25,uv.y+.65))+.4 );
}
float hh(vec2 uv) {
    uv.y *= -1.;
    float x = _u(uv,.25,.25);
    uv.x += .25;
    uv.y *= -1.;
    return min(x,_l(uv));
}
float ii(vec2 uv) {
    return min(_i(uv),length(vec2(uv.x,uv.y-.7))+.4);
}
float jj(vec2 uv) {
    uv.x += .05;
    return min(_j(uv),length(vec2(uv.x-.05,uv.y-.7))+.4);
}
float kk(vec2 uv) {
    float x = line(uv,vec2(-.25,-.1), vec2(0.25,0.4))+.4;
    x = min(x,line(uv,vec2(-.15,.0), vec2(0.25,-0.4))+.4);
    uv.x+=.25;
    return min(x,_l(uv));
}
float ll(vec2 uv) {
    return _l(uv);
}
float mm(vec2 uv) {
    //uv.x *= 1.4;
    uv.y *= -1.;
    uv.x-=.175;
    float x = _u(uv,.175,.175);
    uv.x+=.35;
    x = min(x,_u(uv,.175,.175));
    uv.x+=.175;
    return min(x,_i(uv));
}
float nn(vec2 uv) {
    uv.y *= -1.;
    float x = _u(uv,.25,.25);
    uv.x+=.25;
    return min(x,_i(uv));
}
float oo(vec2 uv) {
    return _o(uv);
}
float pp(vec2 uv) {
    float x = _o(uv);
    uv.x += .25;
    uv.y += .4;
    return min(x,_l(uv));
}
float qq(vec2 uv) {
    uv.x = -uv.x;
    return pp(uv);
}
float rr(vec2 uv) {
    float x =atan(uv.x,uv.y-0.15)<1.14&&uv.y>0.?_o(uv):length(vec2(uv.x-.22734,uv.y-.254))+.4;
    
    //)?_o(uv):length(vec2(uv.x-.22734,uv.y+.254))+.4);
    
    uv.x+=.25;
    return min(x,_i(uv));
}
float ss(vec2 uv) {
    
    if (uv.y <.145 && uv.x>0. || uv.y<-.145)
        uv = -uv;
    
    float x = atan(uv.x-.05,uv.y-0.2)<1.14?
                abs(length(vec2(max(0.,abs(uv.x)-.05),uv.y-.2))-.2)+.4:
                length(vec2(uv.x-.231505,uv.y-.284))+.4;
    return x;
}
float tt(vec2 uv) {
    uv.x *= -1.;
    uv.y -= .4;
    uv.x += .05;
    float x = min(_j(uv),length(vec2(max(0.,abs(uv.x-.05)-.25),uv.y))+.4);
    return x;
}
float uu(vec2 uv) {
    return _u(uv,.25,.25);
}
float vv(vec2 uv) {
    uv.x=abs(uv.x);
    return line(uv,vec2(0.25,0.4), vec2(0.,-0.4))+.4;
}
float ww(vec2 uv) {
    uv.x=abs(uv.x);
    return min(line(uv,vec2(0.3,0.4), vec2(.2,-0.4))+.4,
               line(uv,vec2(0.2,-0.4), vec2(0.,0.1))+.4);
}
float xx(vec2 uv) {
    uv=abs(uv);
    return line(uv,vec2(0.,0.), vec2(.3,0.4))+.4;
}
float yy(vec2 uv) {
    return min(line(uv,vec2(.0,-.2), vec2(-.3,0.4))+.4,
               line(uv,vec2(.3,.4), vec2(-.3,-0.8))+.4);
}
float zz(vec2 uv) {
    float l = line(uv,vec2(0.25,0.4), vec2(-0.25,-0.4))+.4;
    uv.y=abs(uv.y);
    float x = length(vec2(max(0.,abs(uv.x)-.25),uv.y-.4))+.4;
    return min(x,l);
}

// Spare Q :)
float Q(vec2 uv) {
    
    float x = _o(uv);
    uv.y += .3;
    uv.x -= .2;
    return min(x,length(vec2(abs(uv.x+uv.y),max(0.,abs(uv.x-uv.y)-.2)))/sqrt(2.) +.4);
}

//Render char if it's up
#define ch(l) if (nr++==ofs) x=min(x,l(uv));

//Make it a bit easier to type text
#define a_ ch(aa);
#define b_ ch(bb);
#define c_ ch(cc);
#define d_ ch(dd);
#define e_ ch(ee);
#define f_ ch(ff);
#define g_ ch(gg);
#define h_ ch(hh);
#define i_ ch(ii);
#define j_ ch(jj);
#define k_ ch(kk);
#define l_ ch(ll);
#define m_ ch(mm);
#define n_ ch(nn);
#define o_ ch(oo);
#define p_ ch(pp);
#define q_ ch(qq);
#define r_ ch(rr);
#define s_ ch(ss);
#define t_ ch(tt);
#define u_ ch(uu);
#define v_ ch(vv);
#define w_ ch(ww);
#define x_ ch(xx);
#define y_ ch(yy);
#define z_ ch(zz);

//Space
#define _ nr++;

//Next line
#define crlf uv.y += 2.0; nr = 0.;

void drawText(float time, vec2  uv, inout vec4 color) {
    
    pz_realBufferResolution = resolution.xy;
    
    float anim = smoothstep(0.,1.,smoothstep(15.6, 16.1, time));
 
    uv -= 0.5*resolution.xy;
    uv *= pz_scale = 1.;
    uv += (0.5 + mix(vec2(-.1,.4), vec2(.2,.3),anim)) * resolution.xy;
    uv = (uv-0.5*resolution.xy) / resolution.x * 22.0 * mix(1.,.5,anim);
    
    float ofs = floor(uv.x);
    uv.x = mod(uv.x,1.)-.5;
    
    float x = 1.;
    float nr = 0.;
 
    line1;
        
    float px = 17.0/resolution.x*pz_scale;
    float clr = smoothstep(.46-px,.46+px, x); // The body
  //  float clr = smoothstep(0.49-px,0.49+px, x); // The body
    
    color = mix(color, mix(vec4(0), color, clr), smoothstep(14.6,15., time)*(1.-anim));
}

//-----------------------------------------------

vec2 kColor;

struct Context {
    vec4 mins;
    vec4 maxs;
} ;

Context ctx;

// -------------------------------------------------------------------

float hash1(float seed) {
    return fract(sin(seed)*43758.5453123);
}
vec2 hash2(float seed) {
    return fract(sin(vec2(seed*43758.5453123,(seed+.1)*22578.1459123)));
}
vec3 hash3(float seed) {
    return fract(sin(vec3(seed,seed+.1,seed+.2))*vec3(43758.5453123,22578.1459123,19642.3490423));
}

// -----------------------------------------------------

#define R(p, a) p=cos(a)*p+sin(a)*(vec2)(p.y, -p.x)

//knighty's pseudo kleinian
float pseudoKleinianSlider(vec3 p) {
    float k,r2, scale=1., orb = 1.;
    for(int i=0;i<NB_ITERATION;i++) {
        p = 2.*clamp(p, ctx.mins.xyz,ctx.maxs.xyz)-p;
        r2 = dot(p,p);
        k = max(ctx.mins.w/dot(p,p),1.);
        p *= k;
        scale *= k;
    }
    float rxy=length(p.xy);
    return .8*max(rxy-ctx.maxs.w, /*abs*/(rxy*p.z) / length(p))/scale;
}

vec3 pseudoKleinianSliderColor(vec3 p) {
    float k,r2, scale = 1., orb = 1.;
    for(int i=0;i<NB_ITERATION;i++) {
        p = 2.*clamp(p, ctx.mins.xyz, ctx.maxs.xyz)-p;
        r2 = dot(p,p);
        orb = min(orb, r2);
        k = max(ctx.mins.w/r2,1.);
        p *= k;
        scale *= k;
    }
    return vec3(0., kColor.x + kColor.y*sqrt(orb), orb);
}

float rayIntersect(vec3 ro, vec3 rd, float prec, float mind, float maxd) {
    float h, t = mind;
    for(int i=0; i<MAX_RAYMACING_ITERATION; i++ ) {
        h = DE_RAY(ro+rd*t);
        if (h<prec*t || t>maxd) 
            return t;
        t += h;
    }
    return -1.;
}

vec3 trace(vec3 ro, vec3 rd ) {
    float d = rayIntersect(ro, rd, PRECISION_FACTOR, MIN_DIST_RAYMARCHING, MAX_DIST_RAYMARCHING);
    if (d>0.) {
        return vec3(d, DE_COLOR(ro+rd*d).yz);
    }
    return vec3(-1., 1., 0.);
}

#ifdef WITH_SHADOWS

float shadow(vec3 ro, vec3 rd) {
    float 
        seed = hash1(ro.x*(ro.y*32.56)+ro.z*147.2 + ro.y),
        d = rayIntersect(ro, rd, PRECISION_FACTOR_SHADOW, MIN_DIST_SHADOW, MAX_DIST_SHADOW);
    if (d>0.) {
        return smoothstep(0., MAX_DIST_SHADOW, d);
    }
    return 1.;
}

#endif

#ifdef WITH_AO

float calcAO4( vec3 pos, vec3 nor ) {
    vec3 aopos;
    float hr, dd, 
          occ = 0.,
          sca = 1.;
    for( int i=0; i<5; i++ ) {
        hr = MIN_DIST_AO + MAX_DIST_AO*float(i)/4.;
        aopos =  nor * hr + pos;
        dd = DE_RAY(aopos);
        occ += -(dd-hr)*sca;
        sca *= .95;
    }
    return clamp( 1. - 3.*occ, 0., 1. );    
}

#endif

vec3 calcNormal1( vec3 pos, float t ){
    float precis = PRECISION_FACTOR * t * 0.57;
    vec3 e = vec3(precis, -precis, 0.);

    return normalize(e.xyy*DE_RAY(pos + e.xyy) + 
             e.yyx*DE_RAY(pos + e.yyx) + 
             e.yxy*DE_RAY(pos + e.yxy) + 
             e.xxx*DE_RAY(pos + e.xxx) );
}

vec3 calcNormal( vec3 pos, float t ){
    float precis = PRECISION_FACTOR * t * .47;
    vec3 e = vec3(precis, 0., 0.);

    return normalize(vec3(
        DE_RAY(pos + e.xyy) - DE_RAY(pos - e.xyy), 
                      DE_RAY(pos + e.yxy) - DE_RAY(pos - e.yxy),
                     DE_RAY(pos + e.yyx) - DE_RAY(pos - e.yyx)));
}

vec3 RD(vec3 ro, vec3 ww, vec3 uu, float x, float y, vec2 res, float fov) {
    vec3 vv = normalize(cross(uu,ww));
    vec2 resF = vec2(res);
    float px = (2. * (x/resF.x) - 1.) * resF.x/resF.y, 
          py = (2. * (y/resF.y) - 1.);  

    vec3 er = normalize(vec3( px, py, fov) );
    return normalize( er.x*uu + er.y*vv + er.z*ww );
}

vec4 renderScene(vec3 ro, vec3 rd) {
    vec3 col = vec3(0);
    vec3 res = trace( ro, rd);
    float t = res.x;

    if (t>0.) {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos, t);
        vec3 ref = reflect( rd, nor);
 // Color
    col = .5 + .5*cos( 6.2831*res.y + vec3(0,1,2) ); 

 // lighting        
        vec3 lig = LIGHT_VEC; 
        vec3 hal = normalize( lig-rd);

#ifdef WITH_AO
        float occ = calcAO4(pos, nor);
#else
        float occ = 1.;
#endif

#ifdef WITH_SHADOWS
       float sh = .5+.5*shadow( pos, lig );
#else
        float sh = 1.;
#endif

#ifdef ONLY_AO
    col = (vec3)occ*(.5+.5*sh);
#else

        float amb = .3;

        float dif = clamp( dot( nor, lig ), 0., 1. );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.,-lig.z))), 0., 1. )*clamp( 1.-pos.y,0.,1.);
        float dom = smoothstep( -.1, .1, ref.y );
        float fre = clamp(1.+dot(nor,rd),0.,1.);
        fre *= fre;
        float spe = pow(clamp( dot( ref, lig ), 0., 1. ),99.);

       // dom *= softshadow( pos, ref, 0.02, 2.5 );

    vec3 lin = vec3(.5) + 
            + 1.3*sh*dif*vec3(1.,0.8,0.55)
            + 2.*spe*vec3(1.,0.9,0.7)*dif
            + .5*occ*( .4*amb*vec3(0.4,0.6,1.) +
                    .5*sh*vec3(0.4,0.6,1.) +
                   // .5*bac*vec3(0.25,0.25,0.25) +
                    .25*fre*vec3(1.,1.,1.));

    col = col*lin;

   //     col = mix( col, vec3(0.8,0.9,1.), 1.-exp( -0.0002*t*t*t ) );
        // Light attenuation, based on the distances above.

#endif
        // Shading.
       float lDist = t;
       float atten = 1./(1. + lDist*.2 + lDist*0.1); // + distlpsp*distlpsp*0.02
       col *= atten*col*occ;
       col = mix(col, BACK_COLOR, smoothstep(0., .95, t/MAX_DIST_RAYMARCHING)); // exp(-.002*t*t), etc.

    } else {
    col = BACK_COLOR;// vec3(.08, .16, .34);      
    }

    return vec4(sqrt(col),t);
}

vec4 render(vec2 gl_FragCoord, vec3 ro, vec3 ww, vec3 uu, vec4 sliderMins, vec4 sliderMaxs, vec4 deltaPix, vec4 camera) {
    

    ctx.mins = sliderMins;
    ctx.maxs = sliderMaxs;
    
    
    // create ray with depth of field
    float fov = camera.x; // 3.;
           
  //  ro.y -= 3.;    
  //  ta.y -= 3.;

    vec2 res = resolution.xy;
    vec2 q = (gl_FragCoord+deltaPix.xy)/res;

    vec3 rd = RD(ro, ww, uu, gl_FragCoord.x+deltaPix.x, gl_FragCoord.y+deltaPix.y, res, fov);

    vec3 cback = vec3(.1*(1.-length(q-.5)));
    vec4 col = renderScene(ro, rd);

#ifdef WITH_VIGNETING
    col.rgb *= pow(16.*q.x*q.y*(1.-q.x)*(1.-q.y), .3); // vigneting
#endif

    return col;
}

//"pos":["-0.2994025417140019","0.14442263446217093","0.1132174122314898"],"focdist":1.050137996673584,"width":1920,"up":["-0.25671105336937483","-0.1366277802779863","0.9567822556539688"],"look":["-0.8551618945790584","-0.42915603766625093","-0.290728790102664"]
#define NB 18

vec3 CameraPath( float t ) {
    float[] x = float[] ( .2351, 1.2351, 1.2351, 1., .2, .41, .545,.545, .5,.084,.145,
                         3.04,.12, .44,.44,.416, 
                         -1.404, .21,.2351, .2351),
             y = float[] (-.094,  .35,     .28,  .38,  .04, .11, -.44,-.44,.35,.0614,.418,
                         1.,-.96, .67,.8,.0,
                         -1., -.06,-.094),
             z = float[] ( .608,  .608,    .35,   .3608, -.03, .48,.032,.032, .47,0.201,.05,
                         .28,.3, 1.445,1.,1.4,
                         2.019, .508,.608);

    int i0 = int(t)%NB, i1 = i0+1;
    return mix(vec3(x[i0],y[i0],z[i0]), vec3(x[i1],y[i1],z[i1]), smoothstep(0.,1.,fract(t))); 
}

vec3 LookAtPath( float t ) {
    float[] x = float[] (-.73, -.627, -1., -.3, -1., -.72, -.82,-.82,-.67,-.5,-.07,
                         -.67,-.27, -.35,-.35,-.775,
                         .08, -.727),
            y = float[] (-.364, -.2,   -.2,  -.2,  0., -.39, -.5, -.5,-.56,-.37,-.96,
                         -.74,-.94, -.35,-.35,-.1,
                         .83,-.364),
            z = float[] (-.582, -.582, -.5, -.35, -.0, -.58, -.2776,-.2776,-.48,-.79,-.25,
                         .06,-.18, -.87,-.87,.23,
                         .55, -.582);
    int i0 = int(t)%NB, i1 = i0+1;
    return mix(vec3(x[i0],y[i0],z[i0]), vec3(x[i1],y[i1],z[i1]), smoothstep(0.,1.,fract(t))); 
}

vec4 MinsPath(float t ) {
    float[] x = float[] (-.3252,-.3252,-.3252,-.3252,-.3252,-.3252,-.3252,-1.1, -1.05,-1.05,-1.21,
                         -1.22,-1.04,-0.737,-.62,-10.,
                         -.653,  -.653, -.3252),
             y = float[] (-.7862,-.7862,-.7862,-.7862,-.7862,-.7862,-.7862,-.787, -1.05,-1.05,-.954,
                         -1.17,-.79,-0.73,-.71,-.75,
                         -2.,   -2., -.7862),
             z = float[] (-.0948,-.0948,-.0948,-.0948,-.0948,-.0948,-.0948,-.095,-0.0001,-0.0001,-.0001,
                         -.032,-.126,-1.23,-.85,-.787,
                         -.822, -1.073, -.0948),
            w = float[] ( .69, .69, .69, .69, .69, .678, .678,  .678,.7,.73,1.684,
                         1.49,.833, .627,.77,.826,
                         1.8976, 1.8899, .69);
    
    int i0 = int(t)%NB, i1 = i0+1;
    return mix(vec4(x[i0],y[i0],z[i0],w[i0]), vec4(x[i1],y[i1],z[i1],w[i1]), smoothstep(0.,1.,fract(t))); 
    
}

vec4 MaxsPath( float t ) {
    float[] x = float[] ( .35,.3457,.3457,.3457,.3457, .3457,.3457,.3457, 1.05,1.05,.39,
                         .85,.3457,.73,.72,5.,/*1.58,*/
                         .888,  .735, .35),
             y = float[] (1.,1.0218,1.0218,1.0218,1.0218,1.0218,1.0218,1.0218,1.05,1.05,.65,
                         .65,1.0218,0.73,.74,1.67,
                         /*-0.002,*/ .1665, 1.),
             z = float[] (1.22,1.2215,1.2215,1.2215,1.2215,1.2215,1.2215,1.2215, 1.27,1.4,1.27,
                         1.27,1.2215,.73,.74,.775,
                         /*.6991,*/1.2676, 1.22),
            w = float[] ( .84, .84, .84, .84, .84, .9834,.9834,.9834,.95,.93,2.74,
                         1.23,.9834, .8335,.14,1.172,
                         /*1.018,*/ .7798, .84);
    
    int i0 = int(t)%NB, i1 = i0+1;
    return mix(vec4(x[i0],y[i0],z[i0],w[i0]), vec4(x[i1],y[i1],z[i1],w[i1]), smoothstep(0.,1.,fract(t))); 
}

#define BPM 127.0

void main(void)
{
    // BPM by iq ---------------------------------------------
    float h = 0;//fract( 0.25 + 0.5*iChannelTime[1]*BPM/60.0 );
    float f = 1.0-smoothstep( 0.0, 1.0, h );
    f *= 4.5;//smoothstep( 4.5, 4.51, iChannelTime[1] );
    float r =  exp(-4.0*h);
    // -------------------------------------------------------

    
    float t = .1*time;
    vec3 ro = CameraPath(t),
         ww = LookAtPath(t),
         uu = -normalize(cross(ww, vec3(0,1,0)));
         
    vec4
         deltaPix = vec4(.5),
         camera = vec4(3.,0,0,0),
         sliderMins = MinsPath(t),
         sliderMaxs = MaxsPath(t);
  //  float t0 = mod(t,float(NB));
    kColor = mix(vec2(.25,1.),vec2(.01325,1.23), r*r*(.12+smoothstep(12.,14.,t)));
    
    vec4 c = render(gl_FragCoord.xy, ro, ww, -normalize(cross(uu,ww)), sliderMins, sliderMaxs, deltaPix, camera);
    drawText(mod(t,float(NB)), gl_FragCoord.xy, c);
    glFragColor = c;
    
}
