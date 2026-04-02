#version 420

// original https://www.shadertoy.com/view/7ssSR4

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592

vec3 arm(in vec2 st, float period, float radius, float thickness, vec3 color1, vec3 color2)
{
  float line = (1.0 - smoothstep(radius + .0001, radius - .0001,  st.y)) * (smoothstep(radius + thickness + .0001, radius + thickness - .0001,  st.y));
  float phase = step(.5, fract(date.w/period / 2.0)) - .5;
  float p1 = step(sign(phase), 0.0); 
  float p2 = step(-sign(phase), 0.0); 
  
  float x = (fract(date.w/period) + st.x + .5) - 1.0;
  float x2 = (-fract(date.w/period) - st.x + .5);
  float c = clamp(sign(x), 0.0, 1.0);
  float c2 = clamp(sign(x2), 0.0, 1.0);
  
  vec3 col1 = (p1*color1) + (p2*color2);
  vec3 col2 = (p2*color1) + (p1*color2);
  
  vec3 out1 = (line * c * col1);
  vec3 out2 = (line * c2 * col2);
  return vec3(out2 + out1);
}

// Rotates cartesian coordinate system
vec2 rotate2d(in vec2 st, in float angle)
{
    return st * mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

// Maps a cartesian coordinate system to a polar one
vec2 map2Circle(in vec2 st)
{
    return vec2(atan(st.y, st.x), length(st)) / (2. * PI);
}

void main(void)
{
    // Normalized pixel coordinates (from -0.5 to .5)
    vec2 st = ( gl_FragCoord.xy - .5* resolution.xy) / min(resolution.x, resolution.y);
    st = rotate2d(st, PI/2.0);      // Rotate 90 degrees to make clock start at top
    st = map2Circle(st);            // Change coordinate system to polar coordinates
    
    vec3 color1 = vec3(1.0, 0.0, 0.0);
    vec3 color2 = vec3(.4, 0.0, 0.0);
    vec3 img = arm(st, 60.0, .0465, .0056, color1, color2); // seconds
    
    color1 = vec3(1.0, 0.7, 0.0);
    color2 = vec3(.8, 0.4, 0.0);
    img += arm(st, 60.0 * 60.0, .04, .005, color1, color2); // minutes
    
    color1 = vec3(0.8, 0.0, 1.0);
    color2 = vec3(0.4, 0.0, 0.6);
    img += arm(st, 60.0 * 60.0 * 12.0, .034, .0045, color1, color2); // hours
    
    img = max(vec3(0.0, 0.0, 0.1), img); // Add background
   
    // Output to screen
    glFragColor = vec4(img, 1.0);
}
