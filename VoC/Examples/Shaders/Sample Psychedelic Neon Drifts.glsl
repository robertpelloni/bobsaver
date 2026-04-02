#version 420

// original https://www.shadertoy.com/view/7llGRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float c (float oldCos) {
     float newCos = 0.5 + 0.5*cos(oldCos*3.141592);
     return newCos;
     }

float s (float oldSin) {
    float newSin = 0.5 + 0.5*sin(oldSin*3.141592);
    return newSin;    }

void main(void)
{
vec2 uv = gl_FragCoord.xy/resolution.xy;  // Normalized pixel coordinates (from 0 to 1)
//   uv -= 0.5;                           // remap so 0,0 is in the middle of the screen.

float x = uv.x;
float y = uv.y;
float o = time * 0.25;     

// Time varying pixel color
float r = s(s((s(y)-c(x))+c((o*0.28081)))*2.0 + s(s(o+3.0*(y+x)) + s(4.0*x+s(o))));
float g = s(c(c(r)-(x*1.8713) + c(y-x))*2.1);
float b = c(s( c(r)-(g*0.4712))*2.2);
vec3 col = vec3(r, g, b);

// Output to screen
glFragColor = vec4(col,1.0);
    
}
