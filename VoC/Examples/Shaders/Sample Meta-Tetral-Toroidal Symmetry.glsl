#version 420

// original https://www.shadertoy.com/view/3ldcWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License.
//
// "meta-tetra-torodial symmetry v0"
//
// created by Colling Patrik (cyperus) in 2020
//
////////////////////////////////////////////////////////////////////////////////

const float cam_dist = 5.5; // camera distance
const float bb_size = 2.5; // bounding box size
const float rm_rlmin = 0.0; // ray march ray_length minimum
const int   rm_imax = 333; // ray march maximal number of iterations
const float rm_p3slmul = 0.32772; // ray march power(step length multiplier,3)
// anti-aliasing
const float AA = 1.0;

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
vec2 cpowq(vec2 z, float q){            // z^q
    float r = pow(length(z), q);
    float a=q* atan(z.y,z.x);
    return vec2(r*cos(a),r*sin(a));
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
vec2 crpt(vec2 z,float a, float p, float x0){    // z_out = (z*e^ia)^p-x0
    return cpowq( cmul(z, vec2(cos(-a),sin(-a))),p) - vec2(x0, 0.);
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

////////////////////////////////////////////////////////////////////////////////

float map( in vec3 p, out vec4 mat ){

    //// sdf's
    // stereographic projection 3D => 2D
    vec3 pn = normalize(p);
    vec2 zz = pn.xy/(1.0-pn.z);
    float a1 = 2.*sqrt(2.);
    vec2 zz3 = cpow(zz,3);
    vec2 w = 1./(8.*a1) * zz3;
    w = cmul(w, cpow(zz3-vec2(a1,0.),3));
    w = cdiv(w, cpow( zz3+ vec2(1./a1,0.0) ,3) );
    float sr = float(length(w)>1.0?-3:3);

    float r, rxy, au, av;
    vec2 z = vec2(0.); float metaPoly =  1.0;
    au = atan(w.y,w.x)-0.5*PI*sign(sr);
    av = atan(log(length(w))*0.1);

    // spherical => cartesian // TODO: optimization potential
    p = length(p)*vec3(    sin(av)*cos(au),
                sin(av)*sin(au),
                cos(av));

    // torus
    au = atan(p.y, p.x);
    rxy = length(p.xy);
    z = vec2(rxy, p.z);
    z = cmul(z,z); z.x += 4.0;

    float ssr = sign(sr);
    // fractal level 1
    z = crpt(z, -ssr*au/3.0, 3.0,  2.0+3.0*cos(au));

    // fractal level 2
    z = crpt(z, PI*ssr*0.03 * time, 2.0, 1. + 0.5 * cos(0.03*time) );

    mat = vec4(z,au,sr);
    return log(length(z)); // :( Not perfect!
}

float intersect( in vec3 ro, in vec3 rd, out vec4 rescol, in float px )
{
    float res = -1.0; // init no rayintersection
    
    // boundingshape
    vec2 dis = isphere( ro, rd ,abs(bb_size));
    if( dis.y<0.0 ) // Does ray hit boundingshape?
        return -1.0;
    dis.x = max( dis.x, max(rm_rlmin,0.0) );// start_raylength from bb_near_hit or raylength_minimum
    dis.y = min( dis.y, 10.0 );    // end_raylength from bb_far_hit or raylength_maximum
    // raymarch signed distance field
    vec4 data; // data from surface hit point and accumulated data while raymarching
    
    float fh = (0.5-0.0001)*rm_p3slmul*rm_p3slmul*rm_p3slmul + 0.0001;// ray iteration starts at boundingshape
    float t = dis.x;
    for( int i=0; i<rm_imax; i++  )
    { 
        vec3 pos = ro + rd*t;
        float th = 0.0001*px*t; // delta_sdf_surface_hit
        float h = map(pos, data);
        if( t>dis.y || h<th ) break; // ray is outside boundingshape or sdf_surface_hit.
        t += h*fh; // step_length * step_length_multiplier
    }
    
    if( t<dis.y ) // Is ray inside boundingshape?
    {
        rescol = data; // return data
        res = t; // return ray_length
    }
    return res;
}

vec3 calcNormal( in vec3 pos, in float px )
{
    vec4 tmp; // dummy variable
    vec2 e = vec2(1.0,-1.0)*0.5773*0.25*px;
    return normalize( e.xyy*map( pos + e.xyy,tmp ) + 
                      e.yyx*map( pos + e.yyx,tmp ) + 
                      e.yxy*map( pos + e.yxy,tmp ) + 
                      e.xxx*map( pos + e.xxx,tmp ) );
}

// from iq
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<1; i++ )
    {
        vec4 temp;
        float h = map( ro + rd*t, temp );
        res = min( res, 8.0*h/t );
        t += h*.25;
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0., 1. );
}

// from iq
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    // antialeasing
    for( int i=0; i<1; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        vec4 temp;
        float dd = map( aopos, temp );
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
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
    p.xz = crot(p.xz,p.w*0.01);
    return p.xyz;
}

void main(void)
{
    // time
    float time = time;
    // camera
    float fle = 2.0;
    vec3 ro = transform(vec4(0,0,-cam_dist,time)).xyz;

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
            float t = intersect( ro, rd, mat, px );

            // light
            const vec3 ld = 0.5*vec3(0.,1.,.5); // ligth direction
            const vec3 lc = vec3(0.4);// ligth color
            //vec3 bg = vec3(0.8,0.9,1.0)*(0.6+0.4*rd.y);    // background-color
            vec3 bg = vec3(0.8,0.9,2.0)*0.3*(0.9+0.1*rd.y);    // background-color

            // color
            vec3 col = vec3(0.6,0.4,0.7);

            if (t < 0.0){ // sky
                col = bg;
                col += 6.0*vec3(0.8,0.7,0.5)*pow( clamp(dot(rd,lc),0.0,1.0), 32.0 ); // sun
            }
            else{ // hit with object surface
                vec3 p = ro + rd * t;
                vec3 n = calcNormal( p, px );

                // texture_coords
                float u = mat.z*0.5/PI;
                float v = sign(mat.w)*atan(mat.y,mat.x)*0.5/PI;

                // texture_color
                float l = 0.5+0.5*cos(0.3*time);
                float col_h = 1.0;
                col_h *= v;
                //col_h *= u;
                float col_s = 1.0;
                float col_v = 1.0;
                col = hsv2rgb(col_h,col_s,col_v); //(hue, saturation, value)

                // lighting
                float occ = calcAO( p, n );
                float amb = clamp( 0.5+0.5*n.y, 0.0, 1.0 );
                vec4 temp; // dummy variable
                float dif = clamp( dot( n, ld ), 0.0, 1.0 ) * map( p+n*1.16, temp);
                float spe = pow(clamp( dot( rd, ld ), 0.0, 1.0 ),16.0);
                float sss = map( p - n*0.001, temp)/0.01;

                // shading
                dif *= softshadow( p, ld, 0.1, 1. );
                vec3 brdf = vec3(0.0);
                brdf += 0.2*dif*vec3(1.00,0.90,0.60);
                brdf += 0.2*spe*vec3(0.8,0.60,0.20)*dif;
                brdf += 0.2*amb*vec3(0.40,0.60,0.40)*occ;
                brdf += 0.4;
                col.rgb *= brdf;
                // fog
                col = mix( bg,col, exp( -0.025*t*t));
            }
            aacol += col;
        }
    }
    aacol /= float(AA*AA);
    // gamma
    aacol = sqrt(aacol);
    glFragColor = vec4(aacol,1.);
}
