#version 420

// original https://www.shadertoy.com/view/ldVyR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define speed 0.9
#define scaleCo 0.35
#define rotation 1.4
#define angleOffset 0.1
#define intensity 3.1
#define outerOffset 0.9

#define PI 3.14159265359
float rectangle(vec2 r, vec2 topLeft, vec2 bottomRight, float blur) {
    float ret;
    ret = smoothstep(topLeft.x-blur, topLeft.x+blur, r.x);
    ret *= smoothstep(topLeft.y-blur, topLeft.y+blur, r.y);
    ret *= 1.0 - smoothstep(bottomRight.y-blur, bottomRight.y+blur, r.y);
    ret *= 1.0 - smoothstep(bottomRight.x-blur, bottomRight.x+blur, r.x);
    return ret;
}

void main(void)
{
    vec2 p = vec2(gl_FragCoord.xy / resolution.xy);
    vec2 r =  2.0*vec2(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;    
    
    vec3 bgCol = vec3(0.85,0.85,1.0);
    vec3 ret = bgCol;
    vec2 q;
    
    for(float i = 20.0; i > 0.0; i--)
    {    
        float angle;
        angle = PI * rotation * sin(speed * time) + length(r) * -cos(speed * (time - outerOffset)) * intensity;
        angle += angleOffset * i;
        vec3 changingColor = 0.5 + 0.5*cos(time+length(r)+vec3(0,2,4));
        
        // q is the rotated coordinate system
        q.x =   cos(angle)*r.x + sin(angle)*r.y;
        q.y = - sin(angle)*r.x + cos(angle)*r.y;
    //q=r;
        float scale = (i * scaleCo);
      
        
        ret = mix(ret, (vec3(0.03 * i, 0.03 * i, 0.15 * i) + changingColor)/2.0 , rectangle(q, vec2(-0.3, -0.5) * scale, vec2(0.3, 0.5) * scale, 0.0002));
        ret = mix(ret, (vec3(0.06 * i, 0.06 * i, 0.15 * i) + changingColor)/2.0 , rectangle(q, vec2(-0.28, -0.48) * scale, vec2(0.28, 0.48) * scale, 0.04));
    }  
    vec3 pixel = ret;
    glFragColor = vec4(pixel, 1.0);
}
