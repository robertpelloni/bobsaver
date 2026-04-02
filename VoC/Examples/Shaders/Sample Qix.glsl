#version 420

// original https://www.shadertoy.com/view/Md3GWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define StepSize 0.75
#define LineCount 6

//Function to draw a line, taken from the watch shader
float line(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return 0.2*pow(clamp(1.0-length(pa - ba * h),0.0,1.0),13.0)*(12.5-distance(a,b)+abs(h-.5))*.5;
}

float point(vec2 uv, vec2 p, float gt)
{
    return pow(clamp(0.44*(2.2-distance(p,uv)),0.0,1.0),30.0+3.0*sin(gt));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 11.0 - 5.5;

    float gt = time * 5.0;
    //gt -= mod(gt,StepSize);

    // Add lines to the pixel
    vec4 color = texture2D(backbuffer,(gl_FragCoord.xy / resolution.xy)*.98+.01)*5.0;
    vec2 point3 = 2.3 * vec2(sin(gt * 0.39), cos(gt * 0.63)) + 1.7*vec2(sin(gt * 0.27), cos(gt * 0.33));
    for (int i = 0; i < LineCount; i++)
    {
        gt += StepSize;

        //Calculate the next two points
        vec2 point1 = 2.3 * vec2(sin(gt * 0.39), cos(gt * 0.63)) + 1.7*vec2(sin(gt * 0.27), cos(gt * 0.33));
          vec2 point2 = 2.3 * vec2(cos(gt * 0.69), sin(gt * 0.29)) + 1.7*vec2(sin(gt * 0.19), cos(gt * 0.23));

        // Fade older lines
        color.rgb = 0.75 * color.rgb;

        // Add new line
        color.rgb += (point(uv, point1, gt)
                     +line(    uv,
                            point1, point2)
                     +point(uv, point2, gt))
                    //With color
                    * ( 0.5 +
                        0.5 * (vec3(sin(float(i) * 1127.13),
                                    sin(float(i) * 1319.39),
                                    cos(float(i) * 1227.67))));
        point3 = point1;
    }

    // Clamp oversaturation
    glFragColor = clamp(pow(color,vec4(1.2)), 0.0, 1.0);
}
