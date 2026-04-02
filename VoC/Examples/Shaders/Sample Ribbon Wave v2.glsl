#version 420

// original https://www.shadertoy.com/view/sl2czV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float TAU = 2.0*3.14159256;
void main(void)

{
   vec2 uv = gl_FragCoord.xy/resolution.xy;
   vec3 col = vec3(0);  
   for(float i=0.2; i<.8; i+=0.05){
     float off = TAU-10.0*i;
     float damp = abs(uv.x-.5);
     float curve = i + 0.11*pow((1.0-damp),5.0)*sin((40.0 * uv.x + off) - (2.0 * time));
     // float sinSDF = distance(uv.y,curve)-.01;    
     float sinSDF = abs(uv.y-curve) -.01;
     float pix=2./resolution.y;
     col = mix(vec3(1.0+pow((1.0-damp),5.0)*sin(40.*uv.x+off - 2.0*time)), col, smoothstep(-pix, +pix, sinSDF));
   }
    glFragColor = vec4(col, 1.0);
}

