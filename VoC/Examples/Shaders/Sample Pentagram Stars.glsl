#version 420

// original https://www.shadertoy.com/view/X3cXWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float N21(vec2 p) {
    vec3 a = fract(vec3(p.xyx) * vec3(213.897, 653.453, 253.098));
    a += dot(a, a.yzx + 79.76);
    return fract((a.x + a.y) * a.z);
}

mat2 Rotate(float angle) {
    float s = sin(angle), c = cos(angle);
    return mat2(c, s, s, -c);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy ) / resolution.y;

    uv = uv * 18.0;

    vec2 gu = fract(uv)-.5;
    
    vec3 col = vec3(0);
    
    float w = fwidth(uv.y);
    
    vec2 id = floor(uv);
    
    float pi2 = radians(360.0);

    float a1 = pi2 / 5.0;
    float a2 = a1 * 2.0;
    float a3 = a1 * 3.0;

    for(int y=-1;y<=1;y++) {
        for(int x=-1;x<=1;x++) {
            vec2 offs = vec2(x, y);
            vec2 guv = gu;
            float index = N21(id + offs);

            vec3 color = vec3(index, fract(index*34.32), fract(index*123.353));

            vec2 posOffset = vec2(index, fract(index * 2424.852)) - vec2(0.5);

            guv -= offs - posOffset;

            guv *= Rotate(time * sign(index - 0.9) * 2.0);

            guv.x = abs(guv.x);

            float d0 = dot(guv, vec2(0.0, 1.0));
            float d1 = dot(guv, vec2(sin(a1), cos(a1)));
            float d2 = dot(guv, vec2(sin(a2), cos(a2)));
            float d3 = dot(guv, vec2(sin(a3), cos(a3)));

            float d = min(max(d1, d3), max(d0, d2));

            float size = sin(time * (index - 0.5) * 10.0) * 0.25 * index;

            col += color * vec3(smoothstep(w, -w, d - size));
        }
    }
    

    glFragColor = vec4(col,1.0);
}
