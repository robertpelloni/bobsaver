#version 420

// original https://www.shadertoy.com/view/WtV3Wt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate2d(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c)*p;
}

float hash(vec2 p) {
    p = fract(p*vec2(46.12, 499.346));
    p += dot(p, 34.42*p);
    return fract(p.x * p.y);
}

vec3 box(vec2 uv, float t) {
    vec2 id = floor(uv);
    float h = hash(id);
    float r = abs(sin(h*t/2.));
    float g = abs(cos(h*t/1.2));
    float b = 0.5*(1.+cos(h*t/1.442));
    return vec3(r, g, b);               
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    float t = time;
    // for the rotations
    float s = sin(t/2.);
    float c = cos(7.+t/1.7);
    vec2 ruv = rotate2d(uv, 2.*c*s);
    // for the translation
    vec2 tuv = ruv+2.*vec2(s,c);
    // for the zoom
    float zoom = 3.*(1.+2.*s*s);
    
    vec3 col = box(tuv*zoom, abs(10.+3.1415*cos(time/2.)));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
