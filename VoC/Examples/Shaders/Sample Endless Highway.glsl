#version 420

// original https://www.shadertoy.com/view/dsyXDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float atan2(in float y, in float x)
{
    return x == 0.0 ? sign(y)*PI/2.0 : atan(y, x);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 coords = uv*2.0 - 1.0;
    coords.y *= resolution.y / resolution.x;
    
    
    vec3 clr = vec3(0);
    int iter = 100;
    for (int i=0; i<iter; i++) {
        float t = rand(vec2(i, 1.0));
        
        float scale = rand(vec2(t, 1.0)) + 1.0;
        float x = rand(vec2(scale, 1.0))*2.0 - 1.0;
        float y = rand(vec2(x, 1.0))*2.0 - 1.0;

        float d = sdBox(coords+vec2(x,y), vec2(0.1, 0.1));
        
        if (abs(d-scale) < 0.05) {
            float r1 = rand(vec2(y, 1.0));
            float g1 = rand(vec2(r1, 1.0));
            float b1 = rand(vec2(g1, 1.0));
            
            float r2 = rand(vec2(b1, 1.0));
            float g2 = rand(vec2(r2, 1.0));
            float b2 = rand(vec2(g2, 1.0));
            
            float rx = coords.x + x;
            float ry = coords.y + y;
            float angle = abs(atan2(ry, rx)+PI);
        
            clr = vec3(float(i)/float(iter));
            clr *= float((abs(d-scale) > 0.005 || sin(angle*100.0) > 0.0) && abs(d-scale) < 0.045);
            
            float s1 = 1.0+rand(vec2(b2, 1.0));
            float r_angle = fract(time*0.1*s1 + rand(vec2(s1, 1.0)))*2.0*PI;
            float angle_sdf = min(abs(angle-r_angle), min(abs(angle+2.0*PI-r_angle), abs(angle-2.0*PI-r_angle)));
            if (angle_sdf < 0.02 && d-scale > 0.01 && d-scale < 0.04) {
                clr *= vec3(r1,g1,b1);
            }
            
            float s2 = 1.0+rand(vec2(s1, 1.0));
            r_angle = (1.0-fract(time*0.1*s2 + rand(vec2(s2, 1.0))))*2.0*PI;
            angle_sdf = min(abs(angle-r_angle), min(abs(angle+2.0*PI-r_angle), abs(angle-2.0*PI-r_angle)));
            if (angle_sdf < 0.02 && d-scale < -0.01 && d-scale > -0.04) {
                clr *= vec3(r2,g2,b2);
            }
        }
    }    
    
    glFragColor = vec4(clr,1.0);
}
