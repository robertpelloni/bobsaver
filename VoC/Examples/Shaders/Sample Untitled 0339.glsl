#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

vec3 orb;

float map(vec2 p, float s)
{
    float scale = 1.0;
    orb = vec3(100.0);

    for (int i = 0; i < 8; i++)
    {
        p = -1.0 + 2.0 * fract(0.5 * p + 0.5);
        float r2 = dot(p, p);
        orb = min(orb, vec3(abs(p), r2));

        float k = s / r2;
        p *= k;
        scale *= k;
    }
    return 0.25 * (length(p)) / scale;
}

void main() {
   vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
      vec2 pos = surfacePos;
      float dist=map(pos,0.5*(1.0+sin(time/2.+pos.x/2.))+0.6);
      dist=pow(dist,0.25);    
     glFragColor=vec4(dist);
}
