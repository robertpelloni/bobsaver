#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlBBzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = 3.1415926535;
vec3 viewer = vec3(1., 2.,-3.);
float fov = 3.14159/3.;
float cyl_radius = 1.;
float cyl_height = 1.;

vec3 raytrace(vec3 ray)
{
    vec3 col = vec3(.5);
    
    //intersect between cylinder and ray
    
    vec2 xz = normalize(ray.xz);
    vec2 dir = -viewer.xz;
    float d_o = dot(xz,dir);
    float d_c = length(d_o*xz-dir);
    if ( d_c>cyl_radius ) return col;

    float d_d = sqrt(cyl_radius*cyl_radius-d_c*d_c);
    float lmin = (d_o-d_d)/length(ray.xz);
    float lmax = (d_o+d_d)/length(ray.xz);
    if (abs(ray.y) <= 1e-6)
    {
        if (viewer.y>(cyl_height/2.)||viewer.y<(-cyl_height/2.))
            lmax = lmin-1.;
    }
    else
    {
        d_o = sign(ray.y)*(-viewer.y);
        d_d = cyl_height/2.;
        lmin = max (lmin, (d_o-d_d)/abs(ray.y));
        lmax = min (lmax, (d_o+d_d)/abs(ray.y));
    }
    float hmin = lmin-1.;
    float hmax = lmax+1.;
    if (abs(ray.x) <= 1e-6)
    {
        if (viewer.x>cyl_radius||viewer.x<0.)
            hmax = hmin-1.;
    }
    else
    {
        d_o = sign(ray.x)*(cyl_radius/2.-viewer.x);
        d_d = cyl_radius/2.;
        hmin = max (hmin, (d_o-d_d)/abs(ray.x));
        hmax = min (hmax, (d_o+d_d)/abs(ray.x));
    }
    if (abs(ray.y) <= 1e-6)
    {
        if (viewer.z>0.||viewer.z<-cyl_radius)
            hmax = hmin-1.;
    }
    else
    {
        d_o = sign(ray.z)*(-cyl_radius/2.-viewer.z);
        d_d = cyl_radius/2.;
        hmin = max (hmin, (d_o-d_d)/abs(ray.z));
        hmax = min (hmax, (d_o+d_d)/abs(ray.z));
    }
    if ((lmin<hmax)&&(lmin>hmin)) lmin = hmax;
    if (lmin<=lmax)
    {
        col.z=1.;
        vec3 loc = lmin*ray+viewer;
        if (loc.z>0.) col.x = 1.;
        float h,s,l,c,h2,x,m;
        h = acos(loc.x/(length(loc.xz)+1e-6))*sign(loc.z)+pi+time/pi;
        h = mod(h, 2.*pi);
        s = length(loc.xz)/cyl_radius;
        l = loc.y/cyl_height+.5;
        c = l*s;
        h2 = h/(pi/3.);

        int ih = int(h2);
        col = vec3(1.);
        col[(ih/2+2)%3] = 0.;
        col[(7-ih)%3] -= abs( mod(h2, 2.)-1.);
        col *= c;
        col += l-c;
    }

    return(col);
}

vec3 raygen(vec2 uv)
{
    //vec from viewer to cyl_center turned by fov*uv
    vec3 ray = vec3(uv,.5/tan(fov/2.));
    {
    vec3 dir = -viewer;
    float h,c,s;
    h = length(dir.xz);
    s = dir.y/h;
    c = dir.z/h;
    ray.yz *= mat2(c,s,-s,c);
    h = length(dir.xz);
    s = dir.x/h;
    c = dir.z/h;
    ray.xz *= mat2(c,s,-s,c);
    }
    return normalize(ray);
}

void main(void)
{
    vec2 R = resolution.xy;
    if (fov<0.||fov>=pi) return;
    vec3 col = vec3(0.);
    
    // squared pixel coordinates (from -0.5 to 0.5)
    vec2 uv;
    for(int i = 0; i <9; ++i) {
        vec2 delta = vec2(i%3-1,i/3-1);
        uv = (gl_FragCoord.xy+delta/3.-R/2.)/max(R.x,R.y);
        col += raytrace(raygen(uv))/9.;
    }
    
    
    // Output to screen
    glFragColor = vec4(col,1.);
}
