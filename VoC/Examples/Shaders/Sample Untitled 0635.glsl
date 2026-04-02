#version 420

// original https://www.shadertoy.com/view/fsS3RV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.14159;

void main(void)
{

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

vec2 dir = uv - 0.5;
float d = 4. * length(dir);
float theta = atan(dir.y,dir.x);

float val = 1.- cos(theta - 0.2 * time + 0.5 *cos(3. * theta + 0.5 *time));
float val2 = 1.- cos(theta - 0.2 * time + 2. * pi / 3. + 0.5 * cos(3. * theta + 0.5 * time + 2. * pi / 3.));
float val3 = 1. -cos(theta - 0.2 * time + 4. * pi/3. + 0.5 * cos(3. * theta + 0.5 * time + 4. * pi / 3.));

    // Time varying pixel color
    vec3 col = vec3(smoothstep(d,val,sqrt(val2 * val2 + val3 * val3)),
    smoothstep(d,val2,sqrt(val * val + val3 * val3)),
    smoothstep(d,val3,sqrt(val2 * val2 + val * val)));
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
