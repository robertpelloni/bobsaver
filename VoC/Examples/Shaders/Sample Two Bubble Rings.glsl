#version 420

// original https://www.shadertoy.com/view/wlBfzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Patrik Colling - cyperus/2020 (https://www.youtube.com/user/cyperquantus)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//

#define AA

#define PI 3.14159265359
// Time modulation
#define PItime PI * time
#define sinTime02 sin(0.2*time)
#define sinTime03 sin(0.3*time)
#define sinTime05 sin(0.5*time)
#define sinTime07 sin(0.7*time)

// complex number transformations
vec2 mulz(vec2 za,vec2 zb){return za*mat2(zb.x,-zb.y,zb.yx);}    // z_out = za*zb
vec2 powqz(vec2 z, float q){float r = pow(length(z), q);        // z_out = z^q
 float a=q* atan(z.y,z.x); return vec2(r*cos(a),r*sin(a));}
vec2 tfrz(vec2 z,float t, float p, float a){                     // z_out = (z*e^ia)^p-t
    return powqz( mulz(z, vec2(cos(-a),sin(-a))),p) - vec2(t, 0.);}
// 3d transformations
// quaternion transformations

// came
mat3 camerabase(vec3 co, vec3 ct, vec3 cup){
    // co    : camera origin point in worldspace
    // cup    : camera up direction vector in worldspace
    // ct    : camera target point in worldspace
    vec3 cw = normalize(ct - co);        // camera ponting direction
    vec3 cu = normalize(cross(cup, cw));// camera left right
    vec3 cv = normalize(cross(cw, cu));    // camera down up
    return mat3(cu,cv,cw); // return camera orhtogonal basis as matrix
}

vec3 cameraraydirection(vec2 uv, mat3 cam, float f){
    // uv : Viewport coordinates
    // cam : camera orhtogonal basis
    // f : focal length zoom-in: abs(f)<1., zoom-out: abs(f)>1.
    return normalize(cam * vec3(f*uv,1.)); 
}

vec4 df(vec3 p) // MetaTorus transformation
{
    // scale + component swizzling: openGL => math coordinatesystem notation.
    p = 0.5 * p.zxy; //(z, x, y) => (x, y, z)
    ////fractal level 0: torus
    // 3D-space: cartesian3D => cylinder3D transformation
    float au = atan(p.y, p.x);  //float in [-PI, +PI]
    float rxy = length(p.xy)+0.05;    //float in [0., +inf]
    // 2D-space: complex plane := radial plane in cylinderc3d coordinates
    vec2 z = vec2(rxy, p.z);
    // 2Djulia :realaxis-translation, fraction == 2 => (torus,sphere,2spheres) 
    float shift0 = 1.4+1.5*(1.0+sinTime05); //shift0 in [-inf, +inf]
    z = tfrz(z, shift0, 2.0, 0.0);
    ////fractal level 1: 2Djulia realaxis-translation,fraction,rotation
    const float fracu1 = 2.0; // int in [1,2,3,..]
    const float fracv1 = 2.0; // int in [1,2,3,..]
    const float twist1 = 0.0; // int in [...,-1,0,+1,...]  
    float shift1 = 2.0 * sinTime02 + 0.5 * cos(fracu1 * (au + 0.01 * PItime));
    float torsion1 = au * twist1 / fracv1 - 0.25 * PItime;
    z = tfrz(z, shift1, fracv1,  torsion1);
    ////fractal level 2: 2Djulia realaxis-translation,fraction,rotation
    const float fracu2 = 7.0;
    const float fracv2 = 3.0;
    const float twist2 = 5.0;    
    float shift2 = 0.5 +1.4 * sinTime03 + 0.5 * cos( fracu2 * (au - 0.02 * PItime));
    float torsion2 = au * twist2 / fracv2 + 0.05 * PItime;
    z = tfrz(z, shift2, fracv2, torsion2);
    //
    float d = log(length(z)); // :( but it works!
    return vec4(d , z, au * fracu1 * fracu2);
}

vec3 nor( vec3 p, float prec )
{
    vec2 e = vec2( prec, 0. );
    vec3 n = vec3(
        df(p+e.xyy).x - df(p-e.xyy).x,
        df(p+e.yxy).x - df(p-e.yxy).x,
        df(p+e.yyx).x - df(p-e.yyx).x );
    return normalize(n);
}

// from iq code
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<1; i++ )
    {
        float h = df( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += h*.25;
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0., 1. );
}

// from iq code
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    // antialeasing
    for( int i=0; i<1; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = df( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

//--------------------------------------------------------------------------

// Grab all sky information for a given ray from camera
// from Dave Hoskins // https://www.shadertoy.com/view/Xsf3zX
vec3 GetSky(in vec3 rd, in vec3 sunDir, in vec3 sunCol)
{
    float sunAmount = max( dot( rd, sunDir), 0.0 );
    float v = pow(1.0-max(rd.y,0.0),6.);
    vec3  sky = mix(vec3(.1, .2, .3), vec3(.32, .32, .92), v);
    sky = sky + sunCol * sunAmount * sunAmount * .25;
    sky = sky + sunCol * min(pow(sunAmount, 800.0)*1.5, .3);
    return clamp(sky, 0.0, 1.0);
}

void main(void)
{  
        vec3 tot = vec3(0.0);
#ifdef AA
    vec2 rook[4];
    rook[0] = vec2( 1./8., 3./8.);
    rook[1] = vec2( 3./8.,-1./8.);
    rook[2] = vec2(-1./8.,-3./8.);
    rook[3] = vec2(-3./8., 1./8.);
    for( int n=0; n<4; ++n )
    {
    // pixel coordinates
    vec2 o = rook[n];
    vec2 uv = (-resolution.xy + 2.0*(gl_FragCoord.xy+o))/resolution.y;
#else //AA
     vec2 uv = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
#endif //AA
      
    // mouse
    vec2 m = vec2(0.0,1.0);//2.*vec2(mouse.x*resolution.xy.x/resolution.x-0.5,-1.*(mouse.y*resolution.xy.y/resolution.y-0.5)); // [-1.,+1.]
    
    // camera Viewport2Worldspace vec2 => vec3
    float aa = PI*m.x; // aa in [-PI,+PI]
    float ab = 0.49*PI*m.y; // ab in ]-PI/2,+PI/2[
    vec3 co = 5.*vec3( cos(ab)*sin(aa),sin(ab),cos(ab)*cos(aa)); // camera origine   

    const vec3 cup = vec3(0,1,0);    // camera up direction in Worldspace
    const vec3 ct = vec3(0,0,0);    // camera target point in Worldspace
    mat3 cam = camerabase(co,ct,cup);
    //cameradirection = cam[0];
    const float f = 1.3;
    vec3 rd =  cameraraydirection(uv,cam, f);
    
    float rayStep = 1.; // ray step length
    float rayDist = 0.; // ray distance length
    vec3 p = co + rd * rayDist; // point in 3D worldspace
    const float rayDistMax = 14.;         // maximal ray distance length
    const float rayiMax = 300.;         // maximal ray marching iterations
    const float rayF = 0.02;            // ray step multiplier
    for (float i=0.; i<rayiMax; i++){
        if (rayDist<0.0 || rayDist>rayDistMax) break;
        rayStep = df(p).x;
        rayDist += rayStep * rayF;
        p = co + rd *rayDist;    
    }
    
     
    const vec3 ld = vec3(0.,1.,.5); // ligth direction
    const vec3 lc = vec3(0.4); // ligth color
    vec3 col;
    vec3 sky = GetSky(rd, ld, lc);
    
    if (rayDist<rayDistMax)  // intersection with object
    {
        vec3 p = co + rd * rayDist;    // ViewSpace2Worldspace transformation     
        vec3 n = nor(p, 0.001);        // compute normale
        vec4 mat = df(p);
        // uv-coords
        vec2 mat_uv;
        mat_uv.x = atan(mat[2],mat[1])/PI;
        mat_uv.y = mat[3]/PI;
        // texture, color
        const float smoothness = 0.001; 
        col.rgb = vec3(smoothstep(-smoothness,smoothness,cos(PI*mat_uv.x)*cos(PI*mat_uv.y)));                             
        // iq lighting
        float occ = calcAO( p, n );
        float amb = clamp( 0.5+0.5*n.y, 0.0, 1.0 );
        float dif = clamp( dot( n, ld ), 0.0, 1.0 ) * (df(p+n*1.16).x);
        float spe = pow(clamp( dot( rd, ld ), 0.0, 1.0 ),16.0);
        float sss = df(p - n*0.001).x/0.01;
        // shading    
        dif *= softshadow( p, ld, 0.1, 1. );
        vec3 brdf = vec3(0.0);
        brdf += 0.5*dif*vec3(1.00,0.90,0.60);
        brdf += 0.5*spe*vec3(0.8,0.60,0.20)*dif;
        brdf += 0.3*amb*vec3(0.40,0.60,0.40)*occ;
        brdf += 0.4;
        col.rgb *= brdf;
        //
        col.rgb = mix( col.rgb, sky, 1.0-exp( -0.02*rayDist*rayDist ) ); 
    }
    else
    {//no intersection => background
        col.rgb = sky;
    }
    
    tot += col;
            
#ifdef AA
    }
    tot /= 4.;
#endif
    
    glFragColor = vec4( sqrt(0.4*tot), 1.0 );
}
