#version 420

// fun with blobbies... fritschy/2013

uniform sampler2D backbuffer;
uniform vec2 mouse;
uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main()
{
    float rc=cos(time/10.0);
    float rs=sin(time/10.0);
    mat2 rot = mat2(rc, rs, -rs, rc);
    float radius = min(resolution.x, resolution.y) / 45.0;
    float sqr = float(radius * radius);

   vec2 coords = gl_FragCoord.xy / resolution - vec2(0.5);
   vec2 tcr = coords * rot * 1.03 + vec2(0.5);
   vec2 tcg = coords * rot * 1.02  + vec2(0.5);
   vec2 tcb = coords * rot * 1.01  + vec2(0.5);
   vec2 dd = mouse * resolution - gl_FragCoord.xy;
   float p = sqr / dot(dd, dd);
   vec3 c = vec3(texture2D(backbuffer, tcr).r * 0.93,
                 texture2D(backbuffer, tcg).g * 0.94,
                 texture2D(backbuffer, tcb).b * 0.95);
   glFragColor = vec4(c + vec3(p), 1.0);
}
