#version 420

// original https://www.shadertoy.com/view/lXScW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Vibrant by @kishimisu (2024)
 * 
 *       [484 chars]
 */

#define R(a) mat2(cos(a + vec4(0,33,11,0)))

void main(void) {
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);

    vec2    V               = resolution.xy,
              i             = (F+F-V)/V.y;
    float       b           = time * .8,
                  r         = sin(b*.5)*.2+.7,
                    a       , 
                      n     , 
                        t   ;
    
    for (O *= a; a++ < 60.  ;
         O += .06 * (1.  + cos(t*.7 + b + length(i) + vec4(0,1,2,0))) 
                  * (.53 + sin(t+t  + b*4.)*.5) / (.2 + n/.1)) 
    {
        vec3 p = t * normalize(vec3(i * R(b/4.), 1)), q;
        
        p.xz *= R(t*.03);  
        p.z += b; 
        q = p;
        
        p.xy *= R(floor(p.z/.07) * .2 + b*.5);
        p.x = abs(p.x)-.5;
        p.z = mod(p.z, .07) - .035;
        
        t += min(
            n = length(p) - .02, 
            abs(length(vec2(length(mod(q.xy+r,r+r)-r)-.5,p.z))-.02)+.003);
    }
    
    O = tanh(O); // simple tonemapping thanks to Xor
    
    glFragColor=O;
}