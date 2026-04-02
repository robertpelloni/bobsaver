#version 420

// original https://www.shadertoy.com/view/ltXfRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://github.com/hughsk/glsl-hsv2rgb/blob/master/index.glsl
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float checker(vec2 p, vec2 size)
{
    return mod(floor(p.x * size.x)+floor(p.y * size.y),2.0);
}

void main(void)
{
    vec3 col = vec3(0.0);
    
    vec2 uv = (gl_FragCoord.xy / resolution.xy);
    uv.x += sin(time*0.23) * 0.2;
    uv.y += sin(time*0.37) * 0.3;
    
    vec2 size = vec2(16.0,9.0) * (0.15 + sin(time * 0.33) * 0.04);
    vec3 c = vec3(0.4,0.05,0.2);
    float m = 1.0;
    vec3 hsv = vec3(0.5,0.7,1.0);
    float ii = 1.0;
    //float a = 0.02;//sin(time*0.5) * 0.3;
    //mat3 rot = mat3(cos(a),-sin(a),0.0,sin(a),cos(a),0.0,0.0,0.0,1.0);
    
    for (int i=0;i<10;i++){
        
        float ch = checker(uv*m,size*m);
        
        if (ch > 0.5){
            col = hsv2rgb(hsv);
            break;
        }
        
        uv.x += (sin(time/(ii*4.0))*0.01 + sin(ii)*0.5) / m;
        uv.y += (sin(time/(ii*3.8))*0.01 + cos(ii)*0.5) / m;
        
        //uv = (vec3(uv,1.0) * rot).xy;
        
        m+=(0.6 + sin(time * 0.1) * 0.59);
        ii+=0.01;
        
        hsv.x += 0.02;
        hsv.z *= 0.92;
    }
    

    
    glFragColor = vec4(col,1.0);
}
