#version 420

// original https://www.shadertoy.com/view/DlXSWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float _noise(vec2 uv) {
    // some weird noise
    return fract(1e3*sin(1e3*dot(uv, vec2(1234., 1321.))));
}

vec2 _map(vec2 z, vec2 c, int n) {
    for (int i=0; ++i<n;)
        z = mat2(z, -z.y, z.x) * z + c;
    return z;
}

float sdf(vec2 uv){
    uv = _map(uv, vec2(-.5 - .3*cos(.5*time), .4 + .3*sin(.7*time)), 5);
    
    float c = .08;
    vec2 q = mod(uv + .5*c, c) - .5*c; // repetition of shape
    if (dot(q,q) > c*c*.13)
        return q.y*9.; // background
    
    vec2 m = mod(uv + .5*c, 2.*c) - c; // odd-even coloring
    return sign(m.y);
}

vec3 _colorize(float d){
    return abs(sin(d + .65))*vec3(
        .6 + .4*d,
        .3 - .3*d,
        .6 - .3*d 
    );
}

void main(void)
{
    vec2 uv = .7*gl_FragCoord.xy/resolution.y - vec2(.4, .5);
    float d = sdf(uv);
    vec3 col = _colorize(d) - _noise(uv)*.1;

    glFragColor = vec4(col, 1.);
}
