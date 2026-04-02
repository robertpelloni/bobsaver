#version 420

// original https://www.shadertoy.com/view/slf3RS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 m;

const float h = 0.9;
const mat2 skew = mat2( 1.0, 0.5/h, 0.0, 1.0/h) ;
const mat2 unskew = mat2( 1.0, -0.5, 0.0, h);

vec4 tri_grid2(vec2 uv, const float peakY , const float peakZ, float seam_comp) {

  uv *= skew;

  // repeat
  uv = fract(uv);
  vec2 seamv = min(abs(uv),abs(uv-1.0));
  float seam = min(seamv.x,seamv.y);
  
  // up or down triangle
  float d = uv.x-uv.y; 
  seam = min(abs(d),seam);
  d = sign(d);

  // local coordinates
  uv *= unskew;
  uv.y*=d;
  uv+= d>0.0 ? vec2(-0.5,.0) : vec2(0.0,h);
  
  // faces
  vec2 vs1 = normalize(vec2(1.0,peakY));
  vec2 vs2 = normalize(vec2(-1.0,peakY));

  float s1 = dot(uv-vec2(-0.5,0.0),vec2(vs1.y,-vs1.x));
  float s2 = dot(uv-vec2(.5,0.0),vec2(vs2.y,-vs2.x));

  vec4 normal;
  if(s1>0.0 && s2<0.0) {
    normal=vec4(normalize(cross(vec3(vs1,peakZ),vec3(vs2,peakZ))),1.0);
    seam = min(s1,seam);
    seam = min(-s2,seam);
  } else if(uv.x < 0.0) {
    normal=vec4(normalize(cross(vec3(vec2(0.0,-1.0),peakZ),vec3(vs1,peakZ))),0.0);
    seam = min(-s1,seam);
    seam = min(-uv.x,seam);
  } else {
    normal=vec4(normalize(cross(vec3(vs2,peakZ),vec3(vec2(0.0,-1.0),peakZ))),0.0);
    seam = min(uv.x,seam);
    seam = min(s2,seam);
  }

  normal.y*=d;
  return vec4(mix(vec3(0.0,0.0,0.3),normal.xyz,smoothstep(0.0,seam_comp,seam)),normal.w);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 *  resolution.xy) / resolution.y;
    m = vec4(0.0);//mouse.xy*resolution.xy / resolution.xy;
 
    float w = 4.0*pow(sin(
      (1.0+length(uv.x*cos(time*0.5)*3.0+uv.y*sin(time*0.7)*2.0))
      -0.2*time),8.0);

    vec2 uvs = uv*skew;
    vec2 grid = (uvs.x-uvs.y) > 0.0 ? vec2(8.0,0.01) : vec2(24.0,0.03);

    vec4 normal = tri_grid2(uv*grid.x, w, 0.6*sin(0.5-length(uv*2.0)+time*0.2), grid.y);

    vec3 lightDir = normalize(vec3(sin(time*0.5)*50.0, cos(time*0.7)*30.0, 100.0));

    vec3 c = normal.w >0.0 ? vec3(1,0.24,0.2) : vec3(1.0);
    glFragColor = vec4(vec3(dot(normal.xyz,lightDir))* c,1.0);
}
