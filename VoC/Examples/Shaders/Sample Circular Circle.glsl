#version 420

// original https://www.shadertoy.com/view/sdySDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;

float atan2(in float y, in float x){
    return x == 0.0 ? sign(y)*PI/2.0 : atan(y, x);
}

float peek(in float x, in float spr, in float target){
    return min(
        spr/((x-target)*(x-target)+0.0000001),
        1.0
    );
}

float rand(float x){
  return fract(sin(dot(vec2(x, x*1.34) ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 ring(float time, float ang, float d, float spr, float p1, float p2){
    vec3 rgb;
    rgb.x = sin(time*p2+ang*1.0);
    rgb.y = cos(time*p2+ang*1.0);
    rgb.z = sqrt(abs(1.5 - abs(rgb.x) - abs(rgb.y)));
    
    float b = 0.05*cos(cos(time));
    float r = 0.15 + b * cos(cos(ang+time*p2) + 0.6*sin(ang*p1));
    
    float ringeff = peek(d, spr, r);
    return ringeff*rgb;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float d = distance(gl_FragCoord.xy, resolution.xy/2.0)/distance(vec2(0.0, 0.0),resolution.xy/2.0);
    vec2 p = gl_FragCoord.xy - resolution.xy/2.0;
    float ang = atan2(p.y,p.x);
    vec3 col;
    
    float time=time*5.0;
    float offset=17.0;
    
    float spr = 0.0000004;
    spr += spr*cos(time*1.0) + spr*0.8;
    
    col = ring(time, ang, d, spr, 4.0, 1.0);
    col += ring(time, ang, d, spr, 3.0, 1.4);
    col += ring(time, ang, d, spr, 5.0, 1.6);
    col += vec3(1.0, 1.0, 1.0) * (1.0 - distance(vec3(0.,0.,0.),col));

    // Output to screen
    glFragColor = vec4(col,1);
}
