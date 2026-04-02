#version 420

// original https://www.shadertoy.com/view/llScDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Pre-Alpha Vector Field by Chris M. Thomasson ver:0.0.3
The code is basic, and the math can be streamlined.
This is a basic experiment, not thinking of sheer performance yet.

Create an attractor by clicking and dragging it around.
___________________________________*/

// The number of points in the spiral
#define CT_N 5

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

// A vector field point
struct ct_vfpoint
{
    vec2 p;
    float m;
};

// Our global per-pixel points
ct_vfpoint g_vfp[CT_N + 1];

// Gain a normalized vector from p, 
// using a power of npow.
vec2 ct_vfield_normal(
    in vec2 p,
    float npow
){
    vec2 g = vec2(0.0, 0.0);
    
    int imax = g_vfp.length();
    
    for (int i = 0; i < imax; ++i)
    {
        vec2 dif = g_vfp[i].p - p;
        float sum = dif[0] * dif[0] + dif[1] * dif[1];
        float mass = pow(sum, npow);
        
          g[0] = g[0] + g_vfp[i].m * dif[0] / mass;
          g[1] = g[1] + g_vfp[i].m * dif[1] / mass;
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
    
    float a = cos(time * .25) * 3.14;

    vec2 rc = vec2(
        vn[0] * cos(a) - vn[1] * sin(a),
        vn[0] * sin(a) + vn[1] * cos(a)
    );
    
    float npi = ct_normal_pi(vn, a);
    
    float blah = length(vn);
    
    if (blah < .01)
    {
        //return vec4(1.0, 1.0, 0.0, 1.0);
    }
    
    float scale = float(CT_N);// + abs(cos(time * .5)) * 6.0;
    
    return vec4(
        mod(npi * scale, 1.0), 
        mod(npi * scale, 1.0), 
        mod(npi * scale, 1.0),
        1.0
    );
}

// High-Level Entry
vec4 ct_main(
    in ct_plane2d plane,
    in vec2 c
){
    int n = CT_N;
    float scale = 1.0;
    
    for (int x = 0; x < n; ++x)
    {
        int y = 0;
        float xr = float(x) / float(n);
        float angle = xr * 6.28;// + cos(time * .02) * 5.0;
        
        g_vfp[x] = ct_vfpoint(
            vec2(cos(angle), sin(angle)), 
            1.0
        );
    }
    
    //if (mouse*resolution.xy.z > 0.0)
    //{
        vec2 cm = ct_plane2d_project(plane, vec2(mouse*resolution.xy));
        g_vfp[n] = ct_vfpoint(
            cm, 
            -1.6
        );
    //}
    
    return ct_vpixel(c, c, 128, 2.0 + abs(cos(time * 3.0)));
}

// Raw Entry.
void main(void){
    vec3 vpcircle = vec3(
        0.0, 
        0.0, 
        2.0 + cos(time * 1.0) * abs(sin(time * .5))
    );
    
    ct_plane2d plane = ct_plane2d_create(
        ct_axes_from_radius(vpcircle)
    );
    
    vec2 c = ct_plane2d_project(plane, gl_FragCoord.xy);
    
    // Exec...
    vec4 color = ct_main(plane, c);
    
    glFragColor = color;
}
