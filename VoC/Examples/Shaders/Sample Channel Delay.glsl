#version 420

// original https://www.shadertoy.com/view/NtdSWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float d = .06; // delay
float s1 = .3; // circle size max
float s2 = .1; // circle size min
float r = 1.7; // movement range

float circle (vec2 uv, float size)
{
    float d = length(uv);
    return smoothstep(size + .05, size, d);
}

vec2 move (float di, float t, vec2 m)
{
    float s = sin(t + d * di);
    float c = .85; // cutoff sin
    float b = smoothstep(-c, c, s) * 2. - 1.;
    return vec2(b) * m;
}

float map(float v, float l1, float h1, float l2, float h2)
{
  return l2 + (h2 - l2) * (v - l1) / (h1 - l1);
}

vec2 m = vec2(0., 1.);  
void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;    
    
    vec3 col = vec3(0.);
    float time = time * 2.;

    uv *= 10.;
    vec2 gv = fract(uv) - .5;
    vec2 id = floor(uv) + 1.;
    
    for (float i = -2.; i <= 2.; i++)
    {
        vec2 offs = vec2(0., i);
        vec2 nv = gv + offs;
        vec2 id = id + offs;
        if (mod(id.x, 2.) == 0.) nv.y += .5;
        
        float t = time + id.x * .03; // wave length
        vec2[3] moves = vec2[3](move(0., t, m), move(1., t, m), move(2., t, m));
        
        float shape1 = circle(nv + moves[0] * r, map(abs(moves[0].y), 0., 1., s1, s2));
        float shape2 = circle(nv + moves[1] * r, map(abs(moves[1].y), 0., 1., s1, s2));
        float shape3 = circle(nv + moves[2] * r, map(abs(moves[2].y), 0., 1., s1, s2));

        col += vec3(1., 0., 0.) * shape1;
        col += vec3(0., 1., 0.) * shape2;
        col += vec3(0., 0., 1.) * shape3;
    }

    col = 1. - col; // invert    
    glFragColor = vec4(col,1.0);
}
