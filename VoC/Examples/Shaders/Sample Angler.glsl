#version 420

// original https://www.shadertoy.com/view/3dffDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Pre-Alpha Vector Field by Chris M. Thomasson ver:0.0.4
The code is basic, and the math can be streamlined.
This is a basic experiment, not thinking of sheer performance yet.

-- Removed the global array! :^)

-- Removed Create an attractor by clicking and dragging it around.
___________________________________*/

// The number of points in the spiral
#define CT_N 16

// Viewport Axes
struct ct_axes
{
    float xmin;
    float xmax;
    float ymin;
    float ymax;
};
    
    
ct_axes ct_axes_from_radius(
    in vec3 vpcircle
){
    return ct_axes(
        vpcircle.x - vpcircle.z,
        vpcircle.x + vpcircle.z,
        vpcircle.y - vpcircle.z,
        vpcircle.y + vpcircle.z
    );
}

// Simple 2d Plane
struct ct_plane2d
{
    ct_axes axes;
    float xstep;
    float ystep;
};
    
    
ct_plane2d ct_plane2d_create(
    in ct_axes axes
){
    float awidth = axes.xmax - axes.xmin;
    float aheight = axes.ymax - axes.ymin;
    
    float daspect = abs(resolution.y / resolution.x);
    float waspect = abs(aheight / awidth);
    
    if (daspect > waspect)
    {
        float excess = aheight * (daspect / waspect - 1.0);
        axes.ymax += excess / 2.0;
        axes.ymin -= excess / 2.0;
    }
    
    else if (daspect < waspect)
    {
        float excess = awidth * (waspect / daspect - 1.0);
        axes.xmax += excess / 2.0;
        axes.xmin -= excess / 2.0;
    }
    
    return ct_plane2d(
        axes,
        (axes.xmax - axes.xmin) / resolution.x,
        (axes.ymax - axes.ymin) / resolution.y
    );
}

vec2 ct_plane2d_project(
    in ct_plane2d self,
    in vec2 z
){
    return vec2(
        self.axes.xmin + z.x * self.xstep,
        self.axes.ymin + z.y * self.ystep
    );
}

// Gain a normalized vector from p, 
// using a power of npow.
vec2 ct_vfield_normal(
    in vec2 p,
    float npow
){
    vec2 g = vec2(0.0, 0.0);
    
    const int imax = CT_N;
    
    float abase = 6.28318 / float(imax);
    float rbase = 1. / float(imax);
    
    for (int i = 0; i < imax * 2; ++i)
    {
        float angle = abase * float(i);
        float radius = rbase * float(i);
        
        angle += sin(time * .5) * 3.1459;
       
        vec2 vp = vec2(
            cos(angle) * radius * (1. + abs(sin(time))), 
            sin(angle) * radius * (1. + abs(cos(time)))
        );
        
        float vm = -1.;
        
        vec2 dif = vp - p;
        float sum = dif[0] * dif[0] + dif[1] * dif[1];
        float mass = pow(sum, npow);
        
          g[0] = g[0] + vm * dif[0] / mass;
          g[1] = g[1] + vm * dif[1] / mass;
    }
    
    return normalize(g);
}

float ct_normal_pi(
    in vec2 z,
    in float sa
){
    float a = atan(z[1], z[0]) + sa;
    if (a < 0.0) a += 6.28318;
    a /= 6.28318;
    return a;
}

// Vector Pixel Iteration
vec4 ct_vpixel(
    in vec2 z,
    in vec2 c,
    in int n,
    in float npow
){
    vec2 vn = ct_vfield_normal(z, npow);
    
    float a = cos(time * .1) * 3.14; // Humm...
    
    float npi = ct_normal_pi(vn, a);
    
    float scale = float(CT_N);
    
    float color = mod(npi * scale, 1.0);
    
    if (color < .5)
    {
        //color /= .5;
        //return vec4(color, 0, color, 1.0);
    }
    
    return vec4(color, color, color, 1.0);
}

// High-Level Entry
vec4 ct_main(
    in ct_plane2d plane,
    in vec2 c
){  
    return ct_vpixel(c, c, 128, 2.);
}

// Raw Entry.
void main(void)
{
    vec3 vpcircle = vec3(
        0.0, 
        0.0, 
        0.1 + abs(sin(time * .1)) * 4.9
    );
    
    ct_plane2d plane = ct_plane2d_create(
        ct_axes_from_radius(vpcircle)
    );
    
    vec2 c = ct_plane2d_project(plane, gl_FragCoord.xy);
    
    // Exec...
    vec4 color = ct_main(plane, c);
    
    glFragColor = color;
}
