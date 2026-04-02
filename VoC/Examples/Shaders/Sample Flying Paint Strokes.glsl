#version 420

// original https://www.shadertoy.com/view/MstfWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// -------------------------------------------------------
// ---------------  Flying paint strokes -----------------
// Francois 'CoyHot' Grassard, May 2018
// My first real attempt with Raymarching / Sphere Tracing
// -------------------------------------------------------

float map(vec3 p)
{
  // Define some temporal and/or spatial references 
  float a =sin(time);
  float b = p.z/6.0;
  float c = 0.75+(sin((time*p.z)*3.)/12.);
  float d = time/5.;

  // --> Reminder : The next steps have to be read from bottom to top <--

  // Rotate the whole scene
  p.xy *= mat2(cos(d), sin(d), -sin(d), cos(d));

  // Add turbulences on each axes, based on Z value
  p.x += cos(b)*7.;
  p.y += sin(b)*7.;
  p.z += sin(b)*7.;

  // Twist the whole scene alond Z axis
  p.xy *= mat2(cos(b), sin(b), -sin(b), cos(b));

  // Scatter strokes in space to avoid all strokes to be aligned
  p = vec3(p.x+cos((p.z)),p.y+sin((p.z)),p.z);
  p = vec3(p.x+cos(p.y),p.y+cos(p.x),p.z);

  // Multiply Strokes
  p = mod(p,16.0)-8.0;

  // Rotate strokes globaly, base on global time. On Z AXIS !!!!
  p.xy *= mat2(cos(cos(a)), sin(cos(a)), -sin(cos(a)), cos(cos(a)));

  // Rotate each stroke, based on there own Z Value and global time
  p.xz *= mat2(cos(c*3.), sin(c*3.), -sin(c*3.), cos(c));

  // Add another sin/cos Noise on the surface, also based on Z value, to add some smaller details on the surface (to mimic the tail of the stroke)
  p.z += (sin(p.x*25.+time)/40.);
  p.z += (cos(p.y*25.+time)/40.);

  // Rotate the whole shape, based on time
  p.xy *= mat2(cos(a), sin(a), -sin(a), cos(a));

  // Add sin/cos Noise on the surface, based on Z value
  p.z += (sin(p.x*15.+time)/5.);
  p.z += (cos(p.y*15.+time)/5.);

  // Return the distance, including a final turbulence based on sin(time) and Z
  return length(p) - sin((time+p.z)*2.0)-.25;
}

float trace (vec3 o, vec3 d)
{
  float t=0.; // Used as a near clipping value (check it with a value of 20.)
  for(int i = 0; i< 128; i++)
  {
    vec3 p = o+d*t;
    float d = map(p);
    t += d*0.075;
  }
  return t;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
    
    
    // 2D Displacement based on texture (produced Tweaked UV) : First Texture
    // vec4 tex1 = texture(iChannel0, vec2(uv.x,uv.y+time/15.));
    // uv.x += tex1.r/5.5*uv.x;
    // uv.y += tex1.r/5.5*uv.y;
    

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Camera and ray direction
    vec3 pc = vec3(0.+sin(time)*1.0,0.+cos(time)*1.0,time*50.);
    vec3 ray = normalize(vec3(uv*1.5,1.));

    vec3 pixel = vec3(trace(pc,ray));

    // Add some Color, based on Tweaked UV
    pixel.r += uv.x*25.;
    pixel.g += uv.y*25.;
    pixel.b += uv.x*-25.;

    // Multiply the color by the fog
    vec3 fog = 1.0/(1.0+pixel*pixel/10.0)-0.001;    
    
    // Output to screen
    glFragColor = vec4(pixel*fog,1.0);
}
