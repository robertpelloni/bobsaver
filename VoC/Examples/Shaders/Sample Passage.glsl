#version 420

// original https://www.shadertoy.com/view/mlKyRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    "Passage" by @XorDev
    
    X: X.com/XorDev/status/1726396476866044130
    Twigl: twigl.app?ol=true&ss=-Nje8mOER98sqMpHsal-
    
    <512 chars playlist: https://www.shadertoy.com/playlist/N3SyzR
    -10 Thanks to FabriceNeyret2
    -8 Thanks to lluic
*/

void main(void)
{
    vec4 O = vec4(0.0);
    vec2 I = gl_FragCoord.xy;
    
    //Clear fragcolor
    O *= 0.;
    
    //Raymarch loop:
    //iterator, step-size, raymarch distance, Tau
    //Raymarchs 100 times adding brightness when close to a surface
    for(float i,s,d,T=6.283; i++<1e2; O+=1e-5/(.001-s))
    {
        //Rotation matrix
        mat2 R = mat2(8,6,-6,8)*.1;
        //Resolution for scaling
        vec3 r = vec3(resolution.xy,1.0),
        //Project sample with roll rotation and distance
        p = vec3((I+I-r.xy)/r.x*d*R, d-9.)*.7;
        //Rotate pitch
        p.yz *= R;
        //Step forward (negative for code golfing reasons)
        d -= s = min(p.z, cos(dot(
            //Compute subcell coordinates
            modf(fract((
            //Using polar-log coordinates
            vec2(atan(p.y,p.x),log(s=length(p.xy)))/T-time/2e1)*
            //Rotate 45 degrees and scale repetition
            mat2(p/p,-1))*15., p.xy),
        //Randomly flip cells and correct for scaling
        sign(cos(p.xy+p.y)))*T)*s/4e1);
    }
    
    glFragColor = O;
}