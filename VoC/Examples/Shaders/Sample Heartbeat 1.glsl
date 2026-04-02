#version 420

// original https://neort.io/art/bmjk7pc3p9f7m1g01hrg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec2 N22(vec2 p){
    vec3 a = fract(p.xyx * vec3(123.34, 234.34, 345.65));
    a += dot(a, a + 34.45);
    return fract(vec2(a.x * a.y, a.y * a.z));
}

float line(vec2 p, float col){
    return smoothstep(col - 0.1, col, p.y) - smoothstep(col, col + 0.3, p.y);
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / resolution.y;
    vec3 color = vec3(0.0);
    
    float y = sin(uv.x * 5.0 + (floor(time * 2.0)) + (time * 2.0)) * sin(uv.x * 0.5);
    float pict1 = line(uv, y);
    color += pict1 * vec3(1.0, sin(uv.y * 2.0) + 0.2, 0.5);
    
    vec2 scrollNoise = N22(uv * 0.1) + vec2(fract(time));
    y += sin(uv.x * 18.0) * sin(uv.x * 2.0) / (scrollNoise.x) * 0.1;
    
    float pict2 = line(uv, y);
    color += pict2 * vec3(sin(uv.y * 2.0) + 1.0, 1.0, (sin(time) * 0.5 + 0.5) + 0.75);
    

    glFragColor = vec4(color, 1.0);
}
