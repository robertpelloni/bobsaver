#version 420

// original https://www.shadertoy.com/view/MsKyR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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

float ct_circle(
    in vec2 c,
    in vec2 z,
    in float radius
){
    float d = length(c - z);
    if (d < radius) return 1.0;
    return 0.0;
}

vec2 ct_cmul(in vec2 p0, in vec2 p1)
{
    return vec2(p0.x * p1.x - p0.y * p1.y, p0.x * p1.y + p0.y * p1.x);
}

vec4 ct_spiral_arm(
    in vec2 c,
    in float astart,
    in int n
){
    vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
    
    float rbase = 1.0 / float(n);
    float abase = 6.28 / float(n);
    
    vec2 prev = vec2(0.0, 0.0);
    
    c = ct_cmul(c, c) + cos(time * .5) * .5;
    c = ct_cmul(c, c) + sin(time * .25) * .5;
    c = ct_cmul(c, c) + sin(time * .25) * .5;
    
    for (int i = 1; i < n + 1; ++i)
    {
        float angle = abase * float(i) + astart;
        float radius = rbase * float(i);
        
        vec2 cur = vec2(cos(angle) * radius, sin(angle) * radius);
        
        vec2 dif = cur - prev;
        
        float br = length(dif) / 2.0;
        
        vec2 mid = vec2(prev.x + dif.x * .5, prev.y + dif.y * .5);
        
        color += ct_circle(c, mid, br * (.2 + abs(sin(time * 1.5)) * .8));
        
        prev = cur;
    }
    
    
    return color;
}

// High-Level Entry
vec4 ct_main(
    in ct_plane2d plane,
    in vec2 c
){
    vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
    
    vec2 center = vec2(0.0, 0.0);
    float radius = 1.8;
    //int n = 6;//2 + (int(floor(time * 3.)) % 16);
    
    int sn = 23;
    float aspin = -time * 1.0;
    
    int n = 5;
    float abase = 6.28 / float(n);
    
    for (int i = 0; i < n; ++i)
    {
         float angle = abase * float(i) + aspin;
        
        color += ct_spiral_arm(c, angle, sn);
    }
    
    return color;
}

// Raw Entry.
void main(void) {
    vec3 vpcircle = vec3(
        0., 
        0., 
        abs(cos(time * .25)) + .5
    );
    
    ct_plane2d plane = ct_plane2d_create(
        ct_axes_from_radius(vpcircle)
    );
    
    vec2 c = ct_plane2d_project(plane, gl_FragCoord.xy);
    
    // Exec...
    vec4 color = ct_main(plane, c);
    
    glFragColor = color;
}
