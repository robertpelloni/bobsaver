#version 420

// original https://www.shadertoy.com/view/3tjyWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Inspired by Shiny Circle by phil (https://www.shadertoy.com/view/ltBXRc)

float variation(vec2 v1, vec2 v2, float variationStrength) {
 return sin(dot(normalize(v1), normalize(v2))* variationStrength + time * 2.0) / 100.0;
}

mat2 rotate2d(float angle) {
    return mat2(cos(angle), -sin(angle),
                sin(angle),  cos(angle));
}

vec3 paintCircle(vec2 uv, vec2 center, float radius, float width, float variationStrength) {
 
    vec2 diff = center - uv;
    float len = length(diff);
    
    // Make resulting line all wobly by adding some variation based on the dot product of the direction from center with both axis. 
    len += variation(diff, vec2(0.0, 1.0), variationStrength);
    len -= variation(diff, vec2(1.0, 0.0), variationStrength);
    
    
    // Add a circle in the middle
    float circle = smoothstep(radius - width, radius, len);
    // Add a circle on the outside, leaving a white line in the middle between both circles 
    circle -= smoothstep(radius, radius + width, len);
    
    return vec3(circle);
}

vec3 paintOne(vec2 uv, vec2 center, float radius, float variationStrength) {
    
    // Full white circle in the middle
    vec3 col = paintCircle(uv, center, radius, 0.05, variationStrength);
    
    // Add white circle will be outside of the previous one
    col += paintCircle(uv, center, radius, 0.01, variationStrength);
    return col;
}

void main(void)
{
    // hacky way of having this rendered proportionally
    vec2 uv = gl_FragCoord.xy/resolution.xx;
    vec2 center = vec2(0.5, 0.28);
    float radius = 0.15;

    vec3 col = paintOne(uv, center, radius, 5.0);
    col += paintOne(uv, center, radius * 1.2, 0.0);
    
    // Color with gradient that pulses around
    // vec2 v = rotate2d(time) * uv;
    // col *= vec3(v.y, v.x, 0.8 - v.y * v.x);
     col *= 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
