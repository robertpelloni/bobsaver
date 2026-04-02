#version 420

// original https://www.shadertoy.com/view/4dfyDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on https://www.shadertoy.com/view/ltfSWn
// created by inigo quilez - iq
// (see http://iquilezles.org/www/articles/mandelbulb/mandelbulb.htm for details)
//
// and the blog entry "Distance Estimated 3D Fractals (V): The Mandelbulb & Different
// DE Approximations" by Mikael Hvidtfeldt Christensen
// (see http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/)
//
//
// Code for 4x rotated-grid SSAA for antialiasing taken from
// https://www.shadertoy.com/view/XsXXWS by Morgan Mc Guire (Morgan3D)
//
// (take also a look at the excellent documented source code if you need a very good and very detailed
// explanation of how to render mandelbulbs!)
//
//
// For an explanation of how to archieve realistic looking outdoor lighting take a look at
// another excellent article of iq:
//
// http://iquilezles.org/www/articles/outdoorslighting/outdoorslighting.htm
//
// and for raymarching in general, of course, the classic article "rendering worlds with two triangles"
// also by iq:
//
// http://iquilezles.org/www/material/nvscene2008/nvscene2008.htm
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Thanks to iq for the great tutorials, for shadertoy and everything else

// set to true for antialiasing (enhances rendering quality but decreases speed by a factor of 4!)
#define ANTIALIASING false

// globals (are bad, i know, but make life sometimes easier :-) )
float dr;

//Fractal
const int   NUM_ITERATIONS  = 5;
const float SCALE           = 3.0; 
      vec3  OFFSET          = vec3(1.0, 1.0, 1.0);
      mat3  m               = mat3(1,0,0,0,1,0,0,0,1);//Initialized in main function

// background color function, computes skycolor based on ray direction (used, if the ray hits nothing)
vec3 skyColor(vec3 rd)
{
    vec3 sunDir = vec3(0.0, -1.0, 0.0);
    vec3 sunColor = vec3(1.6, 1.8, 2.2);

    float sunAmount = max(dot(rd, sunDir), 0.0);
    float v = pow(1.0 - max(rd.y, 0.0), 6.0);
    vec3 sky = mix(vec3(0.1, 0.2, 0.3), vec3(0.32, 0.32, 0.32), v);

    sky += sunColor * sunAmount * sunAmount * 0.25 + sunColor * min(pow(sunAmount, 800.0) * 1.5, 0.3);

    return clamp(sky, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
}

// signed distance field function (mandelbulb power 8)
float map(vec3 p)
{
    const int itMax = 14;

    vec3 w = p;

    float r = 0.0;
    float dist = 0.0;

    dr = 1.0;

    for(int it = 0; it < itMax; it++)
    {
        r = length(w);

        if (r > 2.0)
        {
            dist = 0.5 * log(r) * r / dr;

            break;
        }

        // extract polar coordinates
        float theta = acos(w.z / r);
        float phi =  atan(w.y, w.x);

        // scale and rotate point
        float rp2 = w.x * w.x + w.y * w.y + w.z * w.z;
        float rp4 = rp2 * rp2;

        float radPower = rp4 * rp4;
        float phiPower = phi * 8.0;
        float thetaPower = theta * 8.0;

        // convert back to cartesian coordinates
        float sinTheta = sin(thetaPower);
        float sinPhi   = sin(phiPower);
        float cosTheta = cos(thetaPower);
        float cosPhi   = cos(phiPower);

        w.x = radPower * sinTheta * cosPhi;
        w.y = radPower * sinTheta * sinPhi;
        w.z = radPower * cosTheta;

        // add c
        w += p;

        // compute dr
        float r2 = r * r;
        float r4 = r2 * r2;
        dr *= r4 * r2 * r * 8.0 + 1.0;
    }

    return dist;
}

// raymarching with distance field
float intersect( in vec3 ro, in vec3 rd)
{
    const int maxStepCount = 256;    // maximum no. of steps to march
    const float tMax = 100.0;        // maximum distance to march
    const float epsilon = 0.0003;    // determines precision (smaller values for more details
                                    // and more noise due to holes from precision problems)

    float t = 0.0;

    // march!
    for(int i = 0; i < maxStepCount; i++)
    {
        // march forward along the ray, compute point p on ray for this step
        vec3 p = ro + rd * t;

        // get distance to nearest surface from distance field
        float distance = map(p);

        // if we're already marched too far (t > tMax),
        // or we're close enough (less than epsilon) to the surface (we have "hit" it)
        if ((t > tMax) || (distance < epsilon))
            break;

        // march further along the ray with the maximal distance possible,
        // which is distance to the closest surface from the actual position
        // taken from the signed distance field describing the mandelbulb
        // this ensures, that we haven't gone too far, so that we are not already inside the mandelbulb
        t += distance;
    }

    // if we're not exceeded the maximum marching distance, return ray parameter t for
    // computating the hit surface position
    if( t < tMax )
           return t;
    else
        return -1.0;    // we missed it, signal this with -1.0
}

// cheap distance field soft shadow computation
// (see iq article "free penumbra shadows for raymarching distance fields":
// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm)
float softShadow(vec3 surfacePoint, vec3 lightDir)
{
    vec3 origin = surfacePoint + 0.001 * lightDir;

    vec3 ro = origin;
    vec3 rd = lightDir;

    const float k = 2.0; // 8.0
    float res = 1.0;
    float t = 0.0;

    for (int i = 0; i < 100; i++)
    {
        float h = map(ro + rd * t);

        if (h < 0.0001)
            return 0.0;

        if (t > 100.0)
            break;

        res = min(res, k * h / t);
        t += h;
    }

    return res;
}

// numerically approximate normal via discrete gradient computation (first order)
vec3 computeNormal(vec3 surfacePoint)
{
    const float epsilon =  0.001;

    vec3 epsX = vec3(epsilon, 0.0, 0.0);
    vec3 epsY = vec3(0.0, epsilon, 0.0);
    vec3 epsZ = vec3(0.0, 0.0, epsilon);

    float dx = map(surfacePoint + epsX) - map(surfacePoint - epsX);
    float dy = map(surfacePoint + epsY) - map(surfacePoint - epsY);
    float dz = map(surfacePoint + epsZ) - map(surfacePoint - epsZ);

    vec3 n = normalize(vec3(dx, dy, dz));

    return n;
}

// cheap distance field ambient occlusion computation
// (see iq article: "rendering worlds with two triangles)
float computeAO(vec3 surfacePoint, vec3 normal)
{
    const float k = 5.0;
    const float delta = 0.005;

    float sum = 0.0;

    for(float i = 0.0; i < 10.0; i+=1.0)
    {
        float factor = 1.0 / pow(2.0, i);
        vec3 samplePoint = surfacePoint + normal * i * delta;

        sum += factor * (i * delta - map(samplePoint));
    }

    return 1.0 - k * sum;
}

// compute fragment color by raymarching the whole scene, given 2D coords
vec3 raymarch(vec2 point)
{
    // scene parameters
    const vec3 cameraLookAt = vec3(0.0, 0.1, 0.0);

    const vec3 light1 = vec3(  0.577, 0.577, -0.577 );
    const vec3 light2 = vec3( -0.707, 0.000,  0.707 );

    const float fov = 1.2;    // change for bigger field of view

    // compute aspect ratio 'corrected' pixel position
    float aspectRatio = resolution.x / resolution.y;
    vec2 xy = -1.0 + 2.0 * point.xy / resolution.xy;

    vec2 s = xy * vec2(aspectRatio, 1.0);

    // slow down time ...
    float time = time * 0.5;

    // some iq magic for camera movement ...  (time dependent camera radius and rotations)
    float r = 2.3 + 0.1  * cos(0.29 * time);
    vec3  ro = vec3( r * cos(0.33 * time), 0.8 * r * sin(0.37 * time), r * sin(0.31 * time) ); // ray origin
    float cr = 0.5 * cos(0.1 * time);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);

    // compute orthonormal camera basis
    vec3 cameraDir = normalize(cameraLookAt - ro);
    vec3 cameraRight = normalize(cross(cameraDir, cp));
    vec3 cameraUp = normalize(cross(cameraRight, cameraDir));

    // compute ray direction for perspective camera
    vec3 rd = normalize( s.x  * cameraUp + s.y * cameraRight + fov * cameraDir );

    vec3 col;
    vec3 tra;

    // intersect ray (ray origin (ro), ray direction (rd) with scene,
    // get ray parameter t for determining hit surface point
    float t = intersect(ro, rd);
        
        
    // nothing hit -> background color based on ray direction
    if( t < 0.0 )
        col = skyColor(rd);
    else
    {
        // hit at t, compute position, normal, reflection, usw. (see links above)
        vec3 pos = ro + t * rd;
        vec3 nor = computeNormal(pos);
        vec3 hal = normalize( light1 - rd);
        vec3 ref = reflect( rd, nor );

        // for using resoluts of orbit traps for color
        float trc = 0.1 * log(dr);

        // position based color for 'colorful' coloration :-)
        tra = vec3(trc, trc, 0) * abs(pos);

        col = vec3(0.7, 0.2, 0.2);
        col = mix( col, vec3(1.0, 0.5, 0.2), sqrt(tra.y) );
        col = mix( col, vec3(1.0, 1.0, 1.0), tra.x );

        // compute diffuse components from both lights
        float dif1 = clamp( dot( light1, nor ), 0.0, 1.0 );
        float dif2 = clamp( 0.5 + 0.5*dot( light2, nor ), 0.0, 1.0 );

        // add other lighting components (ambient occlusion, softshadows, specular)
        // see iq article (http://iquilezles.org/www/articles/outdoorslighting/outdoorslighting.htm)
        float occ =  0.05 * computeAO(pos, nor);
        float sha = softShadow(pos, light1);
        float fre = 0.04 + 0.96 * pow( clamp(1.0 - dot(-rd, nor), 0.0, 1.0), 5.0 );
        float spe = pow( clamp(dot(nor, hal),0.0, 1.0), 12.0 ) * dif1 * fre * 8.0;

        // iq color magic at it's best (unbelievable!)
        // 'good artists copy, great artists steal' - this is stolen from the incredible iq!
        // a complete rip off, for the original see: https://www.shadertoy.com/view/ltfSWn
        vec3 lin  = 1.5 * vec3(0.15, 0.20, 0.23) * (0.7 + 0.3 * nor.y) * (0.2 + 0.8 * occ);
             lin += 3.5 * vec3(1.00, 0.90, 0.60) * dif1 * sha;
             lin += 4.1 * vec3(0.14, 0.14, 0.14) * dif2 * occ;
             lin += 2.0 * vec3(1.00, 1.00, 1.00) * spe * sha * occ;
             lin += 2.0 * vec3(0.20, 0.30, 0.40) * (0.02 + 0.98 * occ);
             lin += 2.0 * vec3(0.8, 0.9, 1.0) * smoothstep( 0.0, 1.0, ref.y ) * occ;

        col *= lin;
        col += spe * 1.0 * occ * sha;
    }

    // cheap gamma correction (for gamma = 1.0 / 2.0, close to 'official' lcd screen gamma = 1.0 / 2.2)
    col = sqrt( col );

    return col;
}

void main(void)
{
    vec3 color;

    if(!ANTIALIASING)
        // single sample for speed
        color = raymarch(gl_FragCoord.xy);
    else
        // 4x rotated-grid SSAA for antialiasing
        // (taken from https://www.shadertoy.com/view/XsXXWS by Morgan3D)
        color =   (    raymarch(gl_FragCoord.xy + vec2(-0.125, -0.375)) +
                     raymarch(gl_FragCoord.xy + vec2(+0.375, -0.125)) +
                    raymarch(gl_FragCoord.xy + vec2(+0.125, +0.375)) +
                     raymarch(gl_FragCoord.xy + vec2(-0.375, +0.125))    ) / 4.0;

    glFragColor = vec4( color, 1.0 );
}
