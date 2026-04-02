#version 420

// original https://www.shadertoy.com/view/4lGXDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Piotr Borys - utak3r/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Classic Julia with animated c param, playing with zoom and pan.
//
// Antialiasing procedure from ttoinou
// Orbit traps colouring from Inigo Quilez (iq)
//
// For antialiasing, use AA_ENABLE and adjust AA_RADIUS for your needs/capabilities.
// For rendering a whole fractal, without camera zooming and panning, disable PLAY_ZOOM.
// MAXITER is taken into account only with PLAY_ZOOM disabled.
// MINITER is a starting value for dynamic quality in zooming animation.
//
// Please note: 
// In WebGL one cannot use variables as for loop's target, as the loop is unwinded.
// Hence here below in main for loop I'm going to use a MAXITER constant.
// But, if you want to use it somewhere else, go and use a maxiter variable instead.

#define MAXITER 1024
#define MINITER 256
//#define AA_ENABLE
#define AA_RADIUS 4
#define PLAY_ZOOM

vec4 julia(vec2 gl_FragCoord)
    {
    float time = time * 1.0;
    float PIH = 1.570797;
#ifdef PLAY_ZOOM
    float zoommin = 0.8;
    float zoommax = 5.0;
    float zoom = (sin(time - PIH) + 1.0) / 2.0 * (zoommax - zoommin) + zoommin;
    //int maxiter = int(float(MINITER) * zoom); // disabled for WebGL
    vec2 zoomcenter = vec2(cos(3.0*time*0.2), sin(5.0*time*0.2));
#else
    float zoom = 0.8;
    vec2 zoomcenter = vec2(0.0, 0.0);
    //int maxiter = MAXITER; // disabled for WebGL
#endif

    vec2 z = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    z.x *= resolution.x/resolution.y;
    z += zoomcenter;
    z /= zoom;
    vec2 c = 1.1*vec2( 0.5*cos(0.1*time) - 0.25*cos(0.2*time), 
                        0.5*sin(0.1*time) - 0.25*sin(0.2*time));
    vec4 dmin = vec4(1e20);

    for (int i = 0; i < MAXITER; i++)
        {
        z = vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y ) + c;
        dmin=min(dmin, vec4(abs(0.0+z.y + 0.5*sin(z.x)),
                            abs(1.0+z.x + 0.5*sin(z.y)),
                            dot(z,z),
                            length(fract(z)-0.5)));
        }

    vec3 color = vec3(dmin.w);
    color = mix(color, vec3(0.992, 0.929, 0.675), min(1.0,pow(dmin.x*0.25,0.20)));
    color = mix(color, vec3(0.835, 0.8, 0.667), min(1.0,pow(dmin.y*0.50,0.50)));
    color = mix(color, vec3(1.00,1.00,1.00), 1.0-min(1.0,pow(dmin.z*1.00,0.15)));
    color = 1.25*color*color;
    return vec4(color, 1.0);
    }

void main(void)
{
    vec4 i1, i2;
#ifdef AA_ENABLE
    i1 = julia(gl_FragCoord.xy);
    vec2 pos;
    float radius = float (AA_RADIUS);
    for (int i = 0; i < AA_RADIUS; i++)
    {
        for (int j = 0; j < AA_RADIUS; j++)
        {
            if (i + j > 0)
            {
            pos = vec2(i, j) / radius;
            i2 = julia(gl_FragCoord+pos);
            i1 += i2;
            }
        }
    }
    i1 /= radius*radius;
#else
    i1 = julia(gl_FragCoord.xy);
#endif
    glFragColor = i1;
}
