#version 420

// original https://www.shadertoy.com/view/MdfcRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Kleinian group using an algorithm of Jos Leys and coloured with orbit traps.
// For more info check this thread on Fractal Forums:
// http://www.fractalforums.com/3d-fractal-generation/an-escape-tim-algorithm-for-kleinian-group-limit-sets/
// and read this paper from Jos:
// http://www.josleys.com/articles/Kleinian%20escape-time_3.pdf

#define MAXITER 64
#define PLAY_ZOOM

float box_size_x = 0.92;

float wrap(float x, float a, float s)
    {
    x -= s; 
    return (x-a*floor(x/a)) + s;
    }

void TransA(inout vec2 z, float a, float b)
    {
    float iR = 1. / dot(z,z);
    z *= -iR;
    z.x = -b - z.x; 
    z.y = a + z.y; 
    }

vec4  JosKleinian(vec2 z)
    {
    float time = time * 0.2;
    float PIH = 1.570797;
#ifdef PLAY_ZOOM
    float zoommin = 1.0;
    float zoommax = 30.0;
    float zoom = (sin(time - PIH) + 1.0) / 2.0 * (zoommax - zoommin) + zoommin;
    //vec2 zoomcenter = vec2((sin(time - PIH) - 0.65) * 0.2, (sin(time - PIH) + 0.95) * 0.5);
    vec2 zoomcenter = vec2(-0.2, 0.5);
#else
    float zoom = 2.8;
    vec2 zoomcenter = vec2(-1.0, 1.75);
#endif

    z /= zoom;
    z += zoomcenter;

    vec2 lz=z+vec2(1.), llz=z+vec2(-1.);
    float flag=0.;
    float KleinR = 1.8462756+(1.958591-1.8462756)*0.5+0.5*(1.958591-1.8462756)*sin(-time*0.2);  
    float KleinI = 0.09627581+(0.0112786-0.09627581)*0.5+0.5*(0.0112786-0.09627581)*sin(-time*0.2);
    //float KleinR = 1.902;
    //float KleinI = 0.042;
      
    float a = KleinR;
    float b = KleinI;
    float f = sign(b)*1.;
    vec4 dmin = vec4(1e20);
    for (int i = 0; i < MAXITER; i++) 
        {
        z.x = z.x + f*b/a*z.y;
        z.x = wrap(z.x, 2. * box_size_x, - box_size_x);
        z.x = z.x - f*b/a*z.y;

        //If above the separation line, rotate by 180° about (-b/2, a/2)
        if  (z.y >= a * 0.5 + f *(2.*a-1.95)/4. * sign(z.x + b * 0.5)* (1. - exp(-(7.2-(1.95-a)*15.)* abs(z.x + b * 0.5))))
            {
            z = vec2(-b, a) - z;
            }

        //Apply transformation a
        TransA(z, a, b);

        // trap calculation
        dmin=min(dmin, vec4( 
                abs(0.0+z.y + 0.5*sin(z.x)),
                abs(1.0+z.x + 0.5*sin(z.y)),
                dot(z,z),
                length(fract(z)-0.5)
        ));

        //If the iterated points enters a 2-cycle , bail out.
        if (dot(z-llz,z-llz) < 1e-6)
            {
            break;
            }
        //if the iterated point gets outside z.y=0 and z.y=a
        if (z.y < 0. || z.y > a)
            {
            flag=1.; 
            break;
            }
        //Store prévious iterates
        llz=lz; lz=z;
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
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - vec2(0.42, 0.);
    uv.x *= resolution.x/resolution.y;
    glFragColor = JosKleinian(uv);
}
