#version 420

// original https://www.shadertoy.com/view/mdsGDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.yy * 10.01;

    float it = mix(15.0, 25.0, (sin(time * 0.01) + 1.0) * 0.5);
    vec2 prev = uv;
    float count = 0.0;

    while (it > 1.0)
    {
      it -= 1.0;
      prev = uv;
      uv = abs(sin(uv * (0.5 + sin(time * 0.1) * 0.004) + vec2(count, 0.0)) + uv.yx + vec2(4.9 + sin(time * 0.13) * 0.1));      
      uv = vec2(uv.y, -uv.x * (mix(1.9, 1.1, smoothstep(time * 0.5, 0.0, 1.0))));
      count++;
    }

    uv = mix(prev, uv, it);

    vec3 col = 0.5 + 0.5*cos(time + vec3(uv.x, uv.y, uv.x + uv.y) - vec3(3, 4, 5));
    glFragColor = vec4(col,1.0);
}
