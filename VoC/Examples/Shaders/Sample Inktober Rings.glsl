#version 420

// original https://www.shadertoy.com/view/tsyGWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float H21(vec2 p) {
    vec3 h = fract(p.xyx * vec3(141.212, 373.184, 107.63));
    h *= dot(h, vec3(p, 1848.177));
    return fract(h.x + (h.y * h.z));
}

vec2 rotate2d(vec2 p, float theta) {
    return p * mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
}

// https://github.com/hughsk/glsl-hsv2rgb/blob/master/index.glsl
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
    
    // -1.0 <> 1.0
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    
    float gridScalar = 30.0;
    
    uv *= gridScalar;
    
    uv += gridScalar * 3.0;
    
    uv = rotate2d(uv, 3.14159 * -0.25);

    
    vec2 id = floor(uv);
    vec2 st = fract(uv) - 0.5;
    
    
    float d = length(st);
    
    vec3 col = hsv2rgb(vec3(H21(id) * d, 0.5, 1.0));
    
    float radius = sin(time * H21(id) * 5.0) * 0.22 + 0.22;
    float border = 0.09;
    
    
    float inner = smoothstep(radius - border, radius, d);
    float outer = smoothstep(radius, radius + border, d);

    
      float mask = inner - outer;
    col *= mask;
    
    //col.b = smoothstep(0.09, 0.07, d);
    //col = vec3(H21(uv));

    glFragColor = vec4(col, 1.0);
}
