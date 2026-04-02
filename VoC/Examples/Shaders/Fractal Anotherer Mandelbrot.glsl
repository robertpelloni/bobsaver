#version 420

// original https://www.shadertoy.com/view/tds3R7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float steps = 128.0;

void main(void)
{
    float scale = 2.0/resolution.y;
    vec2 res = resolution.xy * scale;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy * scale * 4.0 - 2.0 * res)/((sin(time * 0.35) * 5.0 + 7.0) * res.y);
    uv += vec2(-0.745428,  0.113009);
    
    vec3 ld1 = normalize(vec3(cos(time * 0.7237897), sin(time * 0.7237897), 0.75));
    vec3 ld2 = normalize(vec3(sin(time * 0.9237897), cos(time * 0.9237897), 0.25));

    vec2 z = vec2(0.0);
    vec3 nrm = vec3(0.0);
    
    float i = 0.0;
    for (; i < steps; ++i) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y);
        z += uv;
        
        if (z.x * z.x + z.y * z.y > 4.0) {
            break;
        }
        
        nrm += vec3(z.xy, 0.0);
    }
    nrm /= i;//i * 2.0;
    float mag = length(nrm.xy);
    if (mag > 1.0) {
        nrm = vec3(nrm.xy / mag, 0.0);
    } else {
        float m = 1.0 - nrm.x * nrm.x - nrm.y * nrm.y;
        nrm.z = m;
    }
    //nrm = nrm * 0.5 + 0.5;
    float l1 = dot(nrm, ld1) * 0.5 + 0.5;
    l1 = l1*l1*l1 + 0.1;
    float l2 = dot(nrm, ld2) * 0.5 + 0.5;
    l2 = l2*l2*l2 + 0.1;
    
    //nrm = nrm * 0.5 + 0.5;

    // Output to screen
    glFragColor = vec4(l1, (l1 + l2) * 0.5, l2, 1.0);
}
