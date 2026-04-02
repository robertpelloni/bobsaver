#version 420

// original https://www.shadertoy.com/view/Ns2GRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Berry stairs by Julien Vergnaud @duvengar-2021
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
///////////////////////////////////////////////////////////////////////////////////////////
//  ________   ______   ______    ______    __  __      
// /_______/\ /_____/\ /_____/\  /_____/\  /_/\/_/\    
// \    _  \ \\    _\/_\   _ \ \ \   _ \ \ \ \ \ \ \    
//  \  (_)  \/_\ \/___/\\ (_) ) )_\ (_) ) )_\ \_\ \ \    
//   \    _  \ \\  ___\/_\  __ `\ \\  __ `\ \\    _\/    
//    \  (_)  \ \\ \____/\\ \ `\ \ \\ \ `\ \ \ \  \ \    
//     \_______\/ \_____\/ \_\/ \_\/ \_\/ \_\/  \__\/                                                                                                                     
//   ______   _________  ________    ________  ______    ______      
//  /_____/\ /________/\/_______/\  /_______/\/_____/\  /_____/\     
//  \    _\/_\__    __\/\    _  \ \ \__    _\/\   _ \ \ \    _\/_    
//   \ \/___/\  \  \ \   \  (_)  \ \   \  \ \  \ (_) ) )_\ \/___/\   
//    \____ \ \  \  \ \   \   __  \ \  _\  \ \__\  __ `\ \\____ \:\  
//      /__\ \ \  \  \ \   \  \ \  \ \/__\  \__/\\ \ `\ \ \ /__\ \:\ 
//      \_____\/   \__\/    \__\/\__\/\________\/ \_\/ \_\/ \_____\/ 
//
// reference :  FabriceNeyret2 https://www.shadertoy.com/view/3sGfWm
// I have a lot of ideas to use stairs in hexagonal tiling , but to warm up a little bit i just thought why not do a bunch of berries 
// going up and down stairs. Hope you guys like it. 

#define PI2 (2.*acos(-1.))
#define PI acos(-1.)
#define R  vec2(resolution.xy)
#define S(a,b,c) smoothstep(a,b,c)

vec2 h = vec2 (1., 1.73205);

float sat(float a){

    return max(min(a, 1.),.0);
}

vec3 sat(vec3 a){

    return vec3(sat(a.x),sat(a.y),sat(a.z));
}

float hash2(vec2 p){ 

    vec3 p3  = fract(vec3(p.xyx) * .2831);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

///// NOISE /////

float hash(float n) {
    return fract(sin(n)*43758.5453123);   
}

float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0;
    return mix(mix(hash(n + 0.0), hash(n + 1.0), f.x), mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
}

////// FBM ////// 
// see iq // https://www.shadertoy.com/view/lsfGRr

mat2 m = mat2( 0.6, 0.6, -0.6, 0.8);
float fbm(vec2 p){
 
    float f = 0.0;
    f += 0.5000 * noise(p); p *= m * 2.02;
    f += 0.2500 * noise(p); p *= m * 2.03;
    f += 0.1250 * noise(p); p *= m * 2.01;
    f += 0.0625 * noise(p); p *= m * 2.04;
    f /= 0.9375;
    return f;
}

vec4 hexa_grid( vec2 uv){

    vec2 g1 = mod(uv, h)-h*.5;            // first row of hexagons
    vec2 g2 = mod(g1-h, h)-h*.5;          // second row of hexagons
    float row = length(g1)-length(g2);    // row selector 
    g1 = row < .0 ? vec2(g1) : vec2(g2);  // grid of hexagons
    vec2 id = uv-g1;                      // individual id for each hexagons
    return vec4(g1,id);
    
}

vec3 hexa_coords(vec2 hg){

    float x =  1.-(.5-dot(hg, normalize(h.xy))) ;                // up right coords
    float y =  1.-(.5-dot(vec2(-hg.x, hg.y), normalize(h.xy))) ; // up left coords
    float z =  length( hg.x -.5) ;                               // horizontal coords
    
    return vec3(x,y,z);
}

float rect (vec2 p, vec2 b){

    vec2 q = abs(p) - b;
   
    return max(q.x,q.y);
}

vec3 fold( vec3 h, float f ) {

   float x = (1.-mod(-.5+h.x*f,2.));    // right steps
   float y = (1.-mod(-.5+h.y*f,2.));    // left steps
   float z = (1.-mod(1.3+h.z*f*2.,2.)); // horizontal steps

   return vec3(x,y,z);
}

vec4 slopit (vec3 h, vec3 s, float f, float b){
// this part of the code mainly comes from fabrice shader

    float r =  2.*abs(.55+ 2.* h.y-h.x + (abs(s.x)-f*1.1)/f ); // right dented slope shape
    float l =  2.*abs(.55+ 2.* h.x-h.y + (abs(s.y)-f*1.1)/f ); // left dented slope shape
    float rs = S(b,.0,abs(r-.5));                              // right dented slope edges
    float ls = S(b,.0,abs(l-.5));                              // left dented slope edges
    return vec4(r, rs, l, ls); 
}

vec4 faceit( vec3 s, vec4 o, float b){

    float ru = S(.85,.85-b,.8+s.x)-S(.52,.45,1.-o.x);    // right up face
    float rf = S(.85-b,.85,.8+s.x)-S(.52,.45,1.-o.x);    // right front face   
    float lu = S(.85,.85-b,.8 + s.y)-S(.52,.45,1. -o.z); // left up face
    float lf = S(.85-b,.85,.8 + s.y)-S(.52,.45,1.-o.z);  // left front face
    return vec4(ru,rf,lu,lf);
}

vec2 edgit(vec3 s, float b){

    float re = S(.8-b,.8,s.x);                           // right edges
    float le = S(.8-b,.8,s.y);                           // left edges
    return vec2(re, le);
    
}

vec4 ball (vec2 g, vec2 h, float b, vec2 m, float m2){
    

    float el = .06* sin(time*10.);
    vec2 mm = vec2(1.-el,el);
    g.x *= .2+mm.x*.9 ;
    m.y+= mm.y;                                                            // extra animation for bouncing shape 
    float bb = S(.1,.1-b,length( g + m));                                  // ball shape                          
    float be = S(.0+b,.0,abs(length( g + m)-.1));                          // ball edges
    float bs = S(b+m2,.0+m2, 1.*length( h +vec2(-.66,-.55))) ;             // ball shadow   
    float bh = S(b*2.3,.0, length( vec2(.04,-.06) + vec2(.7,1.)*g + m)) ;  // ball highlight 
    return vec4(bb,be,bs,bh);
}

void main(void) {
    
    vec2 u = gl_FragCoord.xy;
    vec4 c = glFragColor;

    float T = -time*.3;
    float z = 1.2*S(200. , 1100., R.y)+1.5;
    vec2 uv = z*(u - .5 * R.xy) / R.y;
    uv.x *= .9;
    
    
    
    float blr = fwidth(uv.y)*R.x/500.;          // antialiasing value

    //// uvs set /////// ////////////////////////////////////////////////////////////
    
    vec2 uva = uv.xy + h*T * .3;                // stairs uvs  
    vec2 iuv = vec2(-uv.x,uv.y);                // horizontaly flipped uvs
    vec2 uvb = iuv - vec2( .0, -2.*h.y*T * .3); // animated up uvs for balls
    vec2 uvc = uv - vec2( h.xy*T*.5 );          // animated down uvs for balls
    vec2 uvs = uv.xy +vec2( T * .2,.0);         // uvs for star pattern
    
    
    ///// grid set //////////////////////////////////////////////////////////////////
    
    vec4 hgrid  = hexa_grid(uva *2.);           // smaller stair grid     
    vec4 bgrid1 = hexa_grid(uvc);               // right ball grid
    vec4 bgrid2 = hexa_grid(uvb);               // left ball grid
    
    ///// hexagons set //////////////////////////////////////////////////////////////
    vec3 hex    = hexa_coords(hgrid.xy);        // hexagonal uvs for stair and balls
    vec3 hex1   = hexa_coords(bgrid1.xy);       
    vec3 hex2   = hexa_coords(bgrid2.xy);
    
    

    //// Stair construction /////////////////////////////////////////////////////////

    
    float st = 8.;                                        /// frequency value for folding
    float r = floor( 2. * hash2(hgrid.zw + vec2(1.)));    /// random value per cel
    
    
    
    vec3 steps  = fold(hex, st);
    vec3 steps2 = fold(hex + vec3(.1), st * 2.); 
    vec4 slope  = slopit(hex,steps, st, blr);
    vec4 faces  = faceit(steps, slope, blr);
    vec2 edges  = edgit(steps2, blr);
    vec4 stairs = vec4(sat(faces.z),sat(faces.w),sat(faces.x),sat(faces.y));

    
    // horizontals not used in this shader :(
    // float h_slope =  2.*abs(.55+ hex.z + hex.y + (abs(stairs.z)-st*3.)/st*.5 );
    // float hfstair = S(.85,.7,1.-(2.*stairs.z))-S(.65,.6,1.-h_slope);
    // float hfstair2 = S(.97,.85,1.-(2.*stairs.z))-S(.65,.6,1.-h_slope);
    // vec2 hs = vec2(max(hfstair,0.),max(hfstair2,0.));
  
    ///// extra motion parameters  /////////////////////////////////////////////////////
    
    vec2  mo  =  vec2(-0.1,-.3+cos(T*30.)*0.03);
    float mo2 = .5-cos(time*20.)*.5;
          mo2 = S(-.5,.5,mo2*.25)*.1;
   
    
    //// balls creation   ///////////////////////////////////////////////////////////////
    
    
    vec4 rbal = ball (bgrid1.xy, hex1.xy, blr, mo, mo2);
    vec4 lbal = ball (bgrid2.xy, hex2.xy, blr, mo, mo2);
    
    
    /// extra stuff to make ball looks more like cute berry
    float el = .05* sin(time*10.);
    float el2 = .055* sin(time*10.);
    
    float rod =  S(.005,.0,rect (vec2(.2,0.01)+bgrid1.xy + mo+vec2(-.19-(el/10.),-.1+el), vec2(.003,.02)));
    float rod2 =  S(.005,.0,rect (vec2(.2,0.01)+bgrid2.xy + mo+vec2(-.19-(el/10.),-.1+el), vec2(.003,.02)));
    float eye =  S(.015,.01,length(bgrid1.xy+mo+vec2(.22,.12)+vec2(-.19-(el/10.),-.1+el)));
    eye +=  S(.015,.01,length(bgrid1.xy+mo+vec2(.26,.1)+vec2(-.19-(el/10.),-.1+el)));
     eye*=2.;
    float eyew =  S(.025,.02,length(bgrid1.xy+mo+vec2(.22,.12)+vec2(-.19-(el/10.),-.1+el2)));
    eyew +=  S(.025,.02,length(bgrid1.xy+mo+vec2(.26,.1)+vec2(-.19-(el/10.),-.1+el2)));
     
    eye = fract(T+bgrid1.z*bgrid1.w)>.86 ? .0: eye;
    eyew = fract(T+bgrid1.z*bgrid1.w)>.86 ? .0: eyew;
    
    //// mask set creation ///////////////////////////////////////////////////////////

    float r_mask = sat(rod+stairs.z + stairs.w + rbal.x + slope.y);
    float l_mask = sat(rod2+stairs.x + stairs.y + lbal.x + slope.w);
    //float smask = sat(stairs.z + stairs.w );
   // float smask2 = sat(stairs.x+stairs.y);

                
    ///////// shading //////////////////////////////////////////////////////////////////
    float f1 = fbm(uv*50.);
    float f2 = fbm(uv*10.);
    float f3 = fbm(uv*4.);

    float tex = (f1+f2+f3)*.33;
   

   
    ///////// stair shade 01 
    vec3 col = vec3( rbal.x,
                     stairs.z - rbal.x -rbal.z ,
                     stairs.z + stairs.w - rbal.x );
  
    col.rgb = sat(col.rgb);
    ///////// stair shade 02 
    vec3 col2 = vec3( lbal.x,
                      stairs.x - lbal.x - lbal.z,
                      stairs.x + stairs.y - lbal.x);
                      
    col2.rgb = sat(col2.rgb);
    col2 = col2.zyx;

    //// save colors
    vec3 bg = col2;
    vec3 bg2 = col;
    

    //// shadow effect under stairs
    float ss =  S(.5,0.,length(hex.y-.25))-min(1.-r_mask,.0) ;
    ss = mix(.0,ss, l_mask-lbal.x-rbal.x);
    bg.g -= ss;
    float iss =  S(.5,.0,length(hex.x-.25))-min(1.-l_mask,.0) ;
    iss = mix(.0,iss, r_mask-lbal.x-rbal.x);
    bg2.g -= iss;
    
    
    ///// applying highlights on balls
    float amp  =  r>.0 ? 1.: 0.0;
    float amp2 = r >.0 ? 0.: 1.;
    bg.rgb += lbal.w >.0 ? amp2:0.; 
    col.rgb += rbal.w >.0 ? amp:0.; 
    bg2.rgb  += rbal.w > .0 ? amp  : 0.; 
    col2.rgb += lbal.w > .0 ? amp2 : 0.;
    
    bg2.rgb += eyew >.0 ? 1.:0.; 
    col.rgb += eyew >.0 ? 1.:0.; 

    
    
    
    /////// creating stroke lines 
    rbal.x-=rod;
    lbal.x-=rod2;
    
    float s1 = mix(rod2+slope.w-lbal.x+lbal.y ,slope.y,min(r_mask,1.));
    
    s1 +=  mix(.0 ,edges.x,min(r_mask,1.));
    s1 +=  mix(.0 ,edges.y-lbal.x,max(min(l_mask-r_mask,1.),0.));
    s1 -= rbal.x*(1.-eye);
    s1 += rbal.y ;
    s1 += rod;
    s1 += eye;
 
    
    
    float s2 = mix(2.*eye+rod+slope.y-rbal.x+rbal.y ,slope.w,min(l_mask,1.));
    s2 +=  mix(.0 ,edges.y,min(l_mask,1.));;
    s2 +=  mix(.0 ,edges.x-rbal.x,max(min(r_mask-l_mask,1.),0.)); 
    s2 -= lbal.x;
    s2 += lbal.y;
    s2 += rod2;
    //s2 += smask >.0 ? eye : .0;
   
    
    s1 = sat(1.-s1);
    s2 = sat(1.-s2);
    
    //// masking outlines
    vec3 cd1 = mix(bg ,col,r_mask);
    vec3 cd2 = mix(bg2 ,col2,l_mask);
    //// random distribution
    vec3 cc = r >.0 ? cd1 : cd2;
    c.rgb = r >.0 ? vec3(s1) : vec3(s2);
    

   
   ///// small post prod and might/day effect
   float noise = hash2(uv*2345.56);
   
   

   c.rgb *= cc;
   c.rgb = sat(c.rgb);

   
   float star = hash2(floor(uvs.yx*30.));
   vec2 starsuv = .5-fract(uvs*30.);
   float sstar = star > .995 ? S(.3,.2,length(starsuv)):.0;
         sstar += star < .96 && star > .95 ? S(.2,.1,length(starsuv)):.0;
  
   c.bg += r_mask+l_mask <= .0 ? vec2(1.,.6): vec2(.0); 
   c.bg += r_mask+l_mask <= .0 ? .6*(1.-length(-.5+uv.y*.5)): .0; 
  
   
   vec4 night = mix(c.rgra*.7, c, .4);
   night += r_mask+l_mask <= .0 ? sstar : .0; 
   night.rg -= r_mask+l_mask <= .0 ? (1.-length(-.5+uv.y*.5)) : .0; 
   night.bg += r_mask+l_mask <= .0 ? vec2(.1,.1): vec2(.0); 

   
   c = mix(c,night,sin(T)*.5+.5);
   c += vec4(noise)*.1;
   

   c -= vec4(vec3(tex),.0)*.2;
   
   //c = vec4(s1,.0,.0,.0);
    
   glFragColor = c;

}
