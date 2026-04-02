#version 420

// original https://www.shadertoy.com/view/wl3SWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Patrik Colling - cyperus/2020 (https://www.youtube.com/user/cyperquantus)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// links : https://www.shadertoy.com/view/3stSR8 Stephane Cuillerdier - Aiekick/2019 (twitter:@aiekick)
// doc     : http://www.iquilezles.org/index.html Inigo Quilez - iq

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

vec4 df(vec3 p) // MetaTorus transformation
{   
    // scale + component swizzling: openGL => math coordinatesystem notation.
    p = 0.5 * p.zxy; //(z, x, y) => (x, y, z)
    ////fractal level 0: torus
    // 3D-space: cartesian3D => cylinder3D transformation
    float au  = atan(p.y, p.x); //float in [-PI, +PI]
    float rxy = length(p.xy);    //float in [0., +inf]
    // 2D-space: complex plane := radial plane in cylinderc3d coordinates
    float av = atan(rxy, p.z);    //float in [-PI, +PI]
    float r =length(p);            //float in [0., +inf]
    vec2 z = r * vec2(cos(av), sin(av));
    // 2Djulia :realaxis-translation, fraction == 2 => (torus,sphere,2spheres) 
    float shift0 = -2.0-3.0*sinTime05; //shift0 in [-inf, +inf]
    z = tfrz(z, shift0, 2.0, 0.0);
    //z = mulz(z,z);
    ////fractal level 1: 2Djulia realaxis-translation,fraction,rotation
    #if 1
    const float fracu1 = 2.0; // int in [1,2,3,..]
    const float fracv1 = 3.0; // int in [1,2,3,..]
    const float twist1 = 2.0; // int in [...,-1,0,+1,...]  
    float shift1 = 1.0 * sinTime02 + 0.5 * cos(fracu1 * (au + 0.01 * PItime));
    float torsion1 = au * twist1 / fracv1 - 0.25 * PItime;
    z = tfrz(z, shift1, fracv1,  torsion1);
    au *=  fracu1;
    #endif
    ////fractal level 2: 2Djulia realaxis-translation,fraction,rotation
    #if 1 
    const float fracu2 = 3.0;
    const float fracv2 = 2.0;
    const float twist2 = 5.0;    
    float shift2 = 0.5 +1.4 * sinTime03 + 0.5 * cos( fracu2 * (au - 0.02 * PItime));
    float torsion2 = au * twist2 / fracv2 + 0.1 * PItime;
    z = tfrz(z, shift2, fracv2, torsion2);
    au *=  fracu2;
    #endif
    ////fractal level 3:  2Djulia realaxis-translation,fraction,rotation
    ///
    float d = log(length(z));
    return vec4(d , z, au);
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
    glFragColor = vec4(1.0);                     // init pixel color white
    vec2 g = gl_FragCoord.xy;                    // g.x, g.y in [0., 1. ]
    vec2 si = resolution.xy;                // pixel count in x and y direction
    
    vec2 uv = (2.*g-si)/min(si.x, si.y);    // u in [-1., 1.] or v in [-1., 1.]
    
    const float a = 0.0;//PI/2.0;
    // https://www.reddit.com/r/twotriangles/comments/1hy5qy/tutorial_1_writing_a_simple_distance_field/
    vec3 rayOrg = vec3(cos(a),1.5,sin(a)) * 5.;     // ray origin in worldspace
    vec3 camUp = vec3(0,1,0);                        // camera up direction Y-axis
    vec3 camOrg = vec3(0,-1.5,0); // orientation-camera XY-screen (-1. * vec3(origin-target)) in worldspace
    
    const float fov = .5; // focal length
    vec3 axisZ = normalize(camOrg - rayOrg);     //sensor +Zaxis (orientation behind camera sensor to rayorigine) 
    vec3 axisX = normalize(cross(camUp, axisZ)); //sensor +Xaxis
    vec3 axisY = normalize(cross(axisZ, axisX)); //sensor +Yaxis
    vec3 rayDir = normalize(axisZ + fov * uv.x * axisX + fov * uv.y * axisY); // ViewSpace2WorldSpace-transformation
    
    float rayStep = 1.; // ray step length
    float rayDist = 0.; // ray distance length
    vec3 p = rayOrg + rayDir * rayDist; // point in 3D worldspace
    const float rayDistMax = 20.;         // maximal ray distance length
    const float rayiMax = 300.;         // maximal ray marching iterations
    const float rayF = 0.03;            // ray step multiplier
    for (float i=0.; i<rayiMax; i++) //(upper bound condition): maximal ray marching iterations.
    {// if (lower boundery condition): intersection with object surface
     //     OR (upper boundery condition): ray distance length to big. => got ray distance.
        if (log(rayDist*rayDist/rayStep/1e6)>0. || rayDist>rayDistMax) break;
        rayStep = df(p).x;
        rayDist += rayStep * rayF;
        p = rayOrg + rayDir *rayDist;    
    }
    
    const vec3 ld = vec3(0.,1.,.5); // ligth direction
    const vec3 lc = vec3(1.5,1.5,1.5); // ligth color
    
    vec3 sky = GetSky(rayDir, ld, lc);
    
    if (rayDist<rayDistMax)  // intersection with object
    {
        vec3 p = rayOrg + rayDir * rayDist;    // ViewSpace2Worldspace transformation     
        vec3 n = nor(p, 0.001);                // compute normale
        vec4 mat = df(p);
        // uv-coords
        vec2 mat_uv;
        mat_uv.x = atan(mat[2],mat[1])/PI;
        mat_uv.y = mat[3]/PI;
        // texture, color
        glFragColor.rgb = vec3(0.2+0.5*smoothstep(-0.01,0.01,cos(PI*mat_uv.x)*cos(PI*mat_uv.y)));                             
        // iq lighting
        float occ = calcAO( p, n );
        float amb = clamp( 0.5+0.5*n.y, 0.0, 1.0 );
        float dif = clamp( dot( n, ld ), 0.0, 1.0 ) * (df(p+n*1.0).x);
        float spe = pow(clamp( dot( rayDir, ld ), 0.0, 1.0 ),1.0);
        float sss = df(p - n*0.001).x/0.01;
        // shading    
        dif *= softshadow( p, ld, 0.1, 10. );
        vec3 brdf = vec3(0.0);
        brdf += 1.00*dif*vec3(1.00,0.90,0.60);
        brdf += 1.00*spe*vec3(1.00,0.90,0.60)*dif;
        brdf += 0.30*amb*vec3(0.50,0.70,0.50)*occ;
        brdf += 0.4;
        glFragColor.rgb *= brdf;
        //
        glFragColor.rgb = mix( glFragColor.rgb, sky, 1.0-exp( -0.02*rayDist*rayDist ) ); 
    }
    else
    {//no intersection => background
        glFragColor.rgb = sky;
    }
    
    glFragColor.rgb *= 0.45;
}
