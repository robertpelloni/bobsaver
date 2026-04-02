#version 420

// original https://www.shadertoy.com/view/MtXyWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float drawCircle(vec2 uv, vec2 p, float r, float blur) {
    return smoothstep(r, r-blur, length(uv - p));
}

float drawGuide(vec2 uv, vec2 pos, float r, float blur) {
    float halfblur = blur * 0.5;
    float outer = drawCircle(uv, pos, r+halfblur, blur);
    float inner = drawCircle(uv, pos, r-halfblur, blur);
    return outer - inner;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy / resolution.xy);
    float ratio = resolution.x/resolution.y;
    uv.x *= ratio;
    
    float size = 0.015;
    float radius = 0.09;
    float speed = 3.0;
    float blur = 0.005;
    float amplitude = 4.0;
    float spacing = 0.1;
    
    float circles = 0.0;
    float guides = 0.0;
    
    for (float i=0.0; i<2.01; i=i+spacing) {
        for (float j=0.0; j<1.01; j=j+spacing) {
            
            vec2 offset = vec2(i, j);
            guides += drawGuide(uv, offset, radius, blur);

            float phase = (i + j) * amplitude;
            float factor = (time * speed) + phase;
            vec2 pos = (vec2(cos(factor), sin(factor)) * radius) + offset;
            circles += drawCircle(uv, pos, size, blur);

        };
    };
    vec3 guides_out = vec3(0.2, 0.2, 0.2) * guides;
    vec3 circles_out = vec3(1.0, 1.0, 1.0) * circles;

    glFragColor = vec4(circles_out + guides_out, 1.0);
}
