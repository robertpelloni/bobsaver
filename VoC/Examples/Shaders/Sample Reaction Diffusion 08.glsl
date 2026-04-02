#version 420

precision mediump float;

uniform float time;
uniform vec2 resolution;
uniform sampler2D backbuffer;
uniform vec2 mouse;

out vec4 glFragColor;

#define DU 1.0
#define DV 0.5
#define F 0.01
#define K 0.045
#define DELTA 1.0

void main()
{
    vec2 c = vec2(1., 0.);
    if (time <= 1.);
    else if (floor(gl_FragCoord.xy) == floor((mouse*resolution)))
    {
        c.y = 1.0;
    }
    else
    {
        vec2 l = vec2(0, 0);
        for (float yy=-1.;yy<=1.;yy++)
        {
            float y = gl_FragCoord.y + yy;
            for (float xx=-1.;xx<=1.;xx++)
            {
                  float x = gl_FragCoord.x + xx;
                  vec2 uv = vec2(x, y);
                  vec2 t = texture2D(backbuffer, uv/resolution).xy;
                  if (uv == gl_FragCoord.xy)
                  {
                      l -= t * 8.0;
                  }
                else
                  {
                      l += t;
                  }
            }
        }
        l /= 9.;
        vec2 t = texture2D(backbuffer, gl_FragCoord.xy/resolution).xy;
        c = t;
        float r = t.x * t.y * t.y;
        c.x += DELTA * (DU*l.x - r + F*(1.-t.x));
        c.y += DELTA * (DV*l.y + r - (F+K)*t.y);
    }
    glFragColor = vec4(c.x, c.y, 0.5, 1.0);
}
