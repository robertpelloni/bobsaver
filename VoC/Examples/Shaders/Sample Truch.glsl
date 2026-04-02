#version 420

// original https://www.shadertoy.com/view/mlVcW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    "Truch" by @XorDev
    
    Experiments with truchets in 3D.
    
    Based on Truchet Blobs: shadertoy.com/view/Nljyzh
    Inspired by @kamoshika_vrc: X.com/kamoshika_vrc
    
    X: X.com/XorDev/status/1725373145597485150
    Twigl: twigl.app/?ol=true&ss=-NjQ_-41acvGMZ5Aj9Ib
    
    <512 chars playlist: https://www.shadertoy.com/playlist/N3SyzR
    -5 Thanks to FabriceNeyret2
*/
void main(void)
{
    vec4 O = vec4(0.0);
    vec2 I = gl_FragCoord.xy;
    
    //Iterator, raymarch step size and total marched distance.
    float i,s,T;
    //Raymarch loop (clear fragcolor, loop 100 times and add shading using SDF)
    for( O*=i ; i++<1e2 ; O += 1e-3/(.1-s) )
    {
        //Resolution for scaling
        vec3 r = vec3(resolution.xy,1.0),
        //Compute projected sample position with matrix for rotation
        p = vec3( (I+I-r.xy)/r.x *T ,T-90. )*.1 * mat3(1,-1,5, 6,0,2, 0,5,4),
        //Polar/log coordinates
        P = vec3( atan(p.z,p.y)*.95, time - log(s=length(p)*.1) , 0 ) *3.,
        //Cell coordinates
        c = ceil(P),
        //This flips the sign of cells in a checkerboard pattern
        //and then pseudo-randomly flips the x sign
        S = cos(ceil( cos(c-c.y) *(c+c.x) )*acos(-1.));
        //Marches forward, computing the truchet SDF
        T -= s = clamp( ( .5 - length( min(P=fract(P*S), 1.-P.yxz) ) ) *S*s , p-5. , p ).x;
    }
    glFragColor=O;
}
