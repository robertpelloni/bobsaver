#version 420

// original https://www.shadertoy.com/view/MtlGDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by nick whitney - nwhit/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Uses Double Precision floats, so it should develop errors after zoom level ~42. 
// Seems to have the same issue with float precision as the Single P version, however.
// I don't know if this is because of WebGL or Nvidia cards or something else.

// I would use a ds_div function instead of the (1. / var), but the ds_div function causes
// an error but no error messages show up.

// Attemping to stop NVidia cards from reverting to singleP
#pragma optionNV(fastmath off)
#pragma optionNV(fastprecision off)

/////////////////////////////////
// Zoom Centers
/////////////////////////////////
const vec2 fillErUp = vec2(0.3585614710926859372,
                           0.3229491840959411351);

const vec2 sunflowers = vec2(-1.985540371654130485531439267191269851811165434636382820704394766801377,
                             0.000000000000000000000000000001565120217211466101983496092509512479178);

const vec2 sunflowersX = vec2(-1.9855403900146484375,
                              0.000000018360517951968560732808730148188834565363617179);

const vec2 sunflowersY = vec2(0.000000000000000000000000000001565120228882564491389030362389781052341234098969,
                              0.);
#define FILLERUP
//#define SUNFLOWERS

/////////////////////////////////
// General Constants
/////////////////////////////////
const int maxIterations = 4000;
const float zoomSpeed = .35;
const float radius = 20.;

/////////////////////////////////
// Emulation based on Fortran-90 double-single package. See http://crd.lbl.gov/~dhbailey/mpdist/

// Add: res = ds_add(a, b) => res = a + b
vec2 ds_add(vec2 dsa, vec2 dsb)
{
    vec2 dsc;
    float t1, t2, e;

    t1 = dsa.x + dsb.x;
    e = t1 - dsa.x;
    t2 = ((dsb.x - e) + (dsa.x - (t1 - e))) + dsa.y + dsb.y;

    dsc.x = t1 + t2;
    dsc.y = t2 - (dsc.x - t1);
    return dsc;
}

// Subtract: res = ds_sub(a, b) => res = a - b
vec2 ds_sub(vec2 dsa, vec2 dsb)
{
    vec2 dsc;
    float e, t1, t2;

    t1 = dsa.x - dsb.x;
    e = t1 - dsa.x;
    t2 = ((-dsb.x - e) + (dsa.x - (t1 - e))) + dsa.y - dsb.y;

    dsc.x = t1 + t2;
    dsc.y = t2 - (dsc.x - t1);
    return dsc;
}

// Compare: res = -1 if a < b
//              = 0 if a == b
//              = 1 if a > b
float ds_compare(vec2 dsa, vec2 dsb)
{
    if (dsa.x < dsb.x) return -1.;
    else if (dsa.x == dsb.x) 
    {
        if (dsa.y < dsb.y) return -1.;
        else if (dsa.y == dsb.y) return 0.;
        else return 1.;
    }
    else return 1.;
}

// Multiply: res = ds_mul(a, b) => res = a * b
vec2 ds_mul(vec2 dsa, vec2 dsb)
{
    vec2 dsc;
    float c11, c21, c2, e, t1, t2;
    float a1, a2, b1, b2, cona, conb, split = 8193.;

    cona = dsa.x * split;
    conb = dsb.x * split;
    a1 = cona - (cona - dsa.x);
    b1 = conb - (conb - dsb.x);
    a2 = dsa.x - a1;
    b2 = dsb.x - b1;

    c11 = dsa.x * dsb.x;
    c21 = a2 * b2 + (a2 * b1 + (a1 * b2 + (a1 * b1 - c11)));

    c2 = dsa.x * dsb.y + dsa.y * dsb.x;

    t1 = c11 + c2;
    e = t1 - c11;
    t2 = dsa.y * dsb.y + ((c2 - e) + (c11 - (t1 - e))) + c21;

    dsc.x = t1 + t2;
    dsc.y = t2 - (dsc.x - t1);

    return dsc;
}

// create double-single number from float
vec2 ds_set(float a)
{
    vec2 z;
    z.x = a;
    z.y = 0.0;
    return z;
}

// End Double-Single Emulation Section
//////////////////////////////////////

//////////////////////////////////////
// Begin Main Section
//////////////////////////////////////
// Calculate and return the iteration depth for the current pixel
float ds_Mandelbrot(vec2 px, vec2 py, vec2 cx1, vec2 cy1, float zoom)
{       
    //calculate the initial real and imaginary part of z, based on the pixel location and zoom and position values        
    vec2 ds_invZoom = ds_set(1. / zoom);
    
    vec2 cx = ds_add(ds_mul(px, ds_invZoom), cx1);
    vec2 cy = ds_add(ds_mul(py, ds_invZoom), cy1);
    
    vec2 zx = cx;
    vec2 zy = cy;
    
    vec2 ds_two = ds_set(2.);
    
    vec2 ds_radius = ds_set(radius * radius);
      
    //start the iteration process
    for(int i = 0; i < maxIterations; i++)
    {     
        vec2 oldzx = zx;
        zx = ds_add(ds_sub(ds_mul(zx, zx), ds_mul(zy, zy)), cx);
        zy = ds_add(ds_mul(ds_two, ds_mul(oldzx, zy)), cy);
        
        if(ds_compare(ds_add(ds_mul(zx, zx), ds_mul(zy, zy)), ds_radius) > 0.) 
        {
            //float modulus = sqrt(z.x*z.x + z.y*z.y);
            
            //return(float(i) + 1. - log(log(modulus)) / log(2.));
            return float(i);
        }
    }    
    
    return 0.;
}

// generates a color based on the iteration depth
vec3 stepColor(float iter)
{   
    //vec3 color = vec3(mod(iter, 255.), sin(iter), cos(iter));
    
    vec3 color = vec3((-cos(0.025*float(iter))+1.0)/2.0,
                      (-cos(0.08*float(iter))+1.0)/2.0,
                      (-cos(0.12*float(iter))+1.0)/2.0);
    
    return color;
}

void main(void)
{    
    vec2 one = ds_set(1.0);
    vec2 two = ds_set(2.0);
    
    //vec2 p = 2.0 * gl_FragCoord.xy / resolution - 1.;

    vec2 p = gl_FragCoord.xy / resolution.xy;
        
    vec2 px = ds_sub(ds_mul(two, ds_set(p.x)), one);
    vec2 py = ds_sub(ds_mul(two, ds_set(p.y)), one);
    
    float ratio = resolution.x/resolution.y;
    vec2 ds_ratio = ds_set(ratio);
    
    px = ds_mul(px, ds_ratio);

    // animation    
    float zoom = pow( 0.5, -zoomSpeed * mod(time, 30. / zoomSpeed) );
    
    vec2 invRes = vec2(1.0) / resolution.xy;
    vec2 iResX = ds_set(resolution.x);
    vec2 iResY = ds_set(resolution.y);
    
    #ifdef FILLERUP
    vec2 cx = ds_set(fillErUp.x);
    vec2 cy = ds_set(fillErUp.y);
    #else
    vec2 cx = sunflowersX;
    vec2 cy = sunflowersY;
    #endif
    
    float iter = float(ds_Mandelbrot(px, py, cx, cy, zoom));
    
    vec3 col = stepColor(iter);
    
       glFragColor = vec4( col, 1.0 );
}
