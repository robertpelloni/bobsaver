#version 420

// original https://www.shadertoy.com/view/dsVfzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define f(z) cos(z * vec2(.6, .5) - vec2(33, 0))
#define h(z) f(z) + .2 * cos(z * vec2(.8, 1.7))
#define k(z) 5.5 * cos((z + 1.57) - vec2(33, 0)) + vec2(0, 4.5)
#define g(z) cos(vec2(33, 0)) * 3. + vec2(0, 2.5)

/* acompanhante veio lá da panacota: 
        https://www.shadertoy.com/view/cljfRc
    */

void main(void) {
    vec4 o = vec4(0.0);
    vec2 u = gl_FragCoord.xy;
    
    float w, i, dd, d, 
          gyr, red, oliv, flagel, 
          a, t = time * 3.;
          
    vec3 p, r = vec3(resolution.xy,1.0);
    o *= .0;
    u = (u - r.xy / 2.) / r.y;

    while (i++ < 180.)
        p.z = a + t,
        p.xy = (u * a + f(p.z) - f(t) - vec2(0, 4.5)),
        
        gyr = abs((dot(cos(p), sin(p.yzx)) + 1.1) / 5.) + .001,
        
        w = cos(t * .3) * 7. + 7.,
        p.xy = (u * a + h(p.z) - h(t) - vec2(0, 4.5)),
        oliv = length(vec3(p.xy + g(p.z), a - w)) / 2. - .3,
        
        flagel = max(length(p.xy + g(p.z)) / 2. - .04, -t + p.z - w),
        
        red = length(vec3(p.xy + k(p.z), a / 2. - 4. + cos(t * .07) * 6.)) / 4. - .6,
        
        
        a += d = min(gyr, min(oliv, min(flagel, red))),
        
        
        o.r += step(red, gyr) * .005,
        o.g += step(oliv, gyr) * .02,
        o += ( ( abs(
                     mod(vec4(6, 4, 2, 0) + p.z * 8., 6.) - 3.
                 ) - 1.
               ) * .06 + step(gyr, red) * .4
             ) / 1e2 / exp(30. * d);

    o *= o - length(u) / 2.;
    glFragColor = o;
}