#version 420

// original https://www.shadertoy.com/view/msKcWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec2 p = gl_FragCoord.xy;
    vec4 f = vec4(0.0);
        
    vec3 q=vec3(resolution.xy,1.0),d=vec3(p-.5*q.xy,q.y)/q.y,c=vec3(0,.5,.7);
    vec2 uv = p / resolution.xy;
    
    q = d/(.1-d.y*5.5);
    // q.x -= 0.5;
    float a = time;
    
    float k = sin(0.2*a);
    
    float w = q.x *= q.x-=.05*k*k*k*q.z*q.z;
    // w *= 0.2;

    f.xyz=d.y>.015?c:
        sin(4.*q.z+40.*a)>0.?
        w>2.?c.xyx:w>1.2?d.zzz:c.yyy:
        w>2.?c.xzx:w>1.2?c.yxx*2.:(w>.004?c:d).zzz;
        
        
    vec3 lighting = vec3(0.2, 0.2, 0.2); // ambient lighting
    float distToSide = 1.0 - clamp(abs(w - 1.2) * 0.5, 0.0, 1.0);
    float spotStrength = (sin((4.0 * q.z + 40.0 * a) * 0.25) * 0.5 + 0.5);
    float lightStrength = spotStrength * distToSide;
    lightStrength *= lightStrength;
    lighting += vec3(0.6, 0.5, 0.3) * lightStrength * 1.2;
    
    if (d.y <= 0.015) { f.xyz *= lighting; } else { f.xyz *= 0.3; }
    
    glFragColor=f;
}