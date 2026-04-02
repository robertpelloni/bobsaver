#version 420

// original https://www.shadertoy.com/view/WlcSD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// For this to work, it needs a rectangle which can be split into a square and another rectangle
// with the same edge-length ratios, such as x:1 where 1 / (x - 1) == x or (x - 1) == 1 / x
// and the golden ratio satisfies this equation.

const float phi = (sqrt(5.) + 1.) / 2.;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.y;

    // Jittered time value for cheap motionblur
    float t = time; // + texelFetch(iChannel0, ivec2(gl_FragCoord.xy) & 1023, 0).r / 60.;
    
    vec2 zc = vec2(0);
    vec2 pp = vec2(pow(phi - 1., 4.), pow(phi - 1., 3.));
    
    // Determine a point close enough to the limit point for zooming in to
    for(int i = 0; i < 16; ++i)
        zc = zc * pp.x + vec2(1., pp.y);
    
    uv -= .5 * vec2(resolution.x / resolution.y, 1);
    uv += vec2(cos(t / 3.), sin(t / 2.)) * .1;
    
    float a = t;
    mat2 m = mat2(cos(a), sin(a), -sin(a), cos(a));
    
    // Exponential scaling transform, for a seamless (self-similar) zooming animation.
    float scale = pow(pp.x, 1. + fract(t));
    
    uv = m * uv * scale + zc;

    vec3 c = vec3(0);

    // Repeatedly subdivide pixelspace into a square and rectangle with edge lengths in ratio 1:(phi-1)
    // Note that such a rectangle has the same shape as a rectangle with ratio 1:phi
    for(int i = 0; i < 32; ++i)
    {
        float j = float(i) + floor(t) * 4.;
        if(uv.x < 1.)
        {
            // Pixel is inside this square. Pick a colour and break out.
            c = sin(vec3(j, j * 2., j * 3.)) * .5 + .5;
            break;
        }
        // Pixel is inside the rectangle, so continue subdividing.
        uv = (uv - vec2(1., 1.)).yx * vec2(-1, 1) * phi;
    }
    
    glFragColor.rgb = sqrt(c);
    glFragColor.a = 1.;
}
