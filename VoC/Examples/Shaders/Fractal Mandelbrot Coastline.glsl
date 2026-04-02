#version 420

// original https://www.shadertoy.com/view/NsffD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265358979;
const int MAX_ITER = 64;
//const int Z_STEP = 256 / MAX_ITER;
const float ROT_SPEED = 0.05;

void main(void)
{
    float zoom = (cos(time*0.2)*0.5+0.5)*0.495+0.05;

    // Normalize pixel coordinates (y = -0.5..0.5, x = -xres/yres/2..xres/yres/2)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float ar = resolution.x/resolution.y;
    uv -= 0.5;
    uv.x *= ar;

    float sa = sin(time*ROT_SPEED), ca = cos(time*ROT_SPEED);
    //uv *= mat2(ca, -sa, sa, ca);
    uv *= zoom;
    float cardioid = (0.5 - 0.5*ca);
    vec2 shift = vec2(ca*cardioid + 0.25, sa*cardioid);
    
    // Mandelbrot : x = x^2 - y^2 + x0, y = 2*x*y + y0
    
    int iter;
    glFragColor = vec4(1.0, 0.25, 0, 0);
    for (int z = MAX_ITER*2; z < MAX_ITER*3-1; ++z) {
        vec2 xy = uv * float(z) / float(MAX_ITER*5) + shift;
        float x0 = xy.x;
        float y0 = xy.y;
        for (iter = 0; iter <= z-MAX_ITER*2; ++iter) {
            vec2 xy2 = xy * xy;
            if (xy2.x + xy2.y > 4.0) { break; }
            xy = vec2(xy2.x - xy2.y + x0, 2.0 * xy.x * xy.y + y0);
        }
        if (iter <= z-MAX_ITER*2) {
            float c = float(MAX_ITER*3-1-z)/float(MAX_ITER);
            glFragColor = vec4(0.75-c/1.333, 1.0-c, c/2.0, 1.0);
            break;
        }
    }
}
