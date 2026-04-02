#version 420

// original https://www.shadertoy.com/view/dljyDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926

float Length(vec2 p, float k)
{
    p = abs(p);
    return pow(pow(p.x, k) + pow(p.y, k), 1./k);
}

float Hash21(vec2 p)
{
    p = fract(p * vec2(195.746, 342.895));
    p += dot(p, p + 218.327);
    return fract(p.x * p.y);
}

float Truchet(vec2 p, float powK, float thickness, float pattern)
{
    vec2 id = floor(p);
    p = fract(p) - .5;
    
    float d = 0.;
    float result = 1.;
    
    if(Hash21(id) < .5) p.x *= -1.;
    
    float s = p.x > -p.y ? 1. : -1.;
    
    vec2 cp = p - vec2(.5, .5) * s; // Center position
    float centerDist = Length(cp, powK);
    
    float w = .005; // Blur
    float edgeDist = abs(centerDist - .5) - thickness;
    result *= smoothstep(w, -w, edgeDist);
    
    float arcT = atan(cp.x, cp.y);
    result *= smoothstep(-.3, .8, sin(PI * .5 + arcT * 2.) *.5 + .5);
    
    float check = mod(id.x + id.y, 2.) * 2. - 1.;
    result *= 1. + sin(check * arcT * 30. + edgeDist * 100. - time * 5.) * .3 * pattern;
    
    // if(p.x > .49 || p.y > .49) col += 1.;
    
    return result;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy -.5*resolution.xy ) / resolution.y;

    float cd = Length(uv, 1.5);
    float w = mix(0.1, .007, smoothstep(0.01, 0.6, cd));
    
    uv *= 1.8 * (sin(time) + 2.);

    uv += vec2(.5) * (vec2(time) - mouse*resolution.xy.xy * 5. / resolution.xy);    

    float t1 = Truchet(uv, 2., w, 1.);
    float t2 = Truchet(uv + .5, 1., .08 - w * .5, .0);
    float t3 = Truchet(uv - .25, 3., .03, .5) * sin(time + cd * 15.);
    
    vec3 col = t1 * vec3(1., .8, .8) + 
               (t2 > t1 ? vec3(.8, 1., .8) : vec3(0.)) +
               t3 * vec3(.8, .8, 1.);

    // Output to screen
    glFragColor = vec4(col.rgb, 1.0);
}
