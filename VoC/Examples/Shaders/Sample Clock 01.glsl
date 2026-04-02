#version 420

// original https://www.shadertoy.com/view/MdSSDy

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Yellow LEDs represent seconds, red ones minutes, and green ones
// hours; all numbers are shown in their binary format (LEDs values
// from right to left: 1, 2, 4, 8, 16 and 32).

#define M_PI 3.1415926535897932384626433832795

vec3 rgb (in vec3 hsv) {
    #ifdef HSV_SAFE
    hsv.yz = clamp (hsv.yz, 0.0, 1.0);
    #endif
    return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.xxx + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

float rand (in vec2 seed) {
    return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 137.5453);
}

void main (void) {

    // Get the fragment's position
    vec2 frag = 7.0 * (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.x;

    // Define the background lights
    vec3 lightColor = vec3(0.0, 0.0, 0.2);
    const float lightCount = 5.0;
    for(float lightId = 0.0; lightId < 1.0; lightId += 1.0 / lightCount) {
        float lightAngle = 2.0 * 3.14159 * lightId + time;
        lightColor += rgb (vec3 (lightId + time * 0.1, 1.0, 1.0)) / length (frag - 2.5 * vec2 (cos (lightAngle), sin (lightAngle)));
    }
    lightColor *= 3.0 / lightCount;

    // Rotate the watch every 5s
    float fragAngle = 0.2 * sin (time * M_PI * 2.0) * step (4.0, mod (time, 5.0));
    vec2 fragRotate = vec2 (cos (fragAngle), sin (fragAngle));
    frag = mat2 (fragRotate.x, fragRotate.y, -fragRotate.y, fragRotate.x) * frag;

    // Define the panel and the border
    float panelDist = length (frag) - 3.5;
    float borderDist = panelDist - 0.05;

    // Define the LEDs
    float ledThresholdBar2 = step (-0.5, frag.y);
    float ledThresholdBar3 = step (0.5, frag.y);
    vec2 ledTranslate = vec2 (0.5 * ledThresholdBar3, 0.5);
    vec2 ledPosition = frag + ledTranslate;
    vec2 ledId = floor (ledPosition);
    float ledMode = max (0.0, cos (time * 0.5));
    float ledDist = length (fract (ledPosition) - 0.5);
    float ledDisplay = step (0.0, 3.1 - length (ledId + 0.5 - ledTranslate));

    float ledTime = mod (date.w / (1.0 + 59.0 * ledThresholdBar2 + 3540.0 * ledThresholdBar3), 60.0);
    vec3 ledColor0 = vec3 (1.0 - ledThresholdBar3, ledThresholdBar3 - ledThresholdBar2 + 1.0, 0.0);
    ledColor0 *= step (0.5, fract (ledTime / pow (2.0, 3.0 - ledId.x))) * step (-1.5, -abs (frag.y));

    float ledRandom = rand (ledId);
    vec3 ledColor1 = rgb (vec3 (ledRandom + time * 0.1, 1.0, 1.0));
    ledColor1 *= 0.5 + 0.5 * cos (ledRandom + ledRandom * time +time);

    // Create everything (panel, casing, LEDs, lights)
    vec3 color = vec3 (0.2, 0.2, 0.4) * (0.7 + 0.3 * cos (frag.y * M_PI / 3.5)) * smoothstep (0.0, -0.2, panelDist) * smoothstep (0.0, 0.2, ledDist);
    color += (0.2 + 0.2 * cos (frag.x + frag.y + time)) * smoothstep (0.1, 0.0, max (borderDist, -panelDist));
    color += mix (ledColor0, ledColor1, ledMode) * smoothstep (0.35, 0.0, ledDist) * ledDisplay;
    color += lightColor * smoothstep (0.0, 0.2, borderDist);

    // Set the fragment color
    glFragColor = vec4 (color, 1.0);
}
