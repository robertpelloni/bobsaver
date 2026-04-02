#version 420

// original https://www.shadertoy.com/view/Ms2BWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
float f,z,z0;
const float n = 40.;

vec2 xy0 = resolution.xy/2.;
float time = time*0.25;
float h = resolution.x/32.;
float r0 = resolution.x/5.5;    // Step of waves
float r1 = resolution.x/10.5;    // Height of waves
float phi = 35.;

float pi = 3.14159265;
float p180 = pi / 180.;

float sf = sin(phi * p180);
float cf = cos(phi * p180);

mat2 trot = mat2(cos(time),sin(time),-sin(time),cos(time));

vec2 xy = vec2(0.);
vec2 r = vec2(0.);
vec3 col = vec3(0.);

xy.x = gl_FragCoord.x - xy0.x;      

z0 = -10000.;

for(float j=0.; j<=n; j++)
  {
  xy.y = abs(xy.x) - n * h + 2. * h * j;
  for(int i=0; i<=1; i++)
    {
    r = xy * trot;
    r.y += sign(r.x) * r0;
    f = cos(pi * length(r) / r0);

    z = xy.y * sf + f * r1 * cf;
    if(z > z0)
        {
        if( abs(xy0.y+z-gl_FragCoord.y) < 2.-.5*abs(f) )
        col = smoothstep(.33, .66, abs(mod(vec3(f+.33,f-.33,f+1.),2.)-1.));
        z0 = z + 1.;
        }
    xy.y += mod(n * h - abs(xy.x), h) * 2.;    
    }
  if(j > n - abs(xy.x) / h) break;
  }
glFragColor = vec4(col,1.);
}
