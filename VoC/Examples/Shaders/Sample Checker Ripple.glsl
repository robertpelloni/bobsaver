#version 420

// original https://neort.io/art/c9ep08c3p9f0i94dmah0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 latticeTex(vec2 uv){
    vec3 col = vec3(0.0);
    float checker = mod(floor(uv.x) + floor(uv.y), 2.0);

    col += checker;
    return col;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    color += latticeTex((uv - vec2(time * 0.4, 0.0)) * 10.0);
    color = mix(color, latticeTex((uv + vec2(time * 0.4, 0.0)) * 4.0), vec3(step((sin(length(uv) * 10.0 - time * 4.0) + 1.0) * 0.5, 0.5)));

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
