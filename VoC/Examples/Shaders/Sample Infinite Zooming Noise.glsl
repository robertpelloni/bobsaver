#version 420

// original https://www.shadertoy.com/view/4tKXD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// snoise from https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83

vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

// number of octaves of noise
#define octaves        4
// zoom level between each successive octave
#define octave_zoom 20.0
// how long in seconds it takes to zoom in one octave
#define zoom_time   2.0
// scaling multiplier of the zoomiest octave
#define base_zoom   1.0

void main(void)
{
    glFragColor=vec4(0.0);
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    float timeI = floor(time / zoom_time);
    float timeF = mod(time, zoom_time) / zoom_time;
    float zoom = base_zoom / pow(octave_zoom, timeF);
    for(int i=0; i<octaves; i++) {
        // linear interpolate contribution from last and first octaves to make it supersmooth <3
        // ?? use zoom to fade out when zoom gets  or above level where moire appears ??
        // ?? interpolate using sin so middle octaves get most contribution ??
        float contrib = i==0 ? (1.0-timeF) : i==octaves-1 ? timeF : 1.0;
        // offset ensures infinite randomness as octaves no longer repeat :D
        vec2 offset = vec2(float(i) + timeI);
        glFragColor += contrib * (0.5 * vec4(snoise(uv * zoom + offset)));
        zoom *= octave_zoom;
        
        // TODO make it zoom in on the mouse location :v
    }
}
