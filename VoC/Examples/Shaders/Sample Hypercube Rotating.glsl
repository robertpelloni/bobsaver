#version 420

// original https://www.shadertoy.com/view/cdy3zt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 project4Dto2D(vec4 pos, float distance, float scale3D) {
    vec3 pos3D = pos.xyz * scale3D / (pos.w + distance);
    return pos3D.xy / (pos3D.z + distance);
}

void drawLine(vec2 uv, vec2 start, vec2 end, vec3 color, inout vec3 o) {
    vec2 p1 = start.xy;
    vec2 p2 = end.xy;
    float lineWidth = 0.05 / (1.0 + 10.0);
    
    float t = clamp((dot(uv - p1, p2 - p1) / dot(p2 - p1, p2 - p1)), 0.0, 1.0);
    float d = length(uv - (p1 + t * (p2 - p1)));
    
    o += color * smoothstep(lineWidth, 0.0, d);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    float time = time * 0.5;
    float aspectRatio = resolution.x / resolution.y;
    
    mat4 rotationXY = mat4(
        cos(time), -sin(time), 0, 0,
        sin(time), cos(time), 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    );
    
    mat4 rotationYZ = mat4(
        1, 0, 0, 0,
        0, cos(time), -sin(time), 0,
        0, sin(time), cos(time), 0,
        0, 0, 0, 1
    );
    
    mat4 rotationZW = mat4(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, cos(time), -sin(time),
        0, 0, sin(time), cos(time)
    );
    
    mat4 totalTransform = rotationXY * rotationYZ * rotationZW;
    
    float scale = 0.5;
    float distance = 2.5;
    vec3 color = vec3(0.5, 0.5, 1.0);
    vec3 o = vec3(0.0);
    
    for (int i = 0; i < 16; i++) {
        for (int j = i + 1; j < 16; j++) {
            if ((i ^ j) == 1 || (i ^ j) == 2 || (i ^ j) == 4 || (i ^ j) == 8) {
                vec4 v1 = vec4(float((i & 1) * 2 - 1) * scale, float((i & 2) - 1) * scale, float((i & 4) / 2 - 1) * scale, float((i & 8) / 4 - 1) * scale);
                vec4 v2 = vec4(float((j & 1) * 2 - 1) * scale, float((j & 2) - 1) * scale, float((j & 4) / 2 - 1) * scale, float((j & 8) / 4 - 1) * scale);
                v1 = totalTransform * v1;
                v2 = totalTransform * v2;
                vec2 p1 = project4Dto2D(v1, distance, 2.00);
                vec2 p2 = project4Dto2D(v2, distance, 2.00);
                p1.xy *= vec2(1.0, aspectRatio);
                p2.xy *= vec2(1.0, aspectRatio);

            drawLine(uv, p1, p2, color, o);
            }
        }
    }

glFragColor = vec4(o, 1.0);
}
