#version 420

// original https://www.shadertoy.com/view/3tByRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// Very highly inspired by the work of Jagarikin 
// https://twitter.com/jagarikin
//
// I basically took his concept to understand how it could be implemented, before going into
// further exploration. Please go check his work if you liked this one !
//
// From my understanding, the illusion of a motion comes from the shift in hue being applied
// width a small offset on the borders. The brain was trained in extracting motion using the
// colors, because usually in real life objects do not tend to change color, therefore a 
// change in color at a particular point is often due to a motion at the point. When an object
// moves, a color on its surface is supposed to follow the motion of the object in the world 
// referential.
//
// I took the rainbow color interpolation from Fabrice Neyret 
// https://www.shadertoy.com/view/MtG3Wh
// The color transitions are just so smooth and work so well in this context. Thanks to him !
//

#define PI 3.14159265359
#define DELAY 0.17
#define SIZE 0.15
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

// some sort of lerp r g b r
// looks bad
vec3 hsv2rgb(float h)
{
    h = mod(h, 1.);
    vec3 c1 = vec3(1,0,0);
    vec3 c2 = vec3(0,1,0);
    vec3 c3 = vec3(0,0,1);
    return h < .33 ? mix(c1, c2, h/.33) : 
        h < .66 ? mix(c2, c3, (h-.33)/.33)
        : mix(c3, c1, (h-.66)/.33);
}

void main(void)
{
    // time
    float t = time * .9;
    
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)  / resolution.y;
    uv*= resolution.y * .01;
    vec2 id = floor(uv);
    uv = fract(uv) - .5;
    uv*= rot(clamp(cos(t*.3), -.2, .2)/.2*PI*.25+ id.x*id.y);
    // square
    vec2 s = smoothstep(SIZE, SIZE-0.01, abs(uv));
    float sq =  s.x * s.y;
    
    float hueShift = (id.x*id.y)*.04 * pow(min(1., time/60.), 3.5);
    
    // left border
    s = smoothstep(SIZE, SIZE-0.01, abs(uv + vec2(.03, 0)));
    float lf = min(s.x * s.y, 1.-sq);
    float lfH = t + DELAY + hueShift;
    vec3 lfC = rainbow(lfH);
    
    // right border
    s = smoothstep(SIZE, SIZE-0.01, abs(uv - vec2(.03, 0)));
    float rt = min(s.x * s.y, 1.-sq);
    float rtH = t - DELAY + hueShift;
    vec3 rtC = rainbow(rtH);
    
    float ch = t + hueShift;
    vec3 c = rainbow(ch);
    

    vec3 col = vec3(.5);
    
    col = mix(col, c, sq);
    col = mix(col, lfC, lf);
    col = mix(col, rtC, rt);

    glFragColor = vec4(col, 1);
}
