#version 420

// original https://www.shadertoy.com/view/XtsyRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rotation = 180.0;
float offsetIntensity = 5.5;
//float offsetIntensity = 5.5; //best

float random (in vec2 st)
{ 
      return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123); 
}

float noise (in vec2 st)
{
  vec2 i = floor(st);
  vec2 f = fract(st);

  // Four corners in 2D of a tile
  float a = random(i);
  float b = random(i + vec2(1.0, 0.0));
  float c = random(i + vec2(0.0, 1.0));
  float d = random(i + vec2(1.0, 1.0));

  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

#define OCTAVES 16

float fbm (in vec2 st)
{
  // Initial values
  float value = 0.0;
  float amplitude = 1.;
  float frequency = 2.;
  //
  // Loop of octaves
  for (int i = 0; i < OCTAVES; i++)
  {
    value += amplitude * noise(st);
    st *= 3.;
    amplitude *= .5;
  }
    
  return value;
}

vec4 mainNoise(vec2 uv)
{
    //return vec4( fbm(uv * (vec2(0.5) + (fbm(uv) * offsetIntensity)) ) ); //multi layered noise
    
    return vec4( fbm(uv + (fbm(uv) * offsetIntensity) ) ); //main effect by 1.0 to 0.3/0.5
}

vec2 rotate(vec2 uv, float a)
{
    return vec2(uv.x*cos(a)-uv.y*sin(a),uv.y*cos(a)+uv.x*sin(a));
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy;

    vec2 uv = p*vec2(resolution.x/resolution.y,1.0);

    
    float f = 0.0;

    uv *= 1.0;

    f  = 0.5000 * mainNoise( 1.0*uv ).r; uv = rotate(uv, radians(-rotation * 0.1));
    f += 0.2500 * mainNoise( 4.0*uv ).r; uv = rotate(uv, radians(-rotation * 0.3));
    f += 0.02500 * mainNoise( 8.0*uv ).r; uv = rotate(uv, radians(rotation * 0.5));
    f += 0.00125 * mainNoise( 16.0*uv ).r; uv = rotate(uv, radians(rotation * 1.0));
    
    f += 0.0250 * mainNoise( 32.0*uv ).r; uv = rotate(uv, radians(rotation * 0.4));
    f += 0.0150 * mainNoise( 64.0*uv ).r; uv = rotate(uv, radians(rotation * 0.4));
    
    f = 0.8*f; //adjust brightness

    
    glFragColor = vec4( vec3(f), 1.0 );
    
}

