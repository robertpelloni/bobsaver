#version 420

// original https://www.shadertoy.com/view/fdBSzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fractal Morph Spin by Chris M. Thomasson

#define PI 3.1459

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

mat3 ct_rot_x(float angle) 
{
    float cos_temp = cos(angle);
    
    float sin_temp = sin(angle);
    
    return mat3(
        vec3(1., 0., 0.),
        vec3(0., cos_temp, -sin_temp),
        vec3(0, sin_temp, cos_temp)
    );
}

mat3 ct_rot_y(float angle) 
{
    float cos_temp = cos(angle);
    float sin_temp = sin(angle);
    return mat3(
        vec3(cos_temp, 0., sin_temp),
        vec3(0., 1., 0.),
        vec3(-sin_temp, 0., cos_temp)
    );
}

vec4 ct_circle(
    in vec2 c,
    in vec2 z,
    in float radius
){
    float d = length(c - z);
    
    if (d < radius) 
    {
        d = d / radius;
        float b = -(.25 + abs(sin(time * .15)));
        return exp(b*dot(d,d) ) * vec4(1,.7,.4,0)*2.;
    }
    
    return vec4(0.0, 0.0, 0.0, 0.0);
}

vec2 ct_cmul(in vec2 p0, in vec2 p1)
{
    return vec2(p0.x * p1.x - p0.y * p1.y, p0.x * p1.y + p0.y * p1.x);
}

float ct_torus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(vec2(p.x, p.z)) - t.x, p.y);
    return length(q) - t.y * 0.5;
}

float ct_de(vec3 p)
{
    p *= ct_rot_x(time);
    p *= ct_rot_y(time);
    float de = ct_torus(p, vec2(.9, .5 + sin(time) * .1f));
    return de;
}

mat3 ct_cam(in vec3 ro, in vec3 ta, float cr)
{
    vec3 norm_0 = normalize(ta - ro);
    vec3 p2d = vec3(sin(cr), cos(cr),0.0);
    vec3 cnorm_0 = normalize( cross(norm_0, p2d) );
    vec3 cnorm_1 = normalize( cross(cnorm_0, norm_0) );
    return mat3( cnorm_0, cnorm_1, norm_0 );
}

float ct_march_along(vec3 from, vec3 direction) {
    float dis_sum = 0.0;
    int i;
    for (i = 0; i < 64; i++) {
        vec3 p = from + dis_sum* direction;
        
        vec3 origin = vec3(1, 0, 0);
        
        float distance = ct_de(p);
        
        distance = min(distance, ct_de(p - origin));
        distance = min(distance, ct_de(p + origin));
        distance = min(distance, ct_de(p + origin + vec3(.2, .2, sin(time * .15))));
        
        dis_sum+= distance;
        if (distance < .001)
        {
            break;
        }
    }
    
    return 1.0 - float(i) / float(64);
}

vec3 ct_main(vec3 pt, vec3 direction) {
    float dis = ct_march_along(pt, direction);
    float color_1 = mod(dis * 5., 1.);
    return vec3(dis, dis, dis);
}

// Raw Entry.
void main(void) //WARNING - variables void ( need changing to glFragColor and gl_FragCoord.xy
{
    vec3 vpcircle = vec3(
        0., 
        0., 
        abs(sin(time * .25)) + .5
    );
    
    ct_plane2d plane = ct_plane2d_create(
        ct_axes_from_radius(vpcircle)
    );
    
    vec2 c = ct_plane2d_project(plane, gl_FragCoord.xy);
    
    
    
    vec2 cj = vec2(-.75, sin(time * .15) * .1);
    vec2 zj = c;
    
    zj = ct_cmul(zj, zj) + cj;
    zj = ct_cmul(zj, zj) + cj;
    zj = ct_cmul(zj, zj) + cj;

    
    c = zj;
    
    
    
    vec3 dis = vec3( 0, 0, 5 );
    vec3 origin = vec3( 0.0, 0.0, 0.0 );
    mat3 cam_mat = ct_cam( dis, origin, 0.0 );
    vec3 rai_vec = cam_mat * normalize( vec3(c.xy, 2.0) );
    
    // Exec...
    vec4 color = vec4(ct_main(dis, rai_vec), 1.);
    
    glFragColor = color;
}
