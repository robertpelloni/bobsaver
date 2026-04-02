// https://www.shadertoy.com/view/XlSBzm

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

// by Nikos Papadopoulos, 4rknova / 2018
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
#define LUM vec3(.2126, .7152, .0722)

// Configuration
#define CHROMA_KEY
#define CHROMA_COEF (00.10)
#define CHROMA_BIAS (00.13)

#define BGCOLOR     vec3(0.03, 0.1, 0.2)
#define GRID_SIZE   (35.0)
#define BIAS        (10.0)
#define SCALE       (32.0)

void main()
{
    // Aspect corrected grid size.
    vec2  gridsz = GRID_SIZE * vec2(resolution.x/resolution.y, 1);
    // Grid coordinates with half a unit offset to sample
    // the center of the cell.
	vec2  pc  = gl_FragCoord.xy / resolution.xy * gridsz;
    vec2  cl  = floor(pc)+0.5;
    vec3  col = texture(image, cl / gridsz).rgb;
    float lum = dot(LUM, col.rgb); // luminance
    // Calculate the sample's distance from the cell center.
    float dst = pow(1. - length(pc - cl), BIAS) * SCALE;
    
 #ifdef CHROMA_KEY
    if (lum > max(col.r, col.b) + CHROMA_BIAS) col = BGCOLOR;
 #endif /* CHROMA_KEY */
    
    glFragColor = vec4(mix(BGCOLOR, col, min(1., dst*lum)), 1);
}