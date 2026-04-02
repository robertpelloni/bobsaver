#version 420

// original https://www.shadertoy.com/view/XlsSW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(in vec2 uv)
{
    float ang = atan(uv.x,uv.y);
    float l = length(uv);
    uv.x = l*cos(time + ang);    
    uv.y = l*sin(time + ang);

    uv = mod(-3.*sin(0.1*time)*uv+vec2(time*2.,time*2.),1.0);
    uv -= .5;
    
    uv *= length(uv) * 120. * (1.0 + .25 * fract(time));
    float t = atan(uv.x,uv.y);
    vec2 p;
    p.x = 16. * sin(t);
    p.y = 13. * cos(t) - 5.*cos(2.*t)-2.*cos(3.*t)-cos(4.*t);
    return (1.0/((length(p)-length(uv))*3.0 ));
 }

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - vec2(.5,.5);
    uv. x *= resolution.x / resolution.y;
    vec2 pixelsize = 1.0 / resolution.xy;
    
    vec3 o = vec3(uv.x,map(uv),uv.y);
    
    vec3 nx = o;
    nx.x += pixelsize.x;
    nx.y = map(nx.xz);
    nx.x = o.x + 1.0;
    nx = normalize(nx - o);

    vec3 nz = o;
    nz.z += pixelsize.y;
    nz.y = map(nz.xz);
    nz.z = o.z + 1.0;
    nz = normalize(nz - o);

    vec3 normal = cross(nz,nx);

    vec3 lightLoc = vec3(
        mouse.x*resolution.x/ resolution.x - .5,
        .4,
        mouse.y*resolution.y/ resolution.y - .5);
    vec3 lightVec = normalize(lightLoc - o);

    glFragColor = 
        vec4(o.y > 0. ? 0.9 : 0., o.y < 0. ? 0.4 : 0. , o.y < 0. ? 0.7 : 0.,0.0) * 
        dot(normal,lightVec) / length(lightLoc - o);
}
