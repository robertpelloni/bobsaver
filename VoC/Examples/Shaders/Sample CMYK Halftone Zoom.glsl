#version 420

// original https://www.shadertoy.com/view/NtjBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TURN 6.283185
#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.
#define ROT(theta) mat2(cos(theta+vec4(0,33,11,0)))

// how much to smooth the color stripes
#define COLOR_SMOOTHING 1.

vec3 color(float x) {
    float factor = fract(x) * 3.0;
    float f0 = smoothstep(0., 0. + COLOR_SMOOTHING, factor);
    float f1 = smoothstep(1., 1. + COLOR_SMOOTHING, factor);
    float f2 = smoothstep(2., 2. + COLOR_SMOOTHING, factor);
    return (
        HEX(0x009BE8) * (f0 - f1) +
        HEX(0xEB0072) * (f1 - f2) +
        HEX(0xfff100) * (f2 - f0 + 1.)
    );
}

// returns a grid of distances from the center. don't threshold it with anything over 1.0
float dots(vec2 uv)
{
    uv = fract(uv) - vec2(0.5); // fractional component with dots centered at (0.5, 0.5)
    return sqrt(uv.x * uv.x + uv.y * uv.y);
}

// returns the coordinates of the center of the closest dot
vec2 uvGrid(vec2 uv)
{
    return floor(uv) + vec2(0.5);
}

#define LOOPLEN 4.
#define LAYERS 16.
#define ZOOMSCALE 0.01
#define LAYERSCALE 0.9
#define LAYERROT 0.01
#define LAYERSPERLOOP 3.
#define ROTALLSCALE -0.25
#define FARFADE 0.5
#define OUTLINE 0.002

void main(void)
{
    const vec3 colOutline = HEX(0x010a31);

    float t = fract(time / LOOPLEN);
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / length(resolution.xy);
    uv *= 0.0625 * ZOOMSCALE;
    
    // camera distortion
    float dist = 1. - length(uv);
    uv *= 100. * dist*dist*dist*dist*dist;

    // Time varying pixel color
    vec3 col = colOutline;
    
    for (float i = 0.; i < LAYERS; i++) {
        float layerAlpha = clamp(
            (LAYERS - i - t * LAYERSPERLOOP) * 3.0
            , 0.0, 1.0
        );
        float depth = LAYERS - i - t * LAYERSPERLOOP;
        vec2 layerUV = uv * ROT(TURN * (
            ROTALLSCALE * -t + depth * LAYERROT
        ));
        
        // offset center by how much the whole graphic is turning
        vec2 layerCenter = vec2(
            cos(-t * (TURN * (1. + ROTALLSCALE))),
            sin(-t * (TURN * (1. + ROTALLSCALE)))
        ) * 0.2;
        
        layerUV = layerUV * exp2(LAYERSCALE * depth) - layerCenter;
        vec2 layerGrid = uvGrid(layerUV);
        
        float aa = fwidth(layerUV.x) * 1.5;
        float thres = 0.20 + 0.15 * sin(TURN * (
            0.5 + 
            log(
                length(layerGrid) + 0.1
            ) * 0.7
            + t * -2.
            + depth * 0.1
            
            - t * ROTALLSCALE // offsets gloabl rotation
        ) - atan(layerGrid.y, layerGrid.x)
        );
        float dots = dots(layerUV);
        float dotsAlpha = smoothstep(0., aa, thres - dots);
        
        vec3 layerCol = mix(
            colOutline,
            color(i / 3.),
            smoothstep(0., aa, thres - dots - OUTLINE) * clamp(
            (i + (t - 1.) * LAYERSPERLOOP) * FARFADE
            , 0., 1.)
        );
        col = mix(
            col,
            layerCol,
            layerAlpha * dotsAlpha
        );
    }
    
    //col = fract(128. * uv.xyx);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
