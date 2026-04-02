#version 420

// original https://www.shadertoy.com/view/3tdczr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// "spherical polyhedra metamorphose"
//
// created by Colling Patrik (cyperus) in 2020
//
// DOCUMENTATION:
// https://math.stackexchange.com/questions/1469554/polyhedral-symmetry-in-the-riemann-sphere
//
////////////////////////////////////////////////////////////////////////////////

// const
const float PI = 3.14159265359;

// 2D transformations: vec2 => vec2
// complex
vec2 cmul(vec2 za,vec2 zb){
    return za*mat2(zb.x,-zb.y,zb.yx);    // za*zb
}
vec2 cinv(vec2 z) {                        // 1/z
  return z*vec2(1,-1)/dot(z,z);
}
vec2 cdiv(vec2 z, vec2 w){                // z/w
  return cmul(z,cinv(w));
}

vec2 cpow(vec2 z, int n) {                // z^n
  float r = length(z);
  float theta = atan(z.y,z.x);
  return pow(r,float(n))*normalize(vec2(cos(float(n)*theta),sin(float(n)*theta)));
}

vec2 crot(vec2 z,float a){
    float si = sin(a), co = cos(a);        // z*e^(j*a)
    return mat2(co,-si,si,co)*z;
}

vec2 metamorph(vec2 z0,vec2 z1, float f){
    if (f<= 0.0) return z0;
    if (f>= 1.0) return z1;
    else return cdiv(cmul(z0,z1),(f*z0+(1.0-f)*z1));
}

float metamorph(float x0,float x1, float f){
    if (f<= 0.0) return x0;
    if (f>= 1.0) return x1;
    return x0*x1/(f* x0+(1.0-f)*x1);
}

//
float smoothrecpuls(float x,float aa,float ab,float ia,float ib){
    /*
    smoothrecpuls is an periodic smooth rectangle-function
    with normalized periode == 1.
    It starts at x == 0 with the first-transition-interval, followed by puls-a-const-
    , second-transition- and puls-b-const-interval.
    float x  : value        (normalized)
    float aa : amplitude pulse a
    float ia : interval puls a        ia in [0,1]  (normalized)
    float ab : amplitude pulse b
    float ib : interval puls b          ib in [0,1]  (normalized)

    check ia+ib < 1.0; it+ia+it+ib = 1.0;
     */
    ia = abs(ia);
    ib = abs(ib);
    // function smooth2puls
    float it = 0.5*(1.-ia-ib); // interval transition
    x = fract(x);
    return   (aa-ab)*smoothstep(0.0        ,it            ,x)+ab
            -(aa-ab)*smoothstep(it+ia    ,it+ia+it    ,x);
}

// 3D-transformations: vec3 => vec3
//color
vec3 hsv2rgb(float h, float s, float v){        // hue, saturation, value
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing       
  return v * mix( vec3(1.0), rgb, s);
}

vec2 isphere(in vec3 ro, in vec3 rd, in float r )
{// sphere centered at the origin, with size rd
    
    float b = dot(ro,rd);
    float c = dot(ro,ro) - r*r;
    float h = b*b - c;
    
    if( h<0.0 ) return vec2(-1.0);

    h = sqrt( h );

    return -b + vec2(-h,h);
}

// camera
const float camedist = 3.0;
const float fle = 2.;
// raymarch
const int maxsteps = 100;
const float maxdist = 4.0;
const float stepmul = 0.3;
// texture
const float vdistri = 0.5;
const float u_sub_div = 6.0, v_sub_div = 6.0;
// anti-aliasing
const float AA = 1.0;

float map( in vec4 pt, out vec4 mat ){
    vec3 p = pt.xyz; float time = pt.w;

    vec3 pn; vec2 zz; int k,n;
    #if 0 // wk2(z)
    // stereographic projection 3D => 2D
    pn = normalize(p);
    zz = pn.xy/(1.0+abs(pn.z));
    // Fk,2(z)
    k = 3;
    vec2 wk2 = float(k) * cdiv( cpow(zz,k) , cpow(cpow(zz,k)-vec2(1.0,0.0),2) );
    float srk2 = float(length(wk2)>1.0?-2:k);
    #endif

    #if 0 // w33(z)
    // stereographic projection 3D => 2D
    pn = normalize(p);
    zz = pn.xy/(1.0-pn.z);
    // F3,3(z)
    const float a1 = 2.*sqrt(2.);
    k = 3; n = 3;
    vec2 zz3 = cpow(zz,k);
    vec2 w33 = 1./(8.*a1) * zz3;
    w33 = cmul(w33, cpow(zz3-vec2(a1,0.),k));
    w33 = cdiv(w33, cpow(zz3+ vec2(1./a1,0.0),n));
    float sr33 = float(length(w33)>1.0?-n:k);
    // sense of rotation of the polygon: sign(sr) in {-1.,+1.}
    // number of sides of the polygon: abs(sr) in {3.,3.}
    #endif

    #if 1 // w43(z)
    // stereographic projection 3D => 2D
    pn = normalize(p);
    pn.xy = crot(pn.xy, sign(pn.z)*PI);
    zz = pn.xy/(1.0+abs(pn.z));
    // F4,3(z)
    k = 4; n = 3;
    vec2 zz4 = cpow(zz,k);
    vec2 w43 = 108.0 * zz4;
    w43 = cmul(w43, cpow(zz4-vec2(1.0,0.),k));
    w43 = cdiv(w43, cpow( cmul(zz4,zz4)+14.0*zz4+ vec2(1.0,0.0) ,n)  );
    float sr43 = float(length(w43)>1.0?-n:k);
    // sense of rotation of the polygon: sign(sr) in {-1.,+1.}
    // number of sides of the polygon: abs(sr) in {3.,4.}
    #endif

    #if 1 // w53(z)
    // stereographic projection 3D => 2D
    pn = normalize(p);
    pn.xy = crot(pn.xy, sign(pn.z)*PI/2.);
    pn.y = -sign(pn.z)*pn.y;
    zz = pn.xy/(1.0+abs(pn.z));
    // F5,3(z)
    k = 5; n = 3;
    vec2 zz5 = cpow(zz,k);
    vec2 zz10 = cmul(zz5,zz5);
    vec2 w53 = 1728.0 * zz5;
    w53 = cmul(w53, cpow(  zz10-11.0*zz5-vec2(1.0,0.0)  ,k));
    w53 = cdiv(w53, cpow(   cmul(zz10,zz10)
                   +228.0*cmul(zz10,zz5)
                   +494.0*zz10
                   -228.0*zz5
                   +vec2(1.0,0.0) ,n)  );
    float sr53 = float(length(w53)>1.0?-n:k);
    // sense of rotation of the polygon: sign(sr) in {-1.,+1.}
    // number of sides of the polygon: abs(sr) in {3.,4.}
    #endif

    vec2 w; float sr;
    #if 0    //switch: single polyhedron, metamorphose of 2 polyhedra
    //select polyhedron from (wk2,srk2 ), (w33,sr33), (w53,sr53), (w43,sr43)
    w = w53; sr = sr53;
    #else
    float ff = smoothrecpuls(0.02*time,0.0,1.0,0.3,0.3);
    //select polyhedra from (wk2,srk2 ), (w33,sr33), (w53,sr53), (w43,sr43)
    w = metamorph(w43,w53,ff); sr = metamorph(sr43,sr53,ff);
    #endif
    // return texture data
    mat = vec4(w,sr,1.0 );

    // uv-coords
    float v = atan(log(length(w))*vdistri)/PI;
 
    // sdf sphere
    float r = 0.3*(3.0+sin(v));
    float d = length(p)-r;
    //
    return d;
}

float intersect( in vec3 ro, in vec3 rd, out vec4 rescol, in float px ,in float time)
{
    float res = -1.0; // init no intersection
    
    // bb boundingbox
    vec2 dis = isphere( ro, rd , 2.);
    
    if( dis.y<0.0 ) // if no hit with bb return
        return -1.0;
    dis.x = max( dis.x, 0.0 );    // start_raylength from bb or minimal_raylength
    dis.y = min( dis.y, maxdist );    // end_raylength from bb or maximal_raylength
    // raymarch signed distance field
    vec4 data; // accumulated data while raymarching
    
    float t = dis.x; // init with start_raylength
    for( int i=0; i<maxsteps; i++  )
    { 
        vec4 pt = vec4(ro + rd*t,time);
        float th = 0.0001*px*t; //th = 0.0001; // iso_surface-hit-delta
        float h = map( pt, data );
        if( t>dis.y || h<th ) break; // reached end_raylength or hit iso_surface
        t += h*stepmul; // step-length-multiplier
    }
    
    if( t<dis.y ) // ray is inside bb
    {
        rescol = data; // return data
        res = t;       // return ray_length
    }
    return res;
}

// transform from mla
vec3 transform(in vec4 p){
    //if (mouse*resolution.xy.x > 0.0)
    //{
        float phi = (2.0*mouse.x*resolution.xy.x-resolution.x)/resolution.x*PI;
        float theta = (2.0*mouse.y*resolution.xy.y-resolution.y)/resolution.y*PI;
        p.yz = crot(p.yz,theta);
        p.zx = crot(p.zx,-phi);
    //}
    p.xz = crot(p.xz,p.w*0.1);
    return p.xyz;
}

void main(void) {
    // global time
    float time = 0.5*time;
    
    // camera
    vec3 ro = transform(vec4(0,0,-camedist,time)).xyz;
    
    // anti-aliasing
    vec3 aacol = vec3(0);
    for (float i = 0.0; i < max(-time,AA); i++) {
        for (float j = 0.0; j < max(-time,AA); j++) {
            // ray direction
            vec2 uv = (2.0*(gl_FragCoord.xy+vec2(i,j)/AA)-resolution.xy)/resolution.y;
            vec3 rd = normalize(transform(vec4(uv,fle,time)));
            // get ray distance to (intersection) hit point
            vec4 mat = vec4(0.0);
            float px = 2.0/( resolution.y*fle );
            float t = intersect( ro, rd, mat, px ,time);

            vec3 col;
            if (t < 0.0){ // sky
                col = vec3(0.8,0.6,1.0)*(0.3+0.2*rd.y); // background-color
            }
            else{ // intersection with surface
                vec3 p = ro + rd * t;// intersection point

                // texture_data, mat = vec4(w,sr,1.0 );
                vec2 w = vec2(mat.s,mat.t); float sr = mat.p;

                // texture_coords
                float u = atan(w.y,w.x)/PI;// u in [-1.,0.,+1.], [green_cyan,red,blue_cyan]
                // length(w) in [0., 1., +inf] => [-inf, 0., +inf] => v in [-1, 0., +1.0], [green_cyan,red,blue_cyan]
                float v = atan(log(length(w))*vdistri)/PI;

                // texture_color
                float col_h = v;
                float col_s=1.0;
                col_s *= 0.9+0.1*sign(sr);
                float col_v = 1.0;
                col_v *=.5+0.5*fract(u_sub_div*(0.5)*(1.+u)+ 0.3* time);
                col_v *=.5+0.5*fract(v_sub_div*(2.0*2.0)*0.5*(1.+v)+ 0.3* time);
                col =  hsv2rgb(col_h, col_s, col_v);// color (hue, saturation, value)
            }
            aacol += col;
        }
    }
    aacol /= float(AA*AA);
    aacol = pow(aacol,vec3(0.4545)); // gamma correction
    glFragColor = vec4(aacol,1);
}
