#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define PI 3.14159265359    
#define TWO_PI (PI*2.0)
#define N 14.0
void main(void) 
{
    vec2 v = (gl_FragCoord.xy - resolution * 0.5) / min(resolution.y,resolution.x) * 50.0;
    vec3 col = vec3(0.0);

    v+=cos(gl_FragCoord.xy * 0.0051 + time * 0.9) * +5.0;
    v+=sin(gl_FragCoord.xy * 0.0032 + time * 0.8) * -5.0;
    
    v*=5.0*sin(time*0.23);
    v+=100.0*vec2(cos(0.5*time),sin(0.5*time));
    for (float i = 0.0; i < N; i++)
    {
          float a = 0.2*time + i * (TWO_PI/N) + (gl_FragCoord.x+gl_FragCoord.y) * 0.0005;
        vec2 w;
        float cosa = cos(a);
        float sina = sin(a);
        w.x = v.x*cosa - v.y*sina;
          w.y = v.y*cosa + v.x*sina;
        col.xyz = col.yxz + vec3(
            cos(w.y + time*0.95),
            sin(w.y + time*1.40),
            cos(w.x + time*0.12)
        );
    }    
    col = abs(col) * 0.3;
    glFragColor = vec4(
        pow(col.r, 0.15) * 1.2,
        pow(col.g, 0.25) * 0.8,
        pow(col.b, 0.20) * 0.4,
        1.0
    );
}
