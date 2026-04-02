#version 420

// -----------------------------------------------------
// findings by nabr
// License Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)
// https://creativecommons.org/licenses/by-nc/4.0/
// -----------------------------------------------------

uniform float time;
uniform vec2 mouse, resolution;

out vec4 glFragColor;

float f(vec2 pp)
{
 //   if (abs(pp.y) > .5)return 0.;
    pp.y *= dot(pp,pp)*4.41;
    vec3 ht = smoothstep(0., 3., .25 - dot(pp, pp)) * vec3(pp, 10.),
         n = 400. * normalize(-ht - vec3(.001, .002, 1)), p = n;
    float tm = 1.35 * time;
    for (float i = 5.; i <= 8.; i++)
    {
        p = 9. * n + vec3(cos(tm + i - p.x*0.4) + cos(tm + i - p.y), sin(i - p.y) + cos(i + p.x), 1);
        p.xy = n.yz + (cos(i) * p.xy + sin(i) * abs(vec2(p.y, -p.x)));
    }
    return (dot(vec3(6, -1, 1000), -p));
}
void main()
{
    vec2 p = 1.25 * (gl_FragCoord.xy - .5 * resolution) / min(resolution.x, resolution.y);
    if(abs(p.x) > .5)discard;
    else if(abs(p.y) > .5){glFragColor = vec4(.25, 0, 0, 1);return;}
    const vec2 e = vec2(.002, .0025);
    vec3 sn = normalize(vec3(f(p + e) - f(p - e), f(p + e.yx) - f(p - e.yx), -.8));
    glFragColor = vec4(.95 - vec3(clamp(dot(-normalize(1. - length(p - vec2(sin(time), cos(time)))+ vec3(2. * p, 3)),sn),.05, .9)),1);
}
