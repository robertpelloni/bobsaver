#version 420

uniform vec2  resolution;     // resolution (width, height)
uniform vec2  mouse;          // mouse      (0.0 ~ 1.0)
uniform float time;           // time       (1second == 1.0)
uniform sampler2D backbuffer; // previous scene

out vec4 glFragColor;

const float PI = 3.15;

vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

vec3 BlueSpecial(float t, float s){
    vec3 color;
    float wavval =  0.05 * ((sin(t * 0.0575) + 1.0) / 2.0) + 0.60;
    color = hsv(wavval , 0.88, s);
    return color;
}

vec3 MagentaSpecial(float t, float s){
    vec3 color;
    float wavval =  0.05 * ((sin(t * 0.0575) + 1.0) / 2.0) + 0.90;
    color = hsv(wavval , 0.88, s);
    return color;
}
vec3 YellowSpecial(float t, float s){
    vec3 color;
    float wavval =  0.05 * ((sin(t * 0.0575) + 1.0) / 1.0) + 0.1;
    color = hsv(wavval , 1.48, s);
    return color;
}
void main(){
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / resolution;
    vec3 line = vec3(0.0);
    
    for(float fi = 0.0; fi < 5.0; ++fi){
        float offset = fi * PI / 1.0;        
        float value = 1.0 - sin(time * fi * 0.15 + 0.1) * 0.5 ;
        float timer = atan(time)*30. * sin(fi) * 0.08*sin(p.x)*sin(time);
        line += 0.04 / abs(atan(p.y) + sin(atan(p.x*sin(time*2.5)) * 1.0 + timer + offset) *0.75) * BlueSpecial(fi + time*1.5 ,value);
        line += 0.01 / abs(atan(p.y) + sin(atan(-p.x*sin(time*2.5)) * 1.0 + timer + offset) * 0.75) * MagentaSpecial(fi + time*3.5 ,value);   
    line += 0.01 / abs(atan(p.y) + sin(atan(-p.y*sin(time*2.5)) * 1.0 + timer + offset) * 0.75) * YellowSpecial(fi + time*4.5 ,value);   
    }
    
    glFragColor = vec4(line*line*0.5, 1.0);
}
