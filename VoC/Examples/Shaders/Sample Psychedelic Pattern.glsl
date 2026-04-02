#version 420

// original https://www.shadertoy.com/view/XlcBzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846264338327950
#define TWO_PI PI * 2.0

// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
    vec2 pos = (gl_FragCoord.xy - .5 *resolution.xy) / resolution.y;
    float angle = atan(pos.y, pos.x) / PI;
    float arms = fract(angle * 3.0);
    arms = abs(arms-0.5)*2.0;
    
    float dist = length(pos);
    
    dist = mix(dist,pow(dist,0.5),1.0);
    
    dist -= time*0.1;
    
    float green = sin((dist + arms*0.5) * 20.0)*0.5+0.5;
    green += sin((dist - arms*0.5 + sin(time*0.4)) * 20.0);
    green = clamp(green,0.0,1.0);
    
    float pink = sin((dist - arms*0.5) * 15.0)*0.5+0.5;
    pink += sin((dist + arms*0.5) * 15.0);
    pink = clamp(pink,0.0,1.0);
    
    vec3 color = vec3(0.1,0.05,0.8);
    
    color = mix(color,vec3(1.0,0.2,0.8),pink);
    color = mix(color,vec3(0.2,1.0,0.05),green);
    
    color = rgb2hsv(color);
    color.r += sin(time*0.3);
    color = hsv2rgb(color);

    // Output to screen
    glFragColor = vec4(color,1.0);
}
