#version 420

// original https://www.shadertoy.com/view/WlsSDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//235 char without animation https://www.shadertoy.com/view/3lsSDl

void main(void) //WARNING - variables void ( out vec4 z, vec2 b ) need changing to glFragColor and gl_FragCoord
{
    vec4 z = glFragColor;
    vec2 b = gl_FragCoord.xy;

    vec2 A,B,C  ,E,G;
    float d,k = .0; // turning z.a into d + introducing snake k => cost 7 chars
    z -= z;
    A=B=C -= C;
    b /= 6e2; // b /= 2.*resolution.y;
    B.x = 1.7; // 1.7320 // sqrt(3)
    C.y = 1.;
    for(int i = 0 ; i < 11 ; i++, k *= 3.)
        G = b - A - B,
        E = B + B - A,
        d = dot(G,E)/length(G)/length(E),
        // find approximation of distance ?!
        // would let me optimize G and E expression after
        // ACD Triangle : cos(angle) < -1/2 = COS(2PI/3)
        A =   d < -.5
            ?  A // ACD => A stays the same 
        
            : (k++, // k += 2 for EBD, k++ for ECD
               B + C) // was previously temporary E
        ,
        // EBD Triangle : cos(angle) > 1/2 = COS( PI/3)
        B =   d > .5
            ?  
             k++,B // => EBD B stays the same
                
            : C
        ,
        
        // G = b - (A+B) => A+B = b - G  saves 2 chars
        C = (b-G)/3.;
    //}       
    
    k/=2e3;
    z = tanh( cos( time + vec4(11,9,7,1)*k ) / sin(time-d*.6+k) );

    glFragColor = z;
    
    
}
