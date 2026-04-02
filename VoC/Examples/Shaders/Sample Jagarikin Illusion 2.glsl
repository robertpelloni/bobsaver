#version 420

// original https://www.shadertoy.com/view/3lByzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// Highly inspired by the work of Jagarikin
// https://twitter.com/jagarikin
//
// 
//

#define DELAY .1
#define PI 3.1415927
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

// @author Fabrice Neyret 
// https://www.shadertoy.com/view/MtG3Wh
// His color interpolation just works so well with this illusion !
vec3 rainbow (float h) {
    vec4 O = mod(vec4(1,2,3,0)-3.*h, 3.); O = min(O,2.-O);     // linear rainbow
      O = .5+.5*cos(6.283185*(h +vec4(0,1,-1,0)/3.));       // 1/j/j² rainbow 
    //O = pow(max(O,0.),vec4(1./2.2));        // gamma correction
    return O.rgb;
}

void main(void)
{
    float T = time * .1;
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)  / resolution.y;
    uv*= 3.;
    
    
    float L = length(uv);
    float An = atan(uv.y, uv.x)*10. + sin(L*(clamp(cos(T*2.), -.2, .2)-.2)*10.)*5.;
    float B = mod(An, 2.*PI) / (2.*PI) - .5;
    vec2 id = vec2(floor(abs(An)/(PI*2.) - .5), floor((L-.5)*3.));
    float S = cos(An) * .5 + .5;
    
    float C = smoothstep(.7, .8, S);
    float Lt = smoothstep(.6, .62, S) - C;
    
    float A = step(abs(cos(L*10.)), .5);
    C*= A;
    Lt*= A;
    
    T*=  10.;
    T+= (-id.y * .08 + id.x * (.08 + cos(time*.1)*.05)) * min(time/60., 1.);
    vec3 cC = rainbow(T);
    vec3 cLt = rainbow(T + DELAY*sign(B));

    vec3 col = vec3(.5);
    
    col = mix(col, cC, C);
    col = mix(col, cLt, Lt);

    
    glFragColor = vec4(col,1.0);
}
