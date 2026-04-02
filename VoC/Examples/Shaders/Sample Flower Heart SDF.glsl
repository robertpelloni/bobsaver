#version 420

// original https://www.shadertoy.com/view/cssczs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592653589793

float flowerSDF(vec2 p, float a, float leafsHalfQty, float radius, float leafSize)
{
    float l = length(p);
    float ang = atan(p.y,p.x)*2.*leafsHalfQty + a;
    return l-(radius+sin(ang)*leafSize);
    
}

float heartSDF(vec2 p, float a,float size, float shape)
{
    p*=4.*size;
    float l = length(p);
    float ang = atan(p.y,p.x)+a;
    
    float d = sin(ang)*sqrt(abs(cos(ang)))/(sin(ang)+7./5.) - 2.*sin(ang) + 1.5+shape;
    return l-d;   
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy)/resolution.y;
    vec3 d1,d2,d3;
    
    d1.x = abs(flowerSDF(uv, time*2., 4., 0.8, 0.6));
    d1.x = 1.-smoothstep(0.0, 0.8, d1.x)-0.7;
    d1.y = heartSDF(uv, time*2., 0.8, 0.)-0.2;
    d1.y = 1.-smoothstep(0.0, 0.8, d1.y);
    d1.z = mix(d1.y, 1.0, d1.x);
    //d1.z = max(d1.y, d1.x);
    
    
    d2.x = abs(flowerSDF(uv, time*8., 5., 0.8, 0.2));
    d2.x = 1.-smoothstep(0.0, 0.6, d2.x)-0.7;
    d2.y = heartSDF(uv, time*8., 0.8, 0.);
    d2.y = 1.-smoothstep(0.0, 0.6, d2.y)-0.2;
    d2.z = mix(d2.y, 1.0, d2.x);
    //d2.z = max(d2.y, d2.x);
    
    d3.x = abs(flowerSDF(uv, -time*4., 6., 0.8, 0.3));
    d3.x = 1.-smoothstep(0.0, 0.6, d3.x)-0.7;
    d3.y = heartSDF(uv, -time*4., 0.8, 0.)-0.2;
    d3.y = 1.-smoothstep(0.0, 0.6, d3.y);
    d3.z = mix(d3.y, 1.0, d3.x);
    //d3.z = max(d3.y, d3.x);
    
    // Output to screen
    glFragColor = vec4(d1.z, d2.z, d3.z, 1.0);
}
