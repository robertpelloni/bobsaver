#version 420

// original https://www.shadertoy.com/view/XtGXRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// #define BW 1

float patternForPos(vec2 uv, float reso, float time) {
    float timeOsc = sin(time) * 0.15;                                // oscillation helper
    float dist = 0.;                                                // start distance count from 0
    for(float i=10.; i < 60.; i++) {                                // create x control points
        float rads = timeOsc + i;                                    // get rads for control point
        vec2 ctrlPoint = vec2(sin(rads), cos(rads));                // control points in a circle 
        ctrlPoint *= abs(cos(rads)) * 15.;                            // oscillate control point radius - the magic happens w/abs()
        dist += sin(i + reso * distance(uv, ctrlPoint));            // sum up oscillated distance between control points
    }
    return dist;
}

vec2 rotateCoord(vec2 uv, float rads) {
    uv *= mat2(cos(rads), sin(rads), -sin(rads), cos(rads));
    return uv;
}

vec3 colFromRGB(float r, float g, float b) {
    return vec3(r, g, b) / 255.;
}

void main(void)
{
    float time = time / 4.;
    // grab postion and rotate per layer
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;    // center coordinates
    vec2 uv2 = rotateCoord(uv + 1., time + 1.);
    vec2 uv3 = rotateCoord(uv * 2., time + 2.);
    vec2 uv4 = rotateCoord(uv + 1.5, time + 3.);
    // create pattern at different resolutions
    float col = patternForPos(uv, 4., time);
    float col2 = patternForPos(uv2, 9., time);
    float col3 = patternForPos(uv3, 3., time);
    float col4 = patternForPos(uv3, 2.25, time);
    // create final pattern
    vec3 color = vec3(0);
    #ifdef BW
        float colorSum = col + col2 + col3 + col4;
        color = vec3(sin(colorSum * 2.));
    #else
        if(col2 + col + col4 > 2.85) color = colFromRGB(53., 58., 65.);
        else if(col2 < 0.81) color = colFromRGB(102., 86., 58.);
        else if(abs(col4 * col3) > 4.5) color = colFromRGB(80., 120., 77.);
        else color = colFromRGB(199., 188., 125.);
    #endif
    glFragColor = vec4(color,1.0);
}
