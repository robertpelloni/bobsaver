#version 420

// original https://www.shadertoy.com/view/43scRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SmoothBump(hi, lo, w, x) \
    smoothstep(w, -w, abs(x - (hi + lo) / 2.) - (hi - lo) / 2.) 

#define h21(p) fract(sin(dot(p, vec2(12.34,26.534))) * 987.23)
#define r resolution.xy
#define t time
#define pi acos(-1.)
#define TAU (2.* pi)

float truchet(vec2 p, bool coin1, bool coin2){
    p.y *= coin1 ? 1. : -1.;
    
    float a = SmoothBump(4., 1.5, .05, acos(cos(t * .3))) * .1,
          d = smoothstep(.4, .6, 
                  min(
                     length(p + .5), 
                     length(p - .5)
                  ) - a
              );
    
    return coin1 ^^ coin2 ?  1. - d :  d;
}
            
void main(void) {
    vec4 o = vec4(0.0);
    vec2 u = gl_FragCoord.xy;
    
    float T = SmoothBump(4., 2.5, .4, acos(cos(t * .5)));
          
    u = 4. * (u - r / 2.) / r.y 
            + vec2(mix(0., 5., T), 0);
            
    u = mix(
            vec2(
                log(length(u)), 
                atan(u.y, u.x)
            ), u,
            T
        );
    
    u = 12. * fract((u - t * .5) / TAU); 
        
    vec2 q = floor(u) / 2.;
         u = fract(u) - .5;
    
    bool coin1 = h21(q) < .5,
         coin2 = fract(q.y + q.x) * 2. < .5;
    
    o = smoothstep(30. / r.y, .0, 
               truchet(u, coin1, coin2)
           )  * vec4(.75) + .25;
    
    //if(mouse*resolution.xy.z > 0.)
    //    T = smoothstep(30. / r.y, .0, max(abs(u.x), abs(u.y)) - .4),
    //    o = mix(o, vec4(T), 1. - T);
    
    glFragColor = o;
}