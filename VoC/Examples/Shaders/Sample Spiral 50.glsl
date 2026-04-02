#version 420

// original https://www.shadertoy.com/view/cslGDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float time = time;
    float x=uv.s, y=uv.t;
    float aspect = resolution.x/resolution.y;

    x -= 0.5;
    y -= 0.5;
    float sca = 2.5;
    x *= aspect;
    x *= sca;
    y *= sca;
    float t = atan(y, x);
    float r = sqrt(x*x + y*y), ror = r;
    r = r - 0.5 * time;
    r += t / 5.0;
    float rof = 0.03 * sin(t * 30.0);
    rof *= pow(ror, 3.0);
    float q = 0.5 + 0.5 * cos((r + rof) * 10.0);

    float p = q*0.520 + 0.240;
    float ofs = 0.100 + 0.1 * sin(time * 3.5);
    vec3 color = vec3(0.);
    color.r += cos(clamp((p - (0.300 + 0.1*sin(time*0.7)) - ofs) * 10.0, -3.14159/2., 3.14159/2.));
    color.g += cos(clamp((p - (0.398 + 0.1*sin(time*0.77)) - ofs) * 10.0, -3.14159/2., 3.14159/2.));
    color.b += cos(clamp((p - (0.488 + 0.1*sin(time*0.97)) - ofs) * 10.0, -3.14159/2., 3.14159/2.));
    color *= 1.0 - pow(clamp(1.0 - ror, 0.0, 1.0), 10.0);

    glFragColor = vec4(color, 1.0);
}
