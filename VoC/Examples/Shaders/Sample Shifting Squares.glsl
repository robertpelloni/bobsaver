#version 420

// original https://www.shadertoy.com/view/ttSSWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265

vec2 rotate2D( in vec2 uv, in float alpha )
{
    uv -= 0.5;
    float s = sin(alpha);
    float c = cos(alpha);
    uv =  mat2(c, -s, s, c) * uv;
    uv += 0.5;
    return uv;
}

vec2 tile(in vec2 uv, in float zoom)
{
    return fract(uv * zoom);
}

float box( in vec2 uv, in vec2 size, in float smoothEdges )
{
  size = 0.5 - size * 0.5;
  vec2 aa = vec2( smoothEdges * 0.5 );
  vec2 st = smoothstep( size, size + aa, uv);
       st *= smoothstep( size,  size + aa, 1.0 - uv);
  return st.x * st.y;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
         uv.y *= resolution.y / resolution.x;
    
    float dx = 0.0;// mouse.x*resolution.xy.x / resolution.x;
    float dy = 0.0;// mouse.y*resolution.xy.y / resolution.y;
    
    float shiftAngle = PI * 0.25;
    float speed = mix( 0.75, 3.5, dy);
    float angle = mod( speed * time, PI) + shiftAngle;
    float doShift = step(angle, 3.0*shiftAngle);

    float scale = mix(4.0, 32.0, dx);
    float shift = 0.5 / scale;
    
    uv += vec2(-shift, shift) * doShift;
    uv = tile(uv, scale);
    uv = rotate2D(uv, angle);

    vec3 color = vec3(abs(box(uv,vec2(0.7), 0.015) - doShift));
    glFragColor = vec4(color,1.0);
}
