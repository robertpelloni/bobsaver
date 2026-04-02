#version 420

// original https://www.shadertoy.com/view/wdjGRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159;

void main(void)
{
    // Generate world UVs
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = (uv - 0.5);
    float aspect = resolution.x / resolution.y;
    uv.x *= aspect;
    uv.y -= 0.2;    // Displace the uv to center the heart
    

    float a = atan(uv.x,uv.y) / PI;     // angle
    float r = length(vec2(uv.x,uv.y));  // radius
    
    float duration = 1.75;
    float t = pow(mod(time, duration)/duration, 0.85);
    float tanim = sin(t*PI*10.0) * exp(1.0 - t*4.0);
    float global_scale = 0.75;
    float d = global_scale *
                (0.2
               + 0.6 * abs(a)                     // main
               - (0.1 - tanim*0.0125) * cos(abs(a) * PI * 2.0)     // wide
               + (0.05 + tanim*0.025) * pow(abs(a), 20.0)         // bottom
               - step(0.0, a) * 0.075 * sin(a*PI)  // reduce right side
                );

    float light_pos = length(vec2(uv.x - 0.35, uv.y + 0.25));
    vec3 heart_color = vec3(0.1, 0.0, 0.15) + vec3(pow(min(d,0.15),light_pos), 0, 0);
    vec3 background = vec3(0.85, 0.75, 0.65) * (1.5 -r);
    float is_heart = smoothstep(d, d+fwidth(r)*2.0, r);
    vec3 color = mix(heart_color, background, is_heart);

    // Output to screen
    glFragColor = vec4(color,1.0);
}
