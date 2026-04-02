#version 420

// original https://www.shadertoy.com/view/stByRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323

#define mode int(time)%8
#define S(v,l) smoothstep( -.7*fwidth(v), .7*fwidth(v), abs(fract(v +.5)-.5) -  (l) / (2.*PI)/2. )

vec3 hrgb (float h, float m)
{
    vec3 c;
    float mm;
    float p;
    
    c.r =  0.5 - 0.5 * sin(2.0 * PI * h - PI / 2.0);
    c.g = (0.5 + 0.5 * sin(2.0 * PI * h * 1.5 - PI / 2.0)) * float(h < 0.66);
    c.b = (0.5 + 0.5 * sin(2.0 * PI * h * 1.5 + PI / 2.0)) * float(h > 0.33);
    
    mm = fract(m); //mod(m * 100.0, 100.0) * 0.01;
    p = fract(mod(h,1.0/16.0));
     
    c.r -= (0.35*mm + 2.5*p);
    c.g -= (0.35*mm + 2.5*p);
    c.b -= (0.35*mm + 2.5*p);
    
    
    return c;
}

void main(void)
{
    vec2 s = resolution.xy;
    vec2 q = gl_FragCoord.xy;
    vec2 uv, p;
    vec2 z, w, f;
    uv = q - s/2.;//vec2(q.x - s.x/2.0, s.y/2.0 - q.y);
    
    uv *= 0.02;
                
    f.x = 1.5*cos(time);
    f.y = 3.0*sin(time);
    
    z = uv - f;
    
    p = z * mat2(uv,-uv.y,uv.x) / dot(uv,uv);
                
                
    f.x = 3.0*cos(-time - PI);
    f.y = 1.5*sin(-time - PI);    
    
    z = uv - f;
    
    p = mat2(p,-p.y,p.x) * z;
             

    float m = length(p);
    float a = (PI + atan(p.y, p.x)) / (2.0 * PI);
    glFragColor = vec4(hrgb(a,m), 1.0);

}
