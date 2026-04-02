#version 420

// original https://www.shadertoy.com/view/MtBfzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

vec2    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
void    rotate(inout vec2 v, float angle);

float     t;            // time
vec3    ret_col;    // torus color
vec3    h;             // light amount

#define I_MAX        400.
#define E            0.00001
#define FAR            50.
#define PI            3.14

// noises taken from : https://www.shadertoy.com/view/4djSRW

// -------------noise--------------------- //
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1, .05030, -.0973)

float hash11(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * HASHSCALE3);
   p3 += dot(p3, p3.yzx+19.19);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}
// -------------noise--------------------- //

// blackbody by aiekick : https://www.shadertoy.com/view/lttXDn

// -------------blackbody----------------- //

// return color from temperature 
//http://www.physics.sfasu.edu/astro/color/blackbody.html
//http://www.vendian.org/mncharity/dir3/blackbody/
//http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html

vec3 blackbody(float Temp)
{
    vec3 col = vec3(255.);
    col.x = 56100000. * pow(Temp,(-3. / 2.)) + 148.;
       col.y = 100.04 * log(Temp) - 623.6;
       if (Temp > 6500.) col.y = 35200000. * pow(Temp,(-3. / 2.)) + 184.;
       col.z = 194.18 * log(Temp) - 1448.6;
       col = clamp(col, 0., 255.)/255.;
    if (Temp < 1000.) col *= Temp/1000.;
       return col;
}

// -------------blackbody----------------- //

void main(void)
{
    vec2 f = gl_FragCoord.xy;
    t  = time*.125;
    vec3    col = vec3(0., 0., 0.);
    vec2 R = resolution.xy,
          uv  = vec2(f-R/2.) / R.y;
    vec3    dir = camera(uv);
    vec3    pos = vec3(.0, .0, 0.0);

    pos.z = 24.5+1.5*sin(t*10.);    
    h*=0.;
    vec2    inter = (march(pos, dir));
    if (inter.y < FAR)
    col.xyz = ret_col*(inter.y*.085);
    col += -h*.01251-.75+.25*blackbody(3000.*length(h.x+h.y+h.z)*.005125);
    glFragColor =  vec4(col,1.0);
}

float    scene(vec3 p)
{  
    float    var;
    float    mind = 1e5;
    p.z += 10.;
    
//    rotate(p.xz, 1.57-.5*time );
    rotate(p.yz, 1.57-.5*time );
    var = atan(p.x,p.y);
    vec2 q = vec2( ( length(p.xy) )-6.,p.z);
    var = sin(floor(sin(atan(p.x, p.y)*1.+time*2.)*3.14 + 3.14*sin(floor(atan(q.x, q.y)*4. + time*5.) + ((time*1.1))*.8 ) ));//+sin(floor(atan(p.x, p.y)*4. +floor(time*10.1)*.1 ) );
    float    oldvar = var;//var;
    var = ( hash11(sin(var*1.) ) );
    ret_col = 1.-vec3(.350, .2, .3);
    ret_col = .5*hash31(sin(var*1.) );
    q.x -= 2.5*var;
    mind = length(q)-2.-var*1.5;
    mind = max(mind, -(length(q)-1.5-var*1.5) );
    h -= .8-ret_col*.125/(.0251+mind*mind);
    
    return (mind);
}

vec2    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0, 0.0);
    vec3    p = vec3(0.0, 0.0, 0.0);
    vec2    s = vec2(0.0, 0.0);

        for (float i = -1.; i < I_MAX; ++i)
        {
            p = pos + dir * dist.y;
            dist.x = scene(p);
            dist.y += dist.x*.12; // makes artefacts disappear
            // log trick by aiekick
            if (log(dist.y*dist.y/dist.x/1e5) > .0 || dist.x < E || dist.y > FAR)
            {
                break;
            }
            s.x++;
    }
    s.y = dist.y;
    return (s);
}

// Utilities

void rotate(inout vec2 v, float angle)
{
    v = vec2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}

vec3    camera(vec2 uv)
{
    float        fov = 1.;
    vec3        forw  = vec3(0.0, 0.0, -1.0);
    vec3        right = vec3(1.0, 0.0, 0.0);
    vec3        up    = vec3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}
