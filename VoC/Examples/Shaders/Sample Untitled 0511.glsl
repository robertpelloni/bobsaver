#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float u_time = time;
vec2 u_mouse = mouse;
vec2 u_resolution = resolution;

const int TV_MODE_SCANLINES = 1;
const int TV_MODE_SLANT = 2;

const float rgbPixZoom = 1.0;
const float scanlineStep = 4.0;
const float scanlineIntensity = 0.7;

//const int tvMode = TV_MODE_SLANT;
const int tvMode = TV_MODE_SCANLINES;

void main( void ) {
  vec2 spd = vec2(
    2.0 * sin( ( (4.1*sin(u_time/(6.5*u_time))-10.2) + (5.4*sin(u_time/12.0)+10.0) + (4.2*sin(u_time/12.10)+0.00) + (1.00*sin(u_time*(0.00125*sin(u_time/2.3)+0.49))) ) / 2.0),
    2.0 * cos( ( (4.0*cos(u_time/(6.0*u_time))-12.2) + (5.5*cos(u_time/12.0)+10.0) + (8.0*cos(u_time/13.23)+0.00) + (1.00*sin(u_time*(0.00125*sin(u_time/3.1)+0.50))) ) / 2.0)
  );
  
  vec2 pos = vec2(
    (gl_FragCoord.x - u_resolution.x/2.0) * spd.x / u_resolution.x / (0.25*sin(u_time/1.3)+1.0) / 0.50,
    (gl_FragCoord.y - u_resolution.y/2.0) * spd.y / u_resolution.y / (0.25*cos(u_time/1.0)+3.0) / 0.50
  );

  // x,y wobble
  // pos.x += (sin(u_time*2.0)) / 20.0;
  // pos.y += (sin(u_time*2.0)) / 20.0;
  
  float diagonalPos = 1.66 * sin(length(vec2(pos.x, pos.y)));

  vec4 image = vec4(
    // sin(spd.x+pos.x*15.0),
    // sin(spd.y+pos.y*16.0)*cos(spd.y+pos.y*16.0),
    // sin(spd.y*diagonalPos*17.0),
    // cos(pos.y*(0.50-diagonalPos)*20.0) * cos(spd.y*(0.50-diagonalPos)*20.0) + 1.0,
    // sin(pos.y*(0.75-diagonalPos)*23.0) * sin(spd.y*(0.75-diagonalPos)*23.0) + 1.0,
    // sin(pos.y*(1.00-diagonalPos)*21.0) * cos(spd.y*(1.00-diagonalPos)*21.0) + 1.0,
    sin(pos.y*(0.80-diagonalPos)*20.0) * cos(spd.y*(0.80-diagonalPos)*20.0) + 1.0,
    sin(pos.y*(0.90-diagonalPos)*23.0) * cos(spd.y*(0.90-diagonalPos)*23.0) + 1.0,
    sin(pos.y*(1.00-diagonalPos)*21.0) * cos(spd.y*(1.00-diagonalPos)*21.0) + 1.0,
    1.0
  );

  image *= vec4(
    sin(pos.x+spd.x+(0.9-diagonalPos)*20.0) * cos(pos.y*spd.y/(0.9-diagonalPos)*20.0),
    cos(pos.x+spd.x+(0.8-diagonalPos)*21.0) * cos(pos.y*spd.y/(0.8-diagonalPos)*19.0),
    sin(pos.x+spd.x+(1.0-diagonalPos)*19.0) * sin(pos.y*spd.y/(1.0-diagonalPos)*21.0),
    1.0
  );
  
  vec4 colorAdjust = vec4(1.66, 1.1, 1.5, 1.0);

  image = clamp(image*colorAdjust, 0.0, 1.0);

  float rgbPos; // 0-red, 1-blue, 2-green
  vec4 rgbFilter;
  
  // rotate R, G and B pixels based on scanline
  if (tvMode == TV_MODE_SLANT) {
    float rgbShift = floor(mod((u_resolution.y-gl_FragCoord.y)/rgbPixZoom, 3.0));
    rgbPos = floor(mod(gl_FragCoord.x/rgbPixZoom+rgbShift, 3.0)); 
    rgbFilter = vec4(
      float(rgbPos == 0.0),
      float(rgbPos == 1.0),
      float(rgbPos == 2.0),
      1.0
    );
  } else if (tvMode == TV_MODE_SCANLINES) {
    float lineIndex = floor(mod((u_resolution.y-gl_FragCoord.y)/rgbPixZoom, scanlineStep));
    bool  isScanline = lineIndex == (scanlineStep-1.0);
    rgbPos = floor(mod(gl_FragCoord.x/rgbPixZoom, 3.0));
    rgbFilter = vec4(
      float(rgbPos == 0.0) * (isScanline ? scanlineIntensity : 1.0),
      float(rgbPos == 1.0) * (isScanline ? scanlineIntensity : 1.0),
      float(rgbPos == 2.0) * (isScanline ? scanlineIntensity : 1.0),
      1.0
    );
  } else {
    rgbFilter = vec4(1.0, 1.0, 1.0, 1.0);
  }
  
  glFragColor = image * colorAdjust * rgbFilter;
  //glFragColor = vec4( vec3( color, color * 0.50, sin( color + time / 3.0 ) * 0.75 ), 1.0 );

}
