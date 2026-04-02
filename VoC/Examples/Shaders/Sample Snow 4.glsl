#version 420

// original https://www.shadertoy.com/view/wt3GWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

float ball(vec2 p) {
    float size = .05;
    float d = distance(vec2(.5), p);
    return smoothstep(size,size - .05, d);
}

float N11(float n) {
    return fract(sin(n * 871.213) * 3134.422);
}

float N21(vec2 uv) {
    return N11(N11(uv.x) + uv.y);
}

float snow(vec2 uv, float t) {
    vec2 org_uv = vec2(uv.x, uv.y);
    float z = 10.;
    uv.y += t * .5;
    vec2 gv = fract(uv*z);
    vec2 id = floor(uv*z); 
    gv.x += (sin(N21(id) * 128. + t) * .4);
    gv.y += (sin(N11(N21(id)) * 128. + t) * .4);
    // float size = graph(org_uv);
    float dots = ball(gv);
    return dots;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x / resolution.y;
    float t = time * .3;
    
    vec2 gh_uv = uv;
    
    // Time varying pixel color
    vec3 col = vec3(0.);
    
    float m = 0.;
    
    for(float i =0.; i <= 1.; i += 1. / 32.) {
        float z = mix(1., .5 , i);
        vec2 offset = vec2(N11(i), N11(N11(i)));
        m += snow((uv + offset) * z, t) * .3;
    }
    
    
    col = vec3(m);
    col += vec3(.85, .90, 1.) *.8 * mix(.5, 1., uv.y);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
