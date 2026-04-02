#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ssjGWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Shader version of @aemkei's "alien art"
// Original: https://twitter.com/aemkei/status/1378106731386040322

// Change ZOOM to get blockier or denser pixels
#define ZOOM 4.0

// Change RATE to control animation rate
#define RATE 2.0

// Change RBGP to make the colour channels animate at different rates
#define RBGP 2.0

// Dark mode 🕶
#define DARK true

// Press the ⏮ button under the preview window to restart from the beginning

void main(void)
{
    // Screen coordinates
    vec2 uv = gl_FragCoord.xy/ZOOM;
    
    // Get "pixel" coordinates
    int x = -int(uv.x); // Negative to remove a constant diagonal line 🤷
    int y = int(uv.y);
    
    // Do the bitwise XOR thing ✨
    int b = x^y;
    
    // Modulo an integer to get the ALIEN ART 👽
    // If RGBP is different to zero, we'll get colour!
    float xr = mod(float(b), floor(time*(RATE)));
    float xg = mod(float(b), floor(time*(RATE+RBGP)));
    float xb = mod(float(b), floor(time*(RATE+RBGP*2.0)));
    vec3 col = vec3(xr, xg, xb);

    // The original is white on black, and honestly it looks better 🕶
    if (DARK) col=1.0-col;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
