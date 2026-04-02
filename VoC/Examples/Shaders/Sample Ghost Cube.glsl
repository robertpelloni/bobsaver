#version 420

// original https://www.shadertoy.com/view/Msc3Wf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float map(vec3 p)
{
    float t = time;
    p.xz *= mat2(cos(t), sin(t), -sin(t), cos(t));
    p.xy *= mat2(cos(t), sin(t), -sin(t), cos(t));
    p.yz *= mat2(cos(t), sin(t), -sin(t), cos(t));
    
    float k = sdBox(p, vec3(1.0));
    float o = 0.85;
    k = max(k, -sdBox(p, vec3(2.0, o, o)));
    k = max(k, -sdBox(p, vec3(o, 2.0, o)));
    k = max(k, -sdBox(p, vec3(o, o, 2.0)));
    return k;
}

float trace(vec3 o, vec3 r)
{
     float t = 0.0;
    for (int i = 0; i < 32; ++i) {
        vec3 p = o + r * t;
        float d = map(p) * 0.9;
        t += d;
    }
    return t;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec4 old = texture(backbuffer, uv - vec2(0.0, 1.0/resolution.y));
    vec4 old2 = texture(backbuffer, uv - vec2(0.0, 2.0*1.0/resolution.y));
    
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 o = vec3(0.0, 0.0, -2.5);
    vec3 r = vec3(uv, 0.8);
    
    float t = trace(o, r);
    
    vec3 fog = vec3(1.0) / (1.0 + t * t * 0.1) * 0.1;
    
    float c = time * 5.0 + uv.x;
    fog *= vec3(sin(c)*cos(c*2.0), cos(c)*cos(c*2.0), sin(c)) * 0.5 + 0.5;
    
    fog += old.xyz * 0.6 + old2.xyz * 0.37;
    
    glFragColor = vec4(fog, 1.0);
}
