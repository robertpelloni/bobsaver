#version 420

// original https://www.shadertoy.com/view/XtyXzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI     3.14159265358
#define TWO_PI 6.28318530718

void main(void)
{
    float time = time * 1.;                                        // adjust time
    vec2 uv = (2. * gl_FragCoord.xy-resolution.xy)/ resolution.y;  // center coordinates
    float rads = atan(uv.x, uv.y);                                 // get radians to center
    float dist = length(uv);                                       // store distance to center
    float spinAmp = 4.;                                            // set spin amplitude
    float spinFreq = 2. + sin(time) * 0.5;                         // set spin frequency
    rads += sin(time + dist * spinFreq) * spinAmp;                 // wave based on distance + time
    float radialStripes = 10.;                                     // break the circle up
    float col = 0.5 + 0.5 * sin(rads * radialStripes);             // oscillate color around the circle
    col = smoothstep(0.5,0.6, col);                                // remap color w/smoothstep to remove blurriness
    col -= dist / 2.;                                              // vignette - reduce color w/distance
    glFragColor = vec4(vec3(col), 1.);
}
