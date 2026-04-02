#version 420

// original https://www.shadertoy.com/view/Wll3Dl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float DistToLine(vec3 Ro, vec3 Rd, vec3 p)
{
    return length(cross((p-Ro) , Rd))/length(Rd);
}

float DrawPoint(vec3 Ro, vec3 Rd, vec3 p)
{
    float d = DistToLine(Ro, Rd, p);
    d = smoothstep(0.08, 0.07, d);
    return d;
}

void main(void)
{
    float t = time;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;
    //uv.y *= resolution.x/resolution.y;
    
    vec3 Ro = vec3(3.0*sin(t), 2.0, -3.0*cos(t));
    vec3 lookat = vec3(0.0);
    float zoom = 0.6;
    vec3 f = normalize(lookat - Ro);
    vec3 r = cross(vec3(0.0, 1.0, 0.0), f);
    vec3 u = cross(f, r);
    
    vec3 c = Ro + f*zoom;
    vec3 i = c + uv.x*r + uv.y*u;
    
    vec3 Rd = i-Ro;
    
    float d = 0.0;
    
    d += DrawPoint(Ro, Rd, vec3( 1.0,  -1.0,  1.0));
    d += DrawPoint(Ro, Rd, vec3(-1.0,  -1.0,  1.0));
    d += DrawPoint(Ro, Rd, vec3( 1.0,  -1.0, -1.0));
    d += DrawPoint(Ro, Rd, vec3(-1.0,  -1.0, -1.0));
    d += DrawPoint(Ro, Rd, vec3( 1.0,   1.0,  1.0));
    d += DrawPoint(Ro, Rd, vec3(-1.0,   1.0,  1.0));
    d += DrawPoint(Ro, Rd, vec3( 1.0,   1.0, -1.0));
    d += DrawPoint(Ro, Rd, vec3(-1.0,   1.0, -1.0));
   
    float col;
    col = d;
  
    glFragColor = vec4(col);
}
