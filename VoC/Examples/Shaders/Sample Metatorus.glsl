#version 420

// original https://www.shadertoy.com/view/Wt3XWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Patrik Colling - cyperus/2020 (https://www.youtube.com/user/cyperquantus)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// links : https://www.shadertoy.com/view/3stSR8 Stephane Cuillerdier - Aiekick/2019 (twitter:@aiekick)
// doc     : http://www.iquilezles.org/index.html Inigo Quilez - iq
#define PI 3.14159265359
#define E  2.71828182845 //exists as y=exp(1.) 
const vec3 ld = vec3(0.,1.,.5); // ligth direction
// complex number transformations
vec2 mulz(vec2 a,vec2 b){return a*mat2(b.x,-b.y,b.yx);}                            // za*zb
vec2 powqz(vec2 c, float q){float r = pow(length(c), q);                        // z^q
 float a=q* atan(c.y,c.x); return vec2(r*cos(a),r*sin(a));}
vec2 tfrz(vec2 c,float t, float f, float r){     // realaxis-translation,fraction,rotation
return powqz( mulz(c, vec2(cos(-r),sin(-r))),f) - vec2(t, 0.);}

vec4 df(vec3 p) // MetaTorus transformation
{   
    // Time modulation
    float sinTime02 =  sin(0.2*time);
    float sinTime03 =  sin(0.3*time);
    float sinTime05 =  sin(0.5*time);
    //float sinTime07 =  sin(0.7*time);
    // scale + component swizzling: openGL => math coordinatesystem notation.
    p = 0.5 * p.zxy; //(z, x, y) => (x, y, z)
    // 3D-space: cartesian3D => cylinder3D transformation
    float au = atan(p.y, p.x);//au in [-PI, +PI]
    float rxy = length(p.xy);    //rxy in [0., +inf]
    // 2D-space: complex plane := radial plane in cylinderc3d coordinates
    float av = atan(rxy, p.z);    //av      in [-PI, +PI]
    float r =length(p);            //r   in [0., +inf]
    vec2 z = r * vec2(cos(av), sin(av));
    float shift = -2.0*(1.0+sinTime05)-1.4;
    z = tfrz(z, shift, 2.0, 0.0);

    //realaxis-translation,fraction,rotation
    float shift0 = 2.0 * sinTime02 + 0.5 * cos(3.0 * (au + 0.01 * PI * time));
    float frac0 = 3.0;
    float cicl0 = 2.0;
    float twist0 = au * cicl0 / frac0 - 0.5*PI* 0.5 * time;
    z = tfrz(z, shift0, frac0, twist0);
    //realaxis-translation,fraction,rotation
    float shift1 = 0.5 +1.0 * sinTime03 + 0.5 * cos(6.0 * (au - 0.02 * PI * time));
    float frac1 = 2.0;
    float cicl1 = 2.0;
    float twist1 = au * cicl1 / frac1 + 0.5*PI* 1.0 * time;
    z = tfrz(z, shift1, frac1, twist1);
    float d = log(length(z));
    return vec4(d - 0.0, z, 0);
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
    vec3  sky = mix(vec3(.1, .2, .3), vec3(.32, .32, .32), v);
    sky = sky + sunCol * sunAmount * sunAmount * .25;
    sky = sky + sunCol * min(pow(sunAmount, 800.0)*1.5, .3);
    return clamp(sky, 0.0, 1.0);
}

void main(void)
{  
    glFragColor = vec4(1);                     // init pixel for multiplication
    
    vec2 g = gl_FragCoord.xy;                // g.x, g.y in [0., 1. ]
    vec2 si = resolution.xy;                // pixel count in x and y direction
    vec2 uv = (2.*g-si)/min(si.x, si.y);    // u in [-1., 1.] or v in [-1., 1.]
    
    float a = 0.0;//PI/2.0;
    // https://www.reddit.com/r/twotriangles/comments/1hy5qy/tutorial_1_writing_a_simple_distance_field/
    vec3 rayOrg = vec3(cos(a),1.5,sin(a)) * 5.;     // ray origin in worldspace
    vec3 camUp = vec3(0,1,0);                        // camera up direction Y-axis
    vec3 camOrg = vec3(0,-1.5,0); // orientation-camera XY-screen (-1. * vec3(origin-target)) in worldspace
    
    float fov = .5; // focal length
    vec3 axisZ = normalize(camOrg - rayOrg);     //sensor +Zaxis (orientation behind camera sensor to rayorigine) 
    vec3 axisX = normalize(cross(camUp, axisZ)); //sensor +Xaxis
    vec3 axisY = normalize(cross(axisZ, axisX)); //sensor +Yaxis
    vec3 rayDir = normalize(axisZ + fov * uv.x * axisX + fov * uv.y * axisY); // ViewSpace2WorldSpace-transformation
    
    float s = 1.; // max-spherical-ray-step-length-to-object from distancefieldfunction
    float d = 0.; // ray distance length
    vec3 p = rayOrg + rayDir * d;
    float dMax = 20.; // maximal ray distance length
    float sMin = 0.01;
    float count = 0.; // number of steps ray marching
    for (float i=0.; i<300.; i++) //(upper bound condition): maximal ray marching steps.
    {// if (lower boundery condition):intersection with object
     //      :ray-step-length-to-object in relation to absolute ray distance is smale enough.
     //     OR (upper boundery condition): ray-distance-length to big. => got ray distance.
        if (log(d*d/s/1e6)>0. || d>dMax) break;
        s = df(p).x;
        d += s * 0.04;
        p = rayOrg + rayDir * d;    
    }
    
    vec3 sky = GetSky(rayDir, ld, vec3(1.5));
    
    if (d<dMax) 
    { // intersection with object
         vec3 p = rayOrg + rayDir * d;  // ViewSpace2Worldspace transformation     
        vec3 n = nor(p, 0.001);        // compute normale
        vec4 mat = df(p);
        // iq lighting
        float occ = calcAO( p, n );
        float amb = clamp( 0.5+0.5*n.y, 0.0, 1.0 );
        float dif = clamp( dot( n, ld ), 0.0, 1.0 ) * (df(p+n*1.16).x);
        float spe = pow(clamp( dot( rayDir, ld ), 0.0, 1.0 ),16.0);
        float sss = df(p - n*0.001).x/0.01;
        //shading    
        dif *= softshadow( p, ld, 0.1, 10. );
        vec3 brdf = vec3(0.0);
        brdf += 1.20*dif*vec3(1.00,0.90,0.60);
        brdf += 1.20*spe*vec3(1.00,0.90,0.60)*dif;
        brdf += 0.30*amb*vec3(0.50,0.70,0.50)*occ;
        brdf += 0.02;
        glFragColor.rgb *= brdf;

        glFragColor.rgb = mix( glFragColor.rgb, sky, 1.0-exp( -0.02*d*d ) ); 
    }
    else
    {//no intersection => background
        glFragColor.rgb = sky;
    }
    
    glFragColor.rgb = sqrt(glFragColor.rgb * glFragColor.rgb * 0.1);
}
