#version 420

// original https://www.shadertoy.com/view/ts3BWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This shader use 
//
// https://iquilezles.org/www/articles/bandlimiting/bandlimiting.htm
//
// Box-filtering of cos(x):
//
// (1/w)∫cos(t)dt with t ∈ (x-½w, x+½w)
// = [sin(x+½w) - sin(x-½w)]/w
// = cos(x)·sin(½w)/(½w)
//
// More example here made by Inigo Quilez:
//   https://www.shadertoy.com/view/WtScDt
//   https://www.shadertoy.com/view/wtXfRH
//   https://www.shadertoy.com/view/3tScWd
//
//________________________________________
//
// This shader show how to extract normal from a sum of cosine functions of different phase and frequence,
// and how to filter analytic normals to remove aliasing in order to do better lighting effect.  
//
// You can use your mouse to select which part of the canvas you want to see.
// You can also modify the filtering coefficient FILTERING_COEF, to modify the intensity of filtering.
// DEFORM can be set to 0, 1 or 2 to change the visuals.
//
// Top left     : Shaded surface with analytic normal from non filtered cosinus functions.
// Top right     : Shaded surface with analytic normal from filtered cosinus functions. 
// Bottom left     : Aliased surface generated with cosinus functions.
// Bottom right : Anti-aliased surface generated with filtered cosinus functions.
//
// Related Shader:
//  https://www.shadertoy.com/view/Wd3fDn
//  https://www.shadertoy.com/view/ts3BWn
//

// 0, 1 or 2
#define DEFORM 1

// Filtering coefficient.
// Define the box filtering size. 
#define FILTERING_COEF 1.

// https://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec2 deform( in vec2 p )
{
    // deform 1
    #if DEFORM >= 1
    p *= 0.25;
    p = 0.5*p/dot(p,p);
    p.x += time*0.1;
    
    
    // deform 2
    #if DEFORM >= 2
    p += 0.1*cos( 1.5*p.yx + 0.003*1.0*time + vec2(0.1,1.1) );
    p += 0.1*cos( 2.4*p.yx + 0.003*1.6*time + vec2(4.5,2.6) );
    p += 0.1*cos( 3.3*p.yx + 0.003*1.2*time + vec2(3.2,3.4) );
    p += 0.1*cos( 4.2*p.yx + 0.003*1.7*time + vec2(1.8,5.2) );
    p += 0.1*cos( 9.1*p.yx + 0.003*1.1*time + vec2(6.3,3.9) );
    #endif
    #endif
    return p;
}

////////////////////////////////////////////////////////////
// derivative of cos(u)
//
// cos(u) = cos(f*t+o)
// cos'(u) = -f*sin(f*t+o)
float dcos( float u,float f)
{
    return -f*sin(u);
}

/////////////////////////////////////////////////////////////
// box-filted cos(x)
float fcos( float u )
{
    float w = fwidth(u);
    return cos(u) * sin(FILTERING_COEF*w)/(FILTERING_COEF*w);
}

//////////////////////////////////////////////////////////////
// derivative of fcos(x)
//
// cos(u)*sin(c*w(u))/(c*w(u)) = cos(f*t+o)*sin(c*w(f*t+o))/(c*w(f*t+o))
//
// (cos(u)*sin(c*w(u))/(c*w(u)))' =
//
//    ( -f * sin(u) * sin(c*w(u)) + cos(u) * c * w'(u) * cos(c*w(u)) ) * c * w(u) - cos(u) * sin(c * w(u)) * c * w'(u)
//    ________________________________________________________________________________________________________________
//                                                    (c * w(u))^2
//
//
// w'(u) assumed to be fwidth(w(u)).
// c is the filtering coefficient.
float dfcos( float u, float f)
{
    float w = fwidth(u);
    float dw = fwidth(w);
    
    return ( (-f * sin(u) * sin(FILTERING_COEF*w) + cos(u) * FILTERING_COEF * dw * cos(FILTERING_COEF * w) ) * (FILTERING_COEF*w) - cos(u) * sin(FILTERING_COEF * w) * (FILTERING_COEF*dw) )/ pow(FILTERING_COEF*w,2.);
}

float getIntensityFiltered( in float t )
{
    float col = 0.4;
    col += 0.14*fcos(t*  1.0+0.6);
    col += 0.13*fcos(t*  3.1+1.0);
    col += 0.12*fcos(t*  5.1+1.1);
    col += 0.11*fcos(t*  9.1+1.2);
    col += 0.10*fcos(t* 17.1+0.9);
    col += 0.09*fcos(t* 31. +11.3);
    col += 0.08*fcos(t* 65. +11.3);
    col += 0.07*fcos(t*131. +10.8);
    return col;
}

float getIntensityFilteredGrad( in float t )
{
    float col = 0.;
    col += 0.14*dfcos(t*  1.0+ 0.6, 1.0);
    col += 0.13*dfcos(t*  3.1+ 1.0, 3.1);
    col += 0.12*dfcos(t*  5.1+ 1.1, 5.1);
    col += 0.11*dfcos(t*  9.1+ 1.2, 9.1);
    col += 0.10*dfcos(t* 17.1+ 0.9, 17.1);
    col += 0.09*dfcos(t* 31. +11.3, 31.);
    col += 0.08*dfcos(t* 65. +11.3, 65.);
    col += 0.07*dfcos(t*131. +10.8,131.);
    return col;
}

float getIntensity( in float t )
{
    float col = 0.4;
    col += 0.14*cos(t*  1.0+0.6);
    col += 0.13*cos(t*  3.1+1.0);
    col += 0.12*cos(t*  5.1+1.1);
    col += 0.11*cos(t*  9.1+1.2);
    col += 0.10*cos(t* 17.1+0.9);
    col += 0.09*cos(t* 31. +11.3);
    col += 0.08*cos(t* 65. +11.3);
    col += 0.07*cos(t*131. +10.8);
    return col;
}

float getIntensityGrad( in float t )
{
    float col = 0.;
    col += 0.14*dcos(t*  1.0+0.6 , 1.0);
    col += 0.13*dcos(t*  3.1+1.0 , 3.1);
    col += 0.12*dcos(t*  5.1+1.1 , 5.1);
    col += 0.11*dcos(t*  9.1+1.2 , 9.1);
    col += 0.10*dcos(t* 17.1+0.9 , 17.);
    col += 0.09*dcos(t* 31. +11.3, 31.);
    col += 0.08*dcos(t* 65. +11.3, 65.);
    col += 0.07*dcos(t*131. +10.8,131.);
    return col;
}

void main(void)
{
    // coordiantes
    vec2 q = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    // separation
    float thx = 1.2*sin(time);
    float thy = 1.2*(resolution.y / resolution.x)*cos(time);
    bool light = (q.y>thy);
    bool filt = (q.x>thx);
    
    // deformation
    vec2 p = deform(q);
    p*=6.2832;
    
    // light position
    vec3 lp = normalize(vec3(cos(time),sin(time),0.2));
    
    vec3 col;
    if(!light){ // original version by Inigo Quilez 
        float i;
        if(filt){ // With filtering
            i = min(getIntensityFiltered(p.x),getIntensityFiltered(p.y));
        } else { // Without filtering
            i = min(getIntensity(p.x),getIntensity(p.y));
        }
        col = pal( i, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );
        
    } else { // shaded version
        float i1,i2,i;
        vec3 normal;
        
        if(filt){ // With filtering
            i1 = getIntensityFiltered(p.x);
            i2 = getIntensityFiltered(p.y);
            i = min(i1,i2);
            
            if(i == i1){
                normal.x = -getIntensityFilteredGrad(p.x);
                normal.z = 1.;
                normal.y = 0.;
            } else {
                normal.z = 1.;
                normal.y = -getIntensityFilteredGrad(p.y);
                normal.x = 0.;
            }
            
        } else { // Without filtering
               i1 = getIntensity(p.x);
               i2 = getIntensity(p.y);
               i = min(i1,i2);
            
            if(i == i1){
                normal.x = -getIntensityGrad(p.x);
                normal.z = 1.;
                normal.y = 0.;
            } else {
                normal.z = 1. ;
                normal.y = -getIntensityGrad(p.y);
                normal.x = 0.;
            }
        }
 
        normal = normalize(normal);
        
        col = pal( i, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );
        col = col + max(dot(lp,normal),0.);
        col *= 0.8;
    }
    
    
    
    // separation
    col *= smoothstep(0.005,0.010,abs(q.x-thx));
    col *= smoothstep(0.005,0.010,abs(q.y-thy));
    

    glFragColor = vec4( col, 1.0 );
}
