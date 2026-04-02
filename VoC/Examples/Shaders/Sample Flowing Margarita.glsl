#version 420

// original https://www.shadertoy.com/view/3tfGDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// originally adapted from http://www.peda.com/grafeq/gallery/margarita.html

#define PI 3.14159265359
#define SCALE 60.0

float f(float a, vec2 p)
{
      float cf = 2.0 - cos(0.1 * time);
      float d = (length(p) - 3.5 * atan(p.y, p.x) + sin(cf * p.x) + cos(cf * p.y))/(a * PI);
     
      return smoothstep(0.0, 0.2, 0.5 * cos(PI * (2.0 * d - time)));
}

void main(void)
{
        vec2 aspect = resolution.xy / resolution.y;
        vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
        uv *= SCALE;
        
        vec3 col = mix(vec3(0.29, 0.22, 0.48), vec3(0.88, 0.03, 0.11), f(7.0, uv));
        col = mix(vec3(0.9, 0.87, 0.63), col, f(1.0, uv));

        col *= 1.0 - 0.1 * length(gl_FragCoord.xy/resolution.xy - 0.5); // vignetting
        glFragColor = vec4( col, 1.0 );
}
