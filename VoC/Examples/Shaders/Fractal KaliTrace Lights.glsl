#version 420

// original https://www.shadertoy.com/view/MsKSDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** KaliTrace+Light
    https://www.shadertoy.com/view/MsKSDG

    (cc) 2016, stefan berke

    More or less the same as     
    https://www.shadertoy.com/view/4sKXWG
    
    Added implicit lighting and light-reflection
    and some parameter morphing

*/

// minimum distance to axis-aligned planes in kali-space
// uses eiffie's mod (/p.w) https://www.shadertoy.com/view/XtlGRj
// to keep the result close to a true distance function
vec3 kali_set(in vec3 pos, in vec3 param)
{
    vec4 p = vec4(pos, 1.);
    vec3 d = vec3(100.);
    for (int i=0; i<9; ++i)
    {
        p = abs(p) / dot(p.xyz,p.xyz);
        d = min(d, p.xyz/p.w);
        p.xyz -= param;
    }
    return d;
}

// same thing as above but also gathers
// distance to light 'bulbs' 
vec4 light=vec4(0.0);
vec3 kali_set_with_light(in vec3 pos, in vec3 param)
{
    vec4 p = vec4(pos, 1.);
    vec3 d = vec3(100.);
    for (int i=0; i<9; ++i)
    {
        p = abs(p) / dot(p.xyz,p.xyz);
        vec3 s = p.xyz/p.w;
        d = min(d, s);
        if (i == 3)
            light = vec4(.5+.5*sin(pos.xzx*vec3(8,9,19)), 
                         length(s.xz)-0.003);
        p.xyz -= param;
    }
    return d;
}

// scene distance
float DE(in vec3 p, in vec3 param)
{
    // floor and ceiling
    float d = min(p.y, -p.y+.2);

    // displaced by kaliset
    d -= kali_set(p*vec3(1,2,1), param).x;
    
    return d;
}

// scene distant with light gathering
float DE_with_light(in vec3 p, in vec3 param)
{
    // floor and ceiling
    float d = min(p.y, -p.y+.2);

    // displaced by kaliset
    d -= kali_set_with_light(p*vec3(1,2,1), param).x;
    
    return d;
}

vec3 DE_norm(in vec3 p, in vec3 param)
{
    vec2 e = vec2(0.0001, 0.);
    return normalize(vec3(
        DE(p+e.xyy, param) - DE(p-e.xyy, param),
        DE(p+e.yxy, param) - DE(p-e.yxy, param),
        DE(p+e.yyx, param) - DE(p-e.yyx, param)));
}

const float max_t = 1.;

// common sphere tracing
// note the check against abs(d) to get closer to surface
// in case of overstepping
vec3 light_accum;
float trace(in vec3 ro, in vec3 rd, in vec3 param)
{
    light_accum = vec3(0.);
    float t = 0.001, d = max_t;
    for (int i=0; i<50; ++i)
    {
        vec3 p = ro + rd * t;
        d = DE_with_light(p, param);
        if (abs(d) <= 0.0001 || t >= max_t)
            break;
        // light accumulation is after break
        // (we are not so much interested in the light's surfaces)
        light_accum += (.2+.4*light.xyz) * max(0., .3 - 6.*light.w) / 3.;
        d = min(d, light.w*.5); // extra fudge for light bulbs
        t += d * .5; // fudge for kali geometry
    }
    return t;
}

// common ambient occlusion
float traceAO(in vec3 ro, in vec3 rd, in vec3 param)
{
    float a = 0., t = 0.01;
    for (int i=0; i<5; ++i)
    {
        float d = DE(ro+t*rd, param);
        a += d / t;
        t += d;
    }
    return min(1., a / 5.);
}

// environment map, 
// background is drawn from kaliset
vec3 skyColor(in vec3 ro, in vec3 rd)
{
    //vec3 par = vec3(0.075, 0.565, .03);
    vec3 par = vec3(1.2, 1.01, .71);
    
    vec3 c = kali_set(rd*2., par);
    c = vec3(.9*c.x,.7,1.)*pow(vec3(c.x),vec3(.7,.5,.5));
    c *= .6;
    
    // some quick tracing of reflected lights
    vec3 lc = vec3(0.);
    float t = 0.001, d = max_t;
    for (int i=0; i<15; ++i)
    {
        vec3 p = ro + rd * t;
        d = DE_with_light(p, vec3(1.));
        if (abs(d) <= 0.0001 || t >= max_t)
            break;
        lc += light.xyz * max(0., .4 - 9.*light.w);
        d = min(d, light.w);
        t += d; // no fudging, artifacts are okay here
    }
    c += .7*min(vec3(1.), lc / (max_t - t));

    return clamp(c, 0., 1.);
}

// trace and color
vec3 rayColor(in vec3 ro, in vec3 rd, in float ti)
{
    // magic params for kali-set
    vec3 par1 = vec3(1.,.7+.6*sin(ti/39.),1.),        // scene geometry 
         par2 = vec3(.63, .55, .73);            // normal/bump map
    
    float t = trace(ro, rd, par1);

    vec3 p = ro + t * rd;
    float d = DE(p, par1);
    
    vec3 col = vec3(0.);

    // did ray hit?
    if (d < 0.03) 
    // note, we always find a surface in this scene except for rays parallel to the 
    // two enclosing planes. The 0.03 is quite large, just to remove the blackness
    // close to edges
    {
        // surface normal
        vec3 n = DE_norm(p, par1);
        // normal displacement
        n = normalize(n + min(p.y+0.05,.02)*DE_norm(p+.1*n, par2));
        n = normalize(n + 0.04*DE_norm(sin(p*30.+n*10.), par2)); // micro-bumps
        // reflected ray
        vec3 rrd = reflect(rd,n);
        // normal towards light
        vec3 ln = normalize(vec3(0.7,0.2,0) - p);
        // 1. - occlusion
        float ao = traceAO(p, n, par1);
        // surface color
        vec3 surf = .1*mix(vec3(1,1.4,1), vec3(3,3,3), ao);

        // lighting
        surf += .25 * ao * max(0., dot(n, ln));
        float d = max(0., dot(rrd, ln));
        surf += ao * (.5 * d + .7 * pow(d, 8.));

        // environment map
        surf += ao * skyColor(ro+0.01*n, rrd);
    
        // distance fog
        col = surf * (1.-t / max_t);
    }
    
    col += light_accum;
    
    return col;
}

// camera path
vec3 path(in float ti)
{
    ti /= 7.;
    vec3 p = vec3(sin(ti)*.5+.5, 
                  .07+.06*sin(ti*3.16), 
                  -.5*cos(ti));
    return p;
}

void main(void)
{
    vec2 suv = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y * 2.;
        
    float ti = time+99.;
    
    vec3 ro = path(ti);
    vec3 look = path(ti+1.+.5*sin(ti/2.3))+vec3(0,.02+.03*sin(ti/5.3),0);
    float turn = sin(ti/6.1); 
        
    // lazily copied from Shane
    // (except the hacky turn param)
    float FOV = 1.6; // FOV - Field of view.
    vec3 fwd = normalize(look-ro);
    vec3 rgt = normalize(vec3(fwd.z, turn, -fwd.x));
    vec3 up = cross(fwd, rgt);
    
    vec3 rd = normalize(fwd + FOV*(uv.x*rgt + uv.y*up));
    
    
    
    //vec3 col = kali_set(vec3(uv, 0.), vec3(1.));
    vec3 col = rayColor(ro, rd, ti);
    
    
    col *= pow(1.-dot(suv-.5,suv-.5)/.5, .6);
    
    glFragColor = vec4(col,1.0);
}
