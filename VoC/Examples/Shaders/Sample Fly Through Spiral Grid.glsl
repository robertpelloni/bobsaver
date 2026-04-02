#version 420

// original https://www.shadertoy.com/view/dsK3DD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// set to 0 to make colors buttery-smooth
// set to 1 to dither colors (for GIF export)
#define DITHER 1

// generate an ordered dithered pattern based on pixel coordinates
#if DITHER == 1
float crosshatch(vec2 xyf) {
    ivec2 xy = ivec2(xyf) & 3;
    return (float(
        + ((xy.y >> 1) & 1)
        + ((xy.x & 2) ^ (xy.y & 2))
        + ((xy.y & 1) << 2)
        + ((((xy.x) & 1) ^ (xy.y & 1)) << 3)
    ) + 0.5) / 16.;
}
#endif

const float TURN = acos(-1.) * 2.;
// rotation matrix
#define ROT(x) mat2x2(cos(x + TURN * vec4(0, 0.25, -0.25, 0)))
// converts colors from hex code to vec3
#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.
// “zigzag” value between 0 and 1
#define ZIG(x) (1. - abs(1. - fract(x) * 2.))

// convert float in range [0, 1) to a color based on a colormap
vec3 colormap(float x){
    const int colorCount = 16;
    vec3[] c = vec3[](
        HEX(0xfaf875),
        HEX(0xfcfc26),
        HEX(0xbcde26),
        HEX(0x5CC863),
        
        HEX(0x1FA088),
        HEX(0x33638D),
        HEX(0x3D4285),
        HEX(0x1F0269),
        
        HEX(0x25024D),
        HEX(0x430787),
        HEX(0x6F00A8),
        HEX(0x9814A0),
        
        HEX(0xC23C81),
        HEX(0xF07F4F),
        HEX(0xFDB22F),
        HEX(0xFAEB20)
    );
    x *= float(colorCount);
    int lo = int(floor(x));
    
    return mix(
        c[lo],
        c[(lo + 1) % colorCount],
        fract(x)
        //smoothstep(0.0, 1., fract(x))
    );
}

void main(void)
{
    float t = fract(time / 8.);
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    uv *= 2.;
    
    // For ease of calculation, X and Y are flipped here
    vec2 disp = vec2(2, 1);
    float dispAngle = atan(disp.x, disp.y);
    float swingAngle = TURN / 2. - 2. * dispAngle;
    vec2 swingRoot = disp.x / vec2(-1, tan(swingAngle));

    float swingProg = cos((t + 1./16.) * TURN);
    vec2 swingArm = vec2(0,-(swingRoot.y + disp.y)) * ROT(
        swingAngle * swingProg
    );
    
    uv *= ROT(cos(t * TURN) * 0.5 * swingAngle);
    
    vec2 swingDisp = vec2(0, swingRoot.y + disp.y) + swingArm;

    float v = 0.;
    const float LAYERS = 16.;
    const float LAYERSPERLOOP = 4.;
    const float ZSCALE = 0.25;
    float LAYEROFFSET = floor(t * LAYERSPERLOOP);
    for (float i = LAYERS; i > 0.; i--) {
        float z = ZSCALE * (i - fract(t * LAYERSPERLOOP));
        vec2 uvLayer = uv * z + swingDisp;
        uvLayer = fract(uvLayer - 0.25);
        float alpha = 1. - step(0.5, uvLayer.x) * step(0.5, uvLayer.y);
        alpha *= step(0.06, z);
        float altColor = 1. - step(uvLayer.x, 0.5) * step(uvLayer.y, 0.5);
        
        vec2 uvGrid = fract(uvLayer * 2.) - 0.5;
        float r = length(uvGrid) + .05;
        float theta = atan(uvGrid.y, uvGrid.x) / TURN;
        
        v = mix(
            v, t + uv.y / 16. + ( 
                0.5 * altColor + 0.5 * step(
                fract(
                    mix(-1.2, 1.0, altColor) * log(r) +
                    mix(0., 3., altColor) * theta +
                    11. * t +
                    1.3 * z +
                    mix(0.5, 0., altColor)
                ), 0.75) +
                (i + LAYEROFFSET) / LAYERSPERLOOP
            ),
            alpha
        );
    }
    
#if DITHER == 1
    float thres = crosshatch(gl_FragCoord.xy);
    const float STEPS = 16.;
    v = fract((
        floor(v * STEPS) +
        step(thres, fract(v * STEPS))
    ) / STEPS);
#endif

    vec3 col = colormap(v);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
