#version 420

// original https://www.shadertoy.com/view/tdXSWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Create a two-dimensional rotation matrix
mat2 rot(in float a){float s = sin(a); float c= cos(a); return mat2(c,s,-s,c);}

// Signed distance field function of a sphere
float sphere(vec3 p, float r){return length(p)-r;}
// Use modulo to copy the spheres
float copy(float p, float d){return mod(p, d) - d/2.0;}

// The distance to the closest sphere
float map(vec3 p){
    p.y-= time;
    p.xz = p.xz*rot(time/11.);
    p.x -= time*3.0;
    p.x = copy(p.x, 10.0);
    p.z = copy(p.z, 10.0);
    p.y = copy(p.y, 5.0);
    float s1 = sphere(vec3(p.x, p.y - 0.0, p.z), 1.0);
    float s2 = sphere(vec3(p.x, p.y - 2.5, p.z), 1.0);
    float s3 = sphere(vec3(p.x, p.y + 2.5, p.z), 1.0);
     return min(min(s1, s2), s3);
}

// The distance to the closest point on the water
float wmap(vec3 p){
     return p.y+0.3;
}

// Use raymacrching to get the point in which the ray hits a ball
vec3 trace(vec3 ro, vec3 rd){
    int i = 0;
    vec3 mp = ro;
     for (i = 0; i < 60; i++)
    {
        float dist = map(mp);
        mp += rd*dist;
        if(dist < 0.01){break;}
    }
    return mp;
}

// Distort the normal of the plane to create the water effect
vec3 distort(vec3 p, float i){return vec3(p.x + sin(p.x*315.+time*1.2)*i/10.,p.y +cos(p.y*321.+time)*i,p.z + sin(p.z*300.+time)*i/10.);}

// Use raymacrching to get the point in which the ray hits the water
vec3 wtrace(vec3 ro, vec3 rd){
    int i = 0;
    vec3 mp = ro;
     for (i = 0; i < 100; i++){
        float dist = wmap(mp);
        mp += rd*dist;
        if(dist < 0.01){break;}
    }
    return mp;
}
void main(void)
{
    // Coordinates in the center of the screen are 0,0
    // Using x-resolution to scale the coordinates (-1 to 1 on x axis)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv*2.0 - 1.0;
    uv.y *= resolution.y/resolution.x;
    // Ray orignin and ray dispance for the ray marching loops
    vec3 ro = vec3(0.0); vec3 rd = normalize(vec3(uv.x, uv.y, 2.0));
    // How far the ray can travel before hitting a sphere
    float dist1  = length(trace(ro, rd));
    // The point in which the ray hits water
    vec3 wp = wtrace(ro, rd);
    // How far the ray cal travel before hitting water
    float wdist = length(wp);
    // The distorted reflection after hitting water
    vec3 wnormal = normalize(distort(vec3(rd.x, -rd.y, rd.z), 0.02));
    // The distance from water to the sphere the reflection ray hits
    float rdist = length(trace(ro + rd*wdist, wnormal)) - wdist;
    vec3 col = vec3(0.0);
    // Background color
    vec3 bgcol = vec3(0.125, 0.25, 0.5)*(uv.y+0.1);
    // Water Background color
    vec3 wbgcol = vec3(0.125, 0.25, 0.5)*(-uv.y*1.0-0.1);
    // If the ray hits nothing, use the bg color
    if(min(dist1, wdist) > 120.0)
        col = bgcol;
    else
    {
        // If the ray hits a sphere, use the sphere's white color, blend its color with the background
        if(dist1 < wdist)
            col = mix(vec3(1.0), bgcol, dist1/120.);
        else
        {
            // Does the reflection ray hit a sphere? No: use the water background color
            if(wdist + rdist > 120.)
                col = wbgcol;
            // Yes: Blend the sphere's color with the water background color
            else
                col = mix(vec3(1.0), wbgcol, (wdist + rdist)/120.);
        }
    }
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
