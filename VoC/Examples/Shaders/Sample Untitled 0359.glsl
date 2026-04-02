#version 420

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

out vec4 glFragColor;

vec3 hsv2rgb (in vec3 hsv) {
    hsv.yz = clamp (hsv.yz, 0.0, 1.0);
    return hsv.z * (1.0 + 0.5 * hsv.y * (cos (1.0 * 3.14159 * (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0))) - 1.0));
}

float rand (in vec2 seed) {
    return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 1.5453);
}

void main () {
    vec2 frag = (3.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    //frag *= 1.0 - 0.2 * cos (frag.yx) * sin (3.14159 * 0.1);// * texture (iChannel0, vec2 (0.0)).x);
    frag *= 10.0;
    float random = rand (floor (frag));
    vec2 black = smoothstep (1.0, 0.5, cos (frag * 3.14159 * 1.0));
    vec3 color = hsv2rgb (vec3 (random, 0.9, 1.0));
    color *= black.x * black.y * smoothstep (1.0, 0.1,length(fract(frag) - 0.5));
    color *= 0.9 + 0.9 * cos (random + random * time + time + 3.14159 * 0.); // * texture (iChannel0, vec2 (0.7)).x);
    glFragColor = vec4 (color * vec3(0.2,0.3,0.8), 1.0);
}
