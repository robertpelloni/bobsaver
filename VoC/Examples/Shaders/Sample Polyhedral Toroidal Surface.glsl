#version 420

// original https://www.shadertoy.com/view/wldcD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License.
//
// "surface with cyclic-regular-polyhedral-toroidal symmetry"
//
// created by Colling Patrik (cyperus) in 2020
//
// CODE snippets from
// - jorge2017a1 => https://www.shadertoy.com/view/3sjyDh
// - mla
// - iq 
//
// DOCUMENTATION:
// - https://math.stackexchange.com/questions/1469554/polyhedral-symmetry-in
//   -the-riemann-sphere
// - https://www.iquilezles.org/www/articles/raymarchingdf/raymarchingdf.htm
// - https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
//
// DESCRIPTION:
// - Choose a cyclic regular polyhedral base transformation. Parameterize.
//   {torus, spherical-truncated-tetrahedron, spherical-truncated-octahedron,
//   spherical-truncated-dodecahedron}
// - Activate up to 2 levels of toroidal transformations. Parameterize.
//
// TODO:
// (0)Optimize transformation by avoiding trigonometric functions.
// (1)Eliminate artifacts caused by stereographic projection and the tan()
//    function.
// (2)Use a more mathematical based approach to estimate the ray step length,
//    reducing the number of iterations in the raymarch loop.
//
////////////////////////////////////////////////////////////////////////////////

//#define PRESET_Shape_000
//#define PRESET_Shape_001
#define PRESET_Shape_002
//#define PRESET_Shape_003
//#define PRESET_Shape_004
//#define PRESET_Shape_005
//#define PRESET_Shape_006
//#define PRESET_Shape_007

#ifdef PRESET_Shape_000
const float cam_dist = 4.7470617;
const float bb_size = -3.0;
const float rm_rlmin = 0.0;
const int rm_imax = 333;
const float rm_p3slmul = 0.3;
const bool texture_ON = true;
const int tex_u_subdiv = 11;
const int tex_v_subdiv = 2;
const bool shade_ON = true;
const bool fog_ON = true;
const int ba_id = 1;
const float ba_v_distri = 1.0;
const float ba_sh_a = -5.87952;
const float end_r0 = 1.0;
const bool j1_ON = true;
const float j1_sh_a0 = 5.0;
const float j1_sh_a1 = 0.5;
const int j1_sh_f1 = 1;
const float j1_sh_p1 = -0.037736;
const float j1_sh_pv1 = 0.3;
const int j1_to_c = 0;
const int j1_to_f = 2;
const float j1_to_p = 0.03773606;
const float j1_to_pv = 0.1;
const bool j2_ON = true;
const float j2_sh_a0 = -2.0;
const float j2_sh_a1 = 3.5;
const int j2_sh_f1 = 0;
const float j2_sh_p1 = -0.19999999;
const float j2_sh_pv1 = 0.07;
const int j2_to_c = -1;
const int j2_to_f = 4;
const float j2_to_p = 0.0;
const float j2_to_pv = 0.05;
#endif // PRESET_Shape_000

#ifdef PRESET_Shape_001
const float cam_dist = 4.852944;
const float bb_size = -3.0;
const float rm_rlmin = 0.0;
const int rm_imax = 333;
const float rm_p3slmul = 0.3;
const bool texture_ON = true;
const int tex_u_subdiv = 11;
const int tex_v_subdiv = 2;
const bool shade_ON = true;
const bool fog_ON = true;
const int ba_id = 3;
const float ba_v_distri = 0.5;
const float ba_sh_a = -4.5;
const float end_r0 = 1.0;
const bool j1_ON = true;
const float j1_sh_a0 = 1.0291395;
const float j1_sh_a1 = 0.5;
const int j1_sh_f1 = 1;
const float j1_sh_p1 = 0.0;
const float j1_sh_pv1 = 0.3;
const int j1_to_c = 1;
const int j1_to_f = 2;
const float j1_to_p = 0.0;
const float j1_to_pv = 0.1;
const bool j2_ON = true;
const float j2_sh_a0 = -2.0;
const float j2_sh_a1 = 3.5;
const int j2_sh_f1 = 0;
const float j2_sh_p1 = -0.19999999;
const float j2_sh_pv1 = 0.07;
const int j2_to_c = -1;
const int j2_to_f = 4;
const float j2_to_p = 0.0;
const float j2_to_pv = 0.05;
#endif // PRESET_Shape_001

#ifdef PRESET_Shape_002
const float cam_dist = 5.67198;
const float bb_size = -3.849708;
const float rm_rlmin = 0.0;
const int rm_imax = 303;
const float rm_p3slmul = 0.268786;
const bool texture_ON = true;
const int tex_u_subdiv = 1;
const int tex_v_subdiv = 1;
const bool shade_ON = true;
const bool fog_ON = true;
const int ba_id = 3;
const float ba_v_distri = 0.3669623;
const float ba_sh_a = -4.219776;
const float end_r0 = 1.0;
const bool j1_ON = true;
const float j1_sh_a0 = 1.0291395;
const float j1_sh_a1 = 0.10017967;
const int j1_sh_f1 = 3;
const float j1_sh_p1 = 0.12568402;
const float j1_sh_pv1 = 0.0631578;
const int j1_to_c = 1;
const int j1_to_f = 2;
const float j1_to_p = -0.92714;
const float j1_to_pv = 0.16120201;
const bool j2_ON = true;
const float j2_sh_a0 = -1.88995;
const float j2_sh_a1 = 3.4928207;
const int j2_sh_f1 = 2;
const float j2_sh_p1 = -0.19999999;
const float j2_sh_pv1 = 0.0746412;
const int j2_to_c = -1;
const int j2_to_f = 4;
const float j2_to_p = 0.060109973;
const float j2_to_pv = -0.1896174;
#endif // PRESET_Shape_002

#ifdef PRESET_Shape_003
const float cam_dist = 5.67198;
const float bb_size = -5.531712;
const float rm_rlmin = 0.0;
const int rm_imax = 1460;
const float rm_p3slmul = 0.378815;
const bool texture_ON = true;
const int tex_u_subdiv = 1;
const int tex_v_subdiv = 1;
const bool shade_ON = true;
const bool fog_ON = false;
const int ba_id = 3;
const float ba_v_distri = 0.48437533;
const float ba_sh_a = -8.0;
const float end_r0 = 1.0;
const bool j1_ON = true;
const float j1_sh_a0 = -0.31099987;
const float j1_sh_a1 = 1.62679;
const int j1_sh_f1 = 0;
const float j1_sh_p1 = 0.425838;
const float j1_sh_pv1 = 0.0631578;
const int j1_to_c = 4;
const int j1_to_f = 5;
const float j1_to_p = -0.31100398;
const float j1_to_pv = 0.0588516;
const bool j2_ON = false;
const float j2_sh_a0 = 1.6149902;
const float j2_sh_a1 = 0.0;
const int j2_sh_f1 = 0;
const float j2_sh_p1 = 0.14624596;
const float j2_sh_pv1 = -0.050988004;
const int j2_to_c = 0;
const int j2_to_f = 3;
const float j2_to_p = 0.012920022;
const float j2_to_pv = 0.3;
#endif // PRESET_Shape_003

#ifdef PRESET_Shape_004
const float cam_dist = 5.67198;
const float bb_size = -5.531712;
const float rm_rlmin = 0.0;
const int rm_imax = 1460;
const float rm_p3slmul = 0.378815;
const bool texture_ON = true;
const int tex_u_subdiv = 1;
const int tex_v_subdiv = 1;
const bool shade_ON = true;
const bool fog_ON = false;
const int ba_id = 1;
const float ba_v_distri = 0.48437533;
const float ba_sh_a = -8.0;
const float end_r0 = 1.0;
const bool j1_ON = true;
const float j1_sh_a0 = -0.31099987;
const float j1_sh_a1 = 1.62679;
const int j1_sh_f1 = 2;
const float j1_sh_p1 = 0.425838;
const float j1_sh_pv1 = 0.0631578;
const int j1_to_c = -1;
const int j1_to_f = 5;
const float j1_to_p = 0.0;
const float j1_to_pv = 0.0;
const bool j2_ON = false;
const float j2_sh_a0 = 1.6149902;
const float j2_sh_a1 = 0.0;
const int j2_sh_f1 = 0;
const float j2_sh_p1 = 0.14624596;
const float j2_sh_pv1 = -0.050988004;
const int j2_to_c = 0;
const int j2_to_f = 3;
const float j2_to_p = 0.012920022;
const float j2_to_pv = 0.3;
#endif // PRESET_Shape_004

#ifdef PRESET_Shape_005
const float cam_dist = 5.67198;
const float bb_size = -5.531712;
const float rm_rlmin = 0.0;
const int rm_imax = 1460;
const float rm_p3slmul = 0.378815;
const bool texture_ON = true;
const int tex_u_subdiv = 1;
const int tex_v_subdiv = 1;
const bool shade_ON = false;
const bool fog_ON = false;
const int ba_id = 1;
const float ba_v_distri = 1.0;
const float ba_sh_a = -3.4506078;
const float end_r0 = 1.0;
const bool j1_ON = true;
const float j1_sh_a0 = 2.0095701;
const float j1_sh_a1 = -1.6746399;
const int j1_sh_f1 = 2;
const float j1_sh_p1 = -0.029586017;
const float j1_sh_pv1 = 0.0631578;
const int j1_to_c = 2;
const int j1_to_f = 3;
const float j1_to_p = 0.0;
const float j1_to_pv = 0.0;
const bool j2_ON = false;
const float j2_sh_a0 = 1.6149902;
const float j2_sh_a1 = 0.0;
const int j2_sh_f1 = 0;
const float j2_sh_p1 = 0.14624596;
const float j2_sh_pv1 = -0.050988004;
const int j2_to_c = 0;
const int j2_to_f = 3;
const float j2_to_p = 0.012920022;
const float j2_to_pv = 0.3;
#endif // PRESET_Shape_005

#ifdef PRESET_Shape_006
const float cam_dist = 5.663412;
const float bb_size = 2.4986763;
const float rm_rlmin = 0.0;
const int rm_imax = 387;
const float rm_p3slmul = 0.302387;
const bool texture_ON = true;
const int tex_u_subdiv = 1;
const int tex_v_subdiv = 1;
const bool shade_ON = true;
const bool fog_ON = true;
const int ba_id = 1;
const float ba_v_distri = 1.0;
const float ba_sh_a = -3.39568;
const float end_r0 = 1.0;
const bool j1_ON = true;
const float j1_sh_a0 = 1.7441897;
const float j1_sh_a1 = 2.9328198;
const int j1_sh_f1 = 1;
const float j1_sh_p1 = 0.0;
const float j1_sh_pv1 = 0.0;
const int j1_to_c = -1;
const int j1_to_f = 3;
const float j1_to_p = -0.031620026;
const float j1_to_pv = 0.0;
const bool j2_ON = true;
const float j2_sh_a0 = 1.5714302;
const float j2_sh_a1 = -0.19048023;
const int j2_sh_f1 = 0;
const float j2_sh_p1 = 0.0;
const float j2_sh_pv1 = 0.0;
const int j2_to_c = 0;
const int j2_to_f = 2;
const float j2_to_p = 0.012920022;
const float j2_to_pv = 0.3;
#endif // PRESET_Shape_006

#ifdef PRESET_Shape_007
const float cam_dist = 4.852944;
const float bb_size = -3.0;
const float rm_rlmin = 0.0;
const int rm_imax = 333;
const float rm_p3slmul = 0.3;
const bool texture_ON = true;
const int tex_u_subdiv = 11;
const int tex_v_subdiv = 2;
const bool shade_ON = true;
const bool fog_ON = true;
const int ba_id = 3;
const float ba_v_distri = 0.5;
const float ba_sh_a = -4.5;
const float end_r0 = 1.0;
const bool j1_ON = true;
const float j1_sh_a0 = 1.0291395;
const float j1_sh_a1 = 0.5;
const int j1_sh_f1 = 1;
const float j1_sh_p1 = 0.0;
const float j1_sh_pv1 = 0.3;
const int j1_to_c = 1;
const int j1_to_f = 2;
const float j1_to_p = 0.0;
const float j1_to_pv = 0.1;
const bool j2_ON = true;
const float j2_sh_a0 = -2.0;
const float j2_sh_a1 = 3.5;
const int j2_sh_f1 = 0;
const float j2_sh_p1 = -0.19999999;
const float j2_sh_pv1 = 0.07;
const int j2_to_c = -1;
const int j2_to_f = 4;
const float j2_to_p = 0.0;
const float j2_to_pv = 0.05;
#endif // PRESET_Shape_007

// const
const float PI = 3.14159265359;

// 2D transformations: vec2 => vec2
// complex
vec2 cmul(vec2 za,vec2 zb) // za*zb
{
    return za*mat2(zb.x,-zb.y,zb.yx);
}

vec2 cinv(vec2 z) // 1/z
{
    return z*vec2(1.,-1.)/dot(z,z);
}

vec2 cdiv(vec2 z, vec2 w) // z/w
{
    return cmul(z,cinv(w));
}

vec2 cpow(vec2 z, int n) // z^n
{
    vec2 w = z;
    for (int i = 1; i < n; i++){
    w = cmul(w,z);
    }
    return w;
}

vec2 crot(vec2 z,float a) // z*e^(i*a)
{
    return cmul(z, vec2(cos(-a),sin(-a)));
}

vec2 crpt(vec2 z,float a, int n, float x0) // z_out = (z*e^ia)^n-x0
{
    return cpow(crot(z, a), n) - vec2(x0, 0.);
}

// 3D-transformations: vec3 => vec3
//color
vec3 hsv2rgb(float h, float s, float v)  // hue, saturation, value
{
    vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing
    return v * mix( vec3(1.0), rgb, s);
}

vec2 isphere(in vec3 ro, in vec3 rd, in float r )
{
    // sphere centered at the origin, with size rd
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
    vec3 pn; vec2 z; float r, au, av, sr;
    float ba_sh_a1 = ba_sh_a;
    /// Torus
    sr = 1.0;

    /// cyclic regular Polyeder ba_id in {1,2,3}
    if(  ba_id == 1 || ba_id == 2 || ba_id == 3 ){
        // F3,3(z)
        if (ba_id == 1){
            // stereographic projection 3D => 2D
            pn = normalize(p);
            z = pn.xy/(1.0-pn.z);
            // F3,3(z)
            int k = 3, n = 3;
            float a1 = 2.*sqrt(2.);
            vec2 z3 = cpow(z,k);
            z = 1./(8.*a1) * z3;
            z = cmul(z, cpow(z3-vec2(a1,0.),k));
            z = cdiv(z, cpow( z3+ vec2(1./a1,0.0) ,n)  );
            sr = float(length(z)>1.0?-n:k);
        }

        // F4,3(z)
        if (ba_id == 2){
            // stereographic projection 3D => 2D
            pn = normalize(p);
            z = pn.xy/(1.0+abs(pn.z));
            if(pn.z<0.0){ z.x *= -1.0;}
            // F4,3(z)
            int k = 4, n = 3;
            vec2 z4 = cpow(z,k);
            z = 108.0 * z4;
            z = cmul(z, cpow(z4-vec2(1.0,0.),k));
            z = cdiv(z, cpow( cmul(z4,z4)+14.0*z4+ vec2(1.0,0.0) ,n)  );
            sr = float(length(z)>1.0?-n:k);
        }

        // F5,3(z)
        if (ba_id == 3){
            // stereographic projection 3D => 2D
            pn = normalize(p);
            z = pn.xy/(1.0+abs(pn.z));
            if(pn.z<0.0){ z.x *= -1.0;}
            // F5,3(z)
            int k = 5, n = 3;
            vec2 z5 = cpow(z,k);
            vec2 z10 = cmul(z5,z5);
            z = 1728.0 * z5;
            z = cmul(z, cpow( z10-11.0*z5-vec2(1.0,0.0) ,k));
            z = cdiv(z, cpow( cmul(z10,z10)
                           +228.0*cmul(z10,z5)
                           +494.0*z10
                           -228.0*z5
                           +vec2(1.0,0.0) ,n)  );
            sr = float(length(z)>1.0?-n:k);
            // sense of rotation of the polygon: sign(sr) in {-1.,+1.}
            // number of sides of the polygon: abs(sr) in {n,k}
        }

        //
        ba_sh_a1 *= -1.0; // adapt direction to be in line with torus.
        au = atan(z.y,z.x); // au in [-PI,+PI]
        // av in [-PI,+PI]
        float m = -ba_v_distri;
        float f_v_distri = sqrt( 1.0+pow(0.5*ba_sh_a1/m ,2.0))+0.5*ba_sh_a1 / m;
        // length(w) in [0., 1., +inf] => [-inf, 0., +inf] => av in [-0.5*PI,+0.5*PI]
        av = atan(log(length(z))*f_v_distri);

        // spherical => cartesian
        au += -0.5 * PI * sign(sr);
        p = length(p)*vec3(    sin(av)*cos(au),
                    sin(av)*sin(au),
                    cos(av));
    }

    /// Torus:
    // 3D-space: cartesian3D => cylinder3D transformation
    au = atan(p.y, p.x); //float in [-PI, +PI]
    r = length(p.xy);     //float in [0., +inf]
    // 2D-space: complex plane := radial plane in cylinderc coordinates
    z = vec2(r, p.z);
    
    /// 2Djulia :realaxis-translation, fraction == 2 => (torus,sphere,2spheres)
    z = cmul(z,z); z.x += ba_sh_a1;
    float ssr = sign(sr);

    //float fru = 1.0; // fractions in u-direction
    /// 2Djulia realaxis-translation,fraction,rotation,torsion
    if (j1_ON){
    float j1_sh = j1_sh_a0 + j1_sh_a1 * cos(float(j1_sh_f1) *(au - PI*(j1_sh_p1+j1_sh_pv1*time)));
    float j1_to = ssr * (au*float(j1_to_c)/float(j1_to_f) + PI*(j1_to_p+j1_to_pv*time));
    z = crpt(z, j1_to, j1_to_f,  j1_sh);
    //fru *= (j1_sh_f1 == 0)?1.0:float(j1_sh_f1);
    }

    /// 2Djulia realaxis-translation,fraction,rotation, torsion
    if (j2_ON){
    float j2_sh = j2_sh_a0 + j2_sh_a1 * cos(float(j2_sh_f1) * (au - PI*(j2_sh_p1+j2_sh_pv1*time)));
    float j2_to = ssr * (au*float(j2_to_c)/float(j2_to_f) + PI*(j2_to_p+j2_to_pv*time));
    z = crpt(z, j2_to, j2_to_f,  j2_sh);
    //fru *= (j2_sh_f1 == 0)?1.0:float(j2_sh_f1);
    }

    mat = vec4(z,au,sr);
    float res = log(length(z)/end_r0); // TODO:  :( Not perfect!

    return res;
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

    float fh = (0.5-0.0001)*rm_p3slmul*rm_p3slmul*rm_p3slmul + 0.0001; // slider response curve
    float t = dis.x;
    for( int i=0; i<rm_imax; i++  )
    {
        vec3 pos = ro + rd*t;
        float th = 0.0001*px*t; // delta_sdf_surface_hit
        float h = map(pos, data);
        if( t>dis.y || h<th ) break; // ray is outside boundingshape OR sdf_surface_hit.
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
    //p.xz = crot(p.xz,p.w*0.1);
    return p.xyz;
}

void main(void)
{
    // time
    float time = time;
    // camera
    float fle = 2.0;
    vec3 ro = transform(vec4(0,0,-cam_dist,time)).xyz;
    vec2 uv = (2.0*(gl_FragCoord.xy-0.5*resolution.xy))/resolution.y;
     
    // ray direction
    vec3 rd = normalize(transform(vec4(uv,fle,time)));
    // get ray distance to (intersection) hit point
    vec4 mat = vec4(0.0);
    float px = 2.0/( resolution.y*fle );
    float t = intersect( ro, rd, mat, px );

    // light
    const vec3 ld = 0.5*vec3(0.,-.5,-1.); // ligth direction
    const vec3 lc = vec3(0.4);// ligth color
    vec3 bg = vec3(0.8,0.9,1.0)*(0.6+0.4*rd.y);    // background-color

    // color
    vec3 col = vec3(0.6,0.4,0.7);

    if (t < 0.0){ // sky
        col = bg;
        col += 5.0*vec3(0.8,0.7,0.5)*pow( clamp(dot(rd,lc),0.0,1.0), 20.0 ); // sun
    }
    else{ // hit with object surface
        vec3 p = ro + rd * t;
        vec3 n = calcNormal( p, px );
        //vec2 mat_uv = vec2(mat.w, atan(mat.z, mat.y) ); //angle-u angle-v

        if(texture_ON){
            //texture_data
            vec2 z = mat.xy; float au = mat.z; float sr = mat.w; float ssr = sign(sr);

            // texture_coords
            float u = au/PI;
            float v = ssr*atan(z.y, z.x)/PI;

            // texture_color
            u -= j2_sh_pv1 * time;
            float col_h = 1.0; // h in [-0.5,0.0,+0.5] => [green_cyan,red,blue_cyan]
            //col_h *= 0.5*v;
            col_h *= 0.5*u;
            float col_s = 1.0;
            //col_s *= 0.9+0.1*ssr; // show polygon rotation sens in u-direction
            float col_v = 1.0;
            col_v *= .5+.5*fract(float(tex_u_subdiv)*1.0*(.5+.5*u));
            col_v *= .5+.5*fract(float(tex_v_subdiv)*2.0*(.5+.5*v));

            col = hsv2rgb(col_h,col_s,col_v);
        }
        else col = -n;

        if(shade_ON){
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
        }

        if(fog_ON){
            // fog
            col = mix( bg,col, exp( -0.025*t*t));
        }
    }
    // gamma
    col = sqrt(col);

    glFragColor = vec4(col,1.);
}
