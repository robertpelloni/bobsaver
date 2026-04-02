#version 420

// original https://www.shadertoy.com/view/3tBSR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float MAX = 20.0;

vec2 po(vec2 z) {
    return vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y);
}

vec4 mende( vec2 pos ) {
    MAX = 10.0 * time;
    
    vec2 z = pos;
    
    float i = 0.0;
    
    for(i = 0.0; i < MAX; i++) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y);
        z += pos;
        if (length(z) > 2.0) break;
    }
    
    float t = cos(time);
    i /= MAX;
    return vec4(i, log(length(z)), i / length(z), 1.0);
    
}

vec2 trata (vec2 idiota) {
    idiota /= resolution.xy;
    idiota =  idiota * 2.0 - 1.0;
    idiota.x *= resolution.x / resolution.y;
    return idiota;
}

void main(void) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = trata(gl_FragCoord.xy);
    //vec2 mouse = trata(mouse*resolution.xy.xy);
    
    vec2 zoom = vec2(-0.749755,0.1006);
    
    uv /= exp(time-1.0);
    //uv += trata(mouse*resolution.xy.xy * uv.x);
    uv += zoom;
    
    // Output to screen
    glFragColor = mende(uv);
}
