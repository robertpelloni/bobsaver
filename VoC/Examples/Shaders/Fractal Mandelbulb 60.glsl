#version 420

// original https://www.shadertoy.com/view/stlGDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ####### Colorful Mandelbulb #######
// Made by Zi7ar21 on May 26th, 2021
// Last Updated: May 26th, 2021 at 11:35 Mountain Standard Time

// If you found this anywhere except Shadertoy, the original and possibly updated version can be found at:
// https://www.shadertoy.com/view/stlGDH

// Check out my friends!
// michael0884
// https://www.shadertoy.com/user/michael0884
// loicvdb
// https://www.shadertoy.com/user/loicvdb
// Dumb Psycho
// https://www.shadertoy.com/user/Dumb_Psycho

// Inspired by "Raymarched Mandelbulb" by Dumb Psycho:
// https://www.shadertoy.com/view/fll3D8

// ##### PARAMETERS #####

#define gamma   2.2
#define camfov  1.0
#define hitDist 1E-3
#define maxDist 8.00
#define maxStep 128

#define iterations 6

// ##### CONSTANTS #####

// Traditional Input Names
#define resolution resolution
#define time time

// http://www.mimirgames.com/articles/programming/digits-of-pi-needed-for-floating-point-numbers/
#define pi 3.1415926535897932384626433832795028841971693993751058209749445923078164

// ##### RENDERING #####

// Material Datatype
struct material {
    vec3 albedo;
    vec3 normal;
};

// Rotate a 3-Component Vector
vec3 rotate(vec3 vec, vec3 rot)
{
    vec3 s = sin(rot), c = cos(rot);

    mat3 rotx = mat3(
    1.0, 0.0, 0.0,
    0.0, c.x,-s.x,
    0.0, s.x, c.x);
    mat3 roty = mat3(
    c.y, 0.0,-s.y,
    0.0, 1.0, 0.0,
    s.y, 0.0, c.y);
    mat3 rotz = mat3(
    c.z,-s.z, 0.0,
    s.z, c.z, 0.0,
    0.0, 0.0, 1.0);

    mat3 rotmat = rotx*roty*rotz;

    /*
    rotmat[0] = normalize(rotmat[0]);
    rotmat[1] = normalize(rotmat[1]);
    rotmat[2] = normalize(rotmat[2]);
    */

    return (vec.x*rotmat[0])+(vec.y*rotmat[1])+(vec.z*rotmat[2]);
}

// Scene Distance Estimator
float DE(in vec3 pos, out vec3 orbitTrap)
{
    // Performance Increase
    if(dot(pos, pos) > 8.0)
    {
        return length(pos)-1.3;
    }

    pos = rotate(pos, pi*vec3(time*0.125*0.125, time*0.125, 0.0));

    //const float power = 8.0;
    float power = (sin(0.125*0.5*pi*time)*2.0)+8.0;

    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;

    orbitTrap = vec3(1.0);

    for(int i = 0; i < iterations; i++)
    {
        r = length(z);

        if(r > 4.0)
        {
            break;
        }

        // Convert to Polar Coordinates
        float theta = acos(z.z/r)*power;
        float phi = atan(z.y, z.x)*power;
        dr = pow(r, power-1.0)*power*dr+1.0;

        // Scale and Rotate the Point
        float zr = pow(r, power);

        // Convert back to Cartesian Coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));

        // Compute Orbit Trap Color
        orbitTrap = min(orbitTrap, abs(z));

        z += pos;
    }

    // Return the Distance to the Fractal
    return 0.5*log(r)*r/dr;
}

// Distance Estimator Tetrahedron Numerical Normals
vec3 getNormal(vec3 pos)
{
    const vec2 k = vec2(-1.0, 1.0);

    vec3 n;

    return normalize(
    k.xxx*DE(pos+k.xxx*hitDist, n)+
    k.xyy*DE(pos+k.xyy*hitDist, n)+
    k.yxy*DE(pos+k.yxy*hitDist, n)+
    k.yyx*DE(pos+k.yyx*hitDist, n));
}

// Distance Estimator Ray-Marching
float intersectDE(in vec3 ro, in vec3 rd, out material materialProperties)
{
    // Set-Up Variables
    float t = 0.0;

    for(int i = 0; i < maxStep; i++)
    {
        if(t > maxDist)
        {
            break;
        }

        float td = DE(ro+rd*t, materialProperties.albedo);

        if(td < hitDist)
        {
            materialProperties.normal = getNormal(ro+rd*t);
            return t;
        }

        t += td;
    }

    // No Intersection
    return -1.0;
}

// Intersection Function
float intersect(in vec3 ro, in vec3 rd, out material materialProperties)
{
    // Compute the Intersection
    float t = intersectDE(ro, rd, materialProperties);

    // Return the Intersection
    return t;
}

// Distance Estimator Soft Shadows
float softShadow(vec3 ro, vec3 rd)
{
    float res = 1.0;
    float t = 0.0;
    float ph = 1E4;
    vec3 n;
    for(int i = 0; i < maxStep; i++)
    {
        float h = DE(ro+rd*t, n);
        float y = i == 0 ? 0.0 : h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);

        res = min(res, 10.0*d/max(0.0, t-y));

        t += h;

        if(res < hitDist || t > maxDist){break;}
    }

    res = clamp(res, 0.0, 1.0);

    return res*res*(3.0-2.0*res);
}

// Rendering
vec3 radiance(vec3 ro, vec3 rd)
{
    // Set-Up Variables
    material materialProperties;

    // Compute the Intersection
    float t = intersect(ro, rd, materialProperties);

    // If there was no Intersection
    if(t < 0.0)
    {
        // Return Background Color
        return (max(vec3(0.4, 0.8, 1.0)*dot(rd, vec3(0.0, 1.0, 0.0)), 0.0)*0.9)+0.1;
    }

    //vec3 lightPosition = vec3(sin(pi*time)*2.0, 4.0, (cos(pi*time)*2.0)-4.0);
    const vec3 lightPosition = vec3(4.0, 4.0, -4.0);

    // Direction of the Light
    vec3 lightDirection = normalize(lightPosition-(ro+rd*t));

    // Compute Lighting
    float lighting0 = max(dot(materialProperties.normal, lightDirection), 0.0);
    float lighting1 = max(dot(materialProperties.normal,-lightDirection), 0.0)*0.1;
    float lighting = lighting0+lighting1+0.2;
    lighting = mix(softShadow(ro+(rd*t)+(materialProperties.normal*hitDist), lightDirection)*lighting, lighting, 0.4);

    // Return Final Result
    return materialProperties.albedo*lighting;
}

// Render and Output the Frame
void main(void)
{
    // Screen UV Coordinates
    vec2 uv = 2.0*(gl_FragCoord.xy-0.5*resolution.xy)/max(resolution.x, resolution.y);

    // Set-Up Variables
    const vec3 ro = vec3(2.0, -1.0, -2.0);

    /*
    const mat3 rotmat = mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
    //rotmat[0] = normalize(rotmat[0]);
    //rotmat[1] = normalize(rotmat[1]);
    //rotmat[2] = normalize(rotmat[2]);
    */

    const vec3 camtarget = vec3(0.0);

    // Calculate the Direction of the Ray
    vec3 targetdir = normalize(camtarget-ro);
    vec3 left = cross(targetdir, vec3(0.0, 1.0, 0.0));
    vec3 up = cross(left, targetdir);
    mat3 rotmat = mat3(left, up, targetdir);
    vec3 rd = normalize(camfov*(uv.x*rotmat[0]+uv.y*rotmat[1])+rotmat[2]);

    // Render the Frame
    vec3 color = radiance(ro, rd);

    // HDR Tonemapping
    color = clamp(pow(color/(color+1.0), vec3(1.0/gamma)), 0.0, 1.0);

    // Output the Rendered Frame
    glFragColor = vec4(color, 1.0);
}
