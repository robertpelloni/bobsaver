#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float MNweights(float x)
{
    float a = abs(x);
    return step(a,2.)*((step(a,1.0000001)*((3.*a-6.)*a*a+4.)/6.)
               +(step(1.0000001,a)*(((6.-a)*a-12.)*a+8.)/6.));
}

vec4 texture2D_bicubic(sampler2D tex, vec2 uv)
{
    vec2 ps = 1./resolution;
    vec2 uva = uv-ps*.5;
    vec2 f = fract(uva*resolution);
    vec2 texel = uv-f*ps;
    vec4 result = vec4(0);
    for (float r = -1.; r < 3.; ++r)
    {
        vec4 tmp = vec4(0);
        for (float t = -1.; t < 3.; ++t)
            tmp += texture2D(tex, texel+vec2(t,r)*ps)
                * MNweights(abs(t)-sign(t+.5)*f.x);
        result += tmp   * MNweights(abs(r)-sign(r+.5)*f.y);
    }
    return result;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution-0.5)*vec2(resolution.x/resolution.y,1.0);
    float t = floor(time*3.)*2.;
    float c = smoothstep(0.21,0.2,length(uv));
    float active = c * smoothstep(0.02,0.01,dot(uv,vec2(sin(t),cos(t))*5.));
    glFragColor = vec4(active) + texture2D_bicubic(backbuffer,(gl_FragCoord.xy/resolution - 0.5)*0.99+0.5)*(1.0-c);
}
