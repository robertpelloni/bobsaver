#version 420

// original https://www.shadertoy.com/view/3sG3Rd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI2 = atan(1.)*8.;
const float minPow = .6;
const float maxPow = 1.5;

void main(void)
{
    vec2 R = resolution.xy;
    vec2 uv = gl_FragCoord.xy/R.xy-.5;
    uv.x *= R.x/R.y;
    uv *= 3.;
    float t = time*.2;
    
    // get radius and angle
    float l = length(uv);
    l = sqrt(l);
    float a = atan(uv.x,uv.y)+sin(l*PI2)*PI2;
    
    // distort uv by length, animated wave over time
    float ex = mix(minPow, maxPow, sin(l*PI2+a+t*PI2)*.5+.5);
    uv = sign(uv)*pow(abs(uv), vec2(ex));
    
    float d = abs(fract(length(uv)-t)-.5);// dist to ring centers
    float c = 1./max(((2.-l)*6.)*d, .1);// dist to grayscale amt
    vec4 o = vec4(c);
    vec3 col = vec3(
        clamp(l*l*l, 0.,1.), // generate correlated colorants 0-1 from length, angle, exponent
        sin(a)*.5+.5,
        (ex-minPow)/(maxPow-minPow));
    //if (mouse*resolution.xy.z <= 0.)
        col = 1.-mix(col, vec3(col.r+col.g+col.b)/3., .8);// desaturate
    o.rgb *= col;
    o *= 1.6-l;// fade edges (vignette)

    glFragColor = o;
}

