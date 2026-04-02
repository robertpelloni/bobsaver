#version 420

// original https://www.shadertoy.com/view/lsfSz8

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// Julia Squid by - JLasor
vec2 center = vec2(0.0, 0.0);
float mag = 0.2;
const int iter = 100;

void main(void)
{
      vec2 p = gl_FragCoord.xy / resolution.xy; 
      vec2 z, c; 
      float t1 = 0.1*time; 
      float t2 = 0.2*time; 
      vec2 cc = vec2(0.5*cos(t1) - 0.25*cos(t2),  0.5*sin(t1) - 0.25*sin(t2)); 

      c = (p - 0.5)/(mag+0.25) + center; 
      c.x *= (resolution.x/resolution.y); 

      z = c; 
      vec4 dmin = vec4(100.0); 
      cc = cc * p + vec2(-0.05, 0.02);
      for (int i = 0; i<iter; i++) 
      { 
        z = vec2(z.x*z.x - z.y*z.y, z.x*z.y * 2.0) + cc;

        dmin = min(dmin, vec4(abs(z.yx + 0.25*sin(z)),
                              dot(z, z), 
                              length(fract(z) - 0.5))); 
    } 
    vec3 color = vec3(dmin.w); 
    color = mix(color, vec3(0.30, 0.00, 0.00), min(1.0, pow(dmin.x*0.05, 0.20))); 
    color = mix(color, vec3(0.00, 0.20, 0.40), min(1.0, pow(dmin.y*0.750, 0.750))); 
    color = mix(color, vec3(0.95, 0.05, 0.00), 1.0 - min(1.0, pow(dmin.z*2.00, 0.25)));  

    color = 1.25*color*color;  

    color *= 0.5 + 0.5*pow(16.0*p.x*(1.0 - p.x)*p.y*(1.0 - p.y), 0.15);  

    glFragColor = vec4(color, 1.0); 
}  
