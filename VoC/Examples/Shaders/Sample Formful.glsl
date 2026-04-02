#version 420

// original https://www.shadertoy.com/view/wtdBWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Formful by Kristian Sivonen (ruojake)
// CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)

mat2 rot(float a)
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float box(in vec4 p, in vec4 b)
{
  vec4 d = abs(p) - b;
  return length(max(d, 0.)) + min(max(d.x, max(d.y, max(d.z, d.w))), 0.);
}

float scene(in vec3 p)
{
    vec4 q = vec4(p, sin(dot(p.xz * 3., -p.yz) * .125 + time * .25) * .4);
    q -= vec4(0,0,4,0);
    float t = time * .0625;
    q.xw *= rot(t);
    q.yw *= rot(t*3.+q.w*.9);
    q.zw *= rot(t*7.-q.w*.5);
    q.xz *= rot(t*5.+q.y*.7);
      
    return box(q, vec4(1,2,1.5,.5)) * .5 - .2;
}

vec3 normal(vec3 p)
{
    float d = scene(p);
    vec2 e = vec2(.002, .0);
    return normalize(d - vec3(
        scene(p - e.xyy),
        scene(p - e.yxy),
        scene(p - e.yyx)));
}

vec3 dither(vec2 p)
{
    float r = dot(vec3(p,floor(fract(time * 60.) * 60.)), vec3(7., 11., 9.) / 13.);
    return fract(vec3(r, r + .3334, r + .6667)) * 2. - 1.;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;

    vec3 ro = vec3(0);
    vec3 rd = normalize(vec3(uv, .5));
    float t = 2.;
    vec3 p;
    float i = 0.;
    
    for(; i < 1. && t < 10.; i += .01)
    {
        p = ro + rd * t;
        float d = scene(p);
        t += d * .75;
        if (abs(d) < .001) break;
    }

    vec3 col = vec3(0);
    if (t >= 10.)
    {
        col = vec3(.15 + uv.y * -.15, .35, .6) + smoothstep(.1, .8, i);
    }
    else
    {
        vec3 n = normal(p);
        float refl = clamp(reflect(vec3(0, -1, 0), n).y, 0., 1.) * step(0., n.y);   
        float l = n.y * .4 + .7;
        vec3 ao = mix(vec3(1), vec3(.3, .6, 1.), i);
        col = vec3(pow(refl,2.) * 4. + pow(l, 3.) * 1.5 * ao * mix(vec3(.35, .8, 0.), vec3(1., 1., .9), refl + pow(l,8.)));
    }
     
    col = col * (1. + col / 9.) / (1. + col);
    col = pow(col, vec3(1. / 2.2));

    glFragColor = vec4(col.rgb + dither(gl_FragCoord.xy) / 253., 1.0);
}
