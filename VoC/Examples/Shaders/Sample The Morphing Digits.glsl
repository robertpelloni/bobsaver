#version 420

// original https://www.shadertoy.com/view/NsdcWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: The Morphing Digits

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

// This shader was inspired by the fine work of Xor.
// The Typist  - https://www.shadertoy.com/view/sd3czM

// Not so long ago I wrote code for changing numbers, but I couldn't think of a way to make
// it interesting. "The Typist" gave me a good idea. 
// But I used a different method for the "tilt shift" effect.

// "Hash without Sine" by Dave_Hoskins.
// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
  vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// IQ's segment SDF 
// https://iquilezles.org/articles/distfunctions2d/
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0., 1. );
    return length( pa - ba*h );
}

#define hue(v) ( .7 + .4 * cos(6.3*(v) + vec4(0,23,21,0) ) ) //hue
#define S(a,b,c) smoothstep (a+b, a-b, c)

void main(void) //WARNING - variables void ( out vec4 O, in vec2 g ) need changing to glFragColor and gl_FragCoord.xy
{
	vec2 g = gl_FragCoord.xy;
	vec4 O = gl_FragColor;

    vec2 r = resolution.xy
        ,org = (g+g-r)/r.y;
    
    vec2 uv = org, p, v;
    uv *= .5 + length(uv)*.02;  //camera barrel distortion
    uv = (uv*mat2(10,-3,1,8)/(2.-org.y*.5)+time*.5)*.75; //camera rotation, skew and zoom
    
    vec2 lc = fract(uv)*vec2(1.8,3) + vec2(-.4,-1.5); //cell local coordinates

    float H = hash12(floor(uv))*2.              //cell hash - determines the color of the digit and the timer offset
        , ts = (1.-S(.6,.3,abs(org.y)))*1.2     //value of "tilt shift" effect
        , N = (hash12(uv*50.)-.5)*ts*.01        //noise value
        , f = 9.
        , z = f
        , a, b, l
        , T = mod(time+H,2.);                 //cycle of digits change - 2 sec
    
    lc += N;    //add a fine noise shift 
    
    //         1            Segment numbers and their drawing directions.
    //      ╔═════╗
    //      ║  ←  ║         The digit consists of seven segments and is coded as an integer.
    //     0║↑   ↑║2        The bit number corresponds to the segment number.
    //      ║  6  ║         The segment is defined by a start point and a vector to the end point.
    //      ╠═════╣         The segment is also encoded by an integer, bits 0-4 being the start point
    //      ║  ←  ║         and bits 4-8 being the vector.
    //     5║↓   ↓║3
    //      ║  ←  ║
    //      ╚═════╝
    //         4
         
    int s[7] = int[7](149,74,150,22,66,21,70)                //segments
        , d[10] = int[10](63,12,118,94,77,91,123,14,127,95)  //digits
        , i=0;
    
    for (;i<7;i++)      //draw all 7 segments
    {
        p = vec2((s[i] & 3) - 1, ((s[i]>>2) & 3) - 1);      //segment start point
        v = vec2((s[i]>>4 & 3) - 1, (s[i]>>6 & 3) - 1);     //vector to the end point
        
        a =  float(d[int(hash12(vec2(floor((time+H)*.5),H))*10.)] >> i & 1);       //the current digit in the cell
        b =  float(d[int(hash12(vec2(floor((time+H)*.5)+1.,H))*10.)] >> i & 1);    //digit in the cell in the next cycle
        l = mix(a,b,smoothstep (.5,1.5,T));                 //segment is changing (or not) from 0.5 to 1.5 seconds of cicle 
        if (l > 0.) f = min(f,sdSegment(lc,p,p+v*l));       //SDF for segment
        if (a > 0.) f = min(f, length(p - lc) + .5 * smoothstep (1.5,2.,T));    //fade out for old segments 1.5 to 2 seconds
        if (b > 0.) f = min(f, length(p - lc) + .5 * smoothstep (.5,0.,T));     //fade in for new segments 1.5 to 2 seconds
        
        z = min(z,sdSegment(lc,p,p+v));     //SDF for digit background
    }
    
    a = .25;                        //segment width
    b = ts*.15+5./resolution.y;    //segment "blur factor" for "tilt shift" effect 
    
    O = -O;
    O = mix (                   //mix colors
            mix(
                mix(O,vec4(.1+S(.03,b,abs(z-a))*.1), S(a,b,z))      //digit background with outline 
                ,hue(H),S(a,b,f))                                   //digit foreground
                ,vec4(0),S(.2,b, abs(fract(f*20.)-.5))*(.2-ts*.2)*step(f,.23));   //thin black lines

    z = dot (vec2(sin(time)*.5-1.,1),normalize(vec2(dFdx(f),dFdy(f))));    //light direction and normal
    O = O * (.8 + z*.5*S(.4,.2,abs(org.y))*S(.1,.1,abs(f-.2)))              //add lighting and shadows
        + N*4.;     //and fine noise

	glFragColor = O;
}
