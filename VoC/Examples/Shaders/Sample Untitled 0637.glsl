#version 420

// original https://www.shadertoy.com/view/fsjGz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.14159;
const float pi2 = 2. * pi / 3.;
const float pi3 = 4. * pi / 3.;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
vec2 dir = uv.xy +  (0.21 * (cos(time)) + 0.05 * cos(0.15 *time)) * cos(3. * uv.xx +0.05 *  time) - 0.5;
dir *= 2.;

float e = 4. * length(dir);
float d = 0.5 * (1. / e + e);
float theta = atan( dir.y,dir.x);

float b = 0.5 + 0.5 * cos(time);
float t= 0.5 * time;
float t2 = 0.5 * time + pi2;
float t3 = 0.5 * time + pi3;

float p = cos(uv.x - 0.5 + 0.5 * cos(2. * t + theta)) * cos(uv.y - 0.5 + 0.5 * cos(t));
float p2 = cos(uv.x - 0.5 + 0.5 * cos(2. * t2 + theta)) * cos(uv.y - 0.5 + 0.5 * cos(t2));
float p3 = cos(uv.x - 0.5 + 0.5 * cos(2. * t3 + theta)) * cos(uv.y - 0.5 + 0.5 * cos(t2));
float val = max(1. - p,p * p2);
float val2 = max(1. -p2,p2 * p3);
float val3 = max(1. -p3,p3 * p);

    // Time varying pixel color
    vec3 col = 1. - vec3(
    smoothstep(val + val2, d, d * sqrt(val * val + val3 * val3)),
    smoothstep(val2 + val3, d, d * sqrt(val2 * val2 + val * val)),
    smoothstep(val3 + val, d, d * sqrt(val3 * val3 + val2 * val2)));
    
    vec3 col2 = 1. - vec3(0.2126* col.x + 0.7152 * col.y + 0.0722 * col.z);
    //col2 = vec3(step(col.x,b));
    col = 1. - min(col,0.58 *  sqrt( 1. - col * col + col2 * col2));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
