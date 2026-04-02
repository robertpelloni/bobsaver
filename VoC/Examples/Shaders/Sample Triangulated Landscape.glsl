#version 420

// original https://www.shadertoy.com/view/wlsSD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//------------------------------------------------------------------------
// Here rather hacky and very basic sphere tracer, feel free to replace.
//------------------------------------------------------------------------

// fField(p) is the final SDF definition, declared at the very bottom

#define PI 3.14159265

const int iterations = 200;
const float dist_eps = .001;
const float ray_max = 200.0;
const float fog_density = .03;

const float cam_dist = 5.;

float fField(vec3 p);

vec3 dNormal(vec3 p)
{
   const vec2 e = vec2(.005,0);
   return normalize(vec3(
      fField(p + e.xyy) - fField(p - e.xyy),
      fField(p + e.yxy) - fField(p - e.yxy),
      fField(p + e.yyx) - fField(p - e.yyx) ));
}

vec4 trace(vec3 ray_start, vec3 ray_dir)
{
   float ray_len = 0.0;
   vec3 p = ray_start;
   for(int i=0; i<iterations; ++i) {
         float dist = fField(p) / 4.;
      if (dist < dist_eps) break;
      if (ray_len > ray_max) return vec4(0.0);
      p += dist*ray_dir;
      ray_len += dist;
   }
   return vec4(p, 1.0);
}

// abs(0+0-1)=1
// abs(1+0-1)=0
// abs(0+1-1)=0
// abs(1+1-1)=1
float xnor(float x, in float y) { return abs(x+y-1.0); }

vec4 checker_texture(vec3 pos, float sample_size)
{

   
   vec4 path_line_color = vec4(0., 0., 1.0, 1.0); 
   vec4 sep_line_color = vec4(0., 0., 1.0, 1.0);
   vec4 ground_color = vec4(.1, .1, .1, 1.0);
    
   float tile_size = 0.3;
   float line_width = 0.01;
   float tpx = mod(pos.x - line_width / 2., tile_size);
   float tpz = mod(pos.z - line_width / 2., tile_size);
   if (pos.x > 0. && pos.x < 0.6) {
      return vec4(1.0);
   }   
    if (tpx < line_width) {
        return sep_line_color;
    } else if (tpz < line_width) {
        return sep_line_color;
    } else if (tpz + tpx > tile_size && tpz + tpx < tile_size + line_width) {
        return sep_line_color;
    } else {
        return ground_color;
    }
    
    
   pos = pos*8.0 + .5;
   vec3 cell = step(1.0,mod(pos,2.0));
   float checker = xnor(xnor(cell.x,cell.y),cell.z);
   vec4 col = mix(vec4(.4),vec4(.5),checker);
   float fade = 1.-min(1.,sample_size*24.); // very fake "AA"
   col = mix(vec4(.5),col,fade);
   pos = abs(fract(pos)-.5);
   float d = max(max(pos.x,pos.y),pos.z);
   d = smoothstep(.45,.5,d)*fade;
   return mix(col,vec4(0.0),d);
}

vec3 sky_color(vec3 ray_dir, vec3 light_dir)
{
   float d = max(0.,dot(ray_dir,light_dir));
   float d2 = light_dir.y*.7+.3;
   vec3 base_col;
   base_col = mix(vec3(.3),vec3((ray_dir.y<0.)?0.:1.),abs(ray_dir.y));
   return base_col*d2;
}

vec4 debug_plane(vec3 ray_start, vec3 ray_dir, float cut_plane, inout float ray_len)
{
    // Fancy lighty debug plane
    if (ray_start.y > cut_plane && ray_dir.y < 0.) {
       float d = (ray_start.y - cut_plane) / -ray_dir.y;
       if (d < ray_len) {
           vec3 hit = ray_start + ray_dir*d;
           float hit_dist = fField(hit);
           float iso = fract(hit_dist*5.0);
           vec3 dist_color = mix(vec3(.2,.4,.6),vec3(.2,.2,.4),iso);
           dist_color *= 1.0/(max(0.0,hit_dist)+.001);
           ray_len = d;
           return vec4(dist_color,.1);
      }
   }
   return vec4(0);
}

vec3 shade(vec3 ray_start, vec3 ray_dir, vec3 light_dir, vec4 hit)
{
   vec3 fog_color = sky_color(ray_dir, light_dir);
   
   float ray_len;
   vec3 color;
   if (hit.w == 0.0) {
      ray_len = 1e16;
      color = fog_color;
   } else {
      vec3 dir = hit.xyz - ray_start;
      vec3 norm = dNormal(hit.xyz);
      float diffuse = max(0.0, dot(norm, light_dir));
      float spec = max(0.0,dot(reflect(light_dir,norm),normalize(dir)));
      spec = pow(spec, 16.0)*.5;
       
      ray_len = length(dir);
   
      vec3 base_color = checker_texture(hit.xyz,ray_len/resolution.y).xyz;
      color = mix(vec3(0.,.1,.3),vec3(1.,1.,.9),diffuse)*base_color +
         spec*vec3(1.,1.,.9);

      float fog_dist = ray_len;
      float fog = 1.0 - 1.0/exp(fog_dist*fog_density);
      color = mix(color, fog_color, fog);
   }
   
   
    
   float cut_plane0 = sin(time)*.15 - .8;
   for(int k=0; k<4; ++k) {
      vec4 dpcol = debug_plane(ray_start, ray_dir, cut_plane0+float(k)*.75, ray_len);
      //if (dpcol.w == 0.) continue;
      float fog_dist = ray_len;
      dpcol.w *= 1.0/exp(fog_dist*.05);
      //color = mix(color,dpcol.xyz,dpcol.w);
   }

   return color;
}

void main(void)
{
   vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5) / resolution.y;
    
   vec3 light_dir = normalize(vec3(.5, 1.0, -.25));
   
   // Simple model-view matrix:
   float ang, si, co;
   ang = time*.25;
   si = sin(ang); co = cos(ang);
   mat4 cam_mat = mat4(
      co, 0., si, 0.,
      0., 1., 0., 0.,
     -si, 0., co, 0.,
      0., 0., 0., 1.);
   ang = time*.2;
   si = sin(ang); co = cos(ang);
   cam_mat = cam_mat * mat4(
      1., 0., 0., 0.,
      0., co, si, 0.,
      0.,-si, co, 0.,
      0., 0., 0., 1.);

   vec3 pos = vec3(cam_mat*vec4(0., 0., -cam_dist, 1.0));
   vec3 dir = normalize(vec3(cam_mat*vec4(uv, 1., 0.)));
   
   vec3 color = shade(pos, dir, light_dir, trace(pos, dir));
   color = pow(color,vec3(.44));
   glFragColor = vec4(color, 1.);
}

//------------------------------------------------------------------------
// Your custom SDF
//------------------------------------------------------------------------

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p, float unit){
    vec2 ij = floor(p/unit);
    vec2 xy = mod(p,unit)/unit;
    //xy = 3.*xy*xy-2.*xy*xy*xy;
    xy = .5*(1.-cos(PI*xy));
    float a = rand((ij+vec2(0.,0.)));
    float b = rand((ij+vec2(1.,0.)));
    float c = rand((ij+vec2(0.,1.)));
    float d = rand((ij+vec2(1.,1.)));
    float x1 = mix(a, b, xy.x);
    float x2 = mix(c, d, xy.x);
    return mix(x1, x2, xy.y);
}

float bumpy_terrain(vec3 p) {
     float large_scale_noise = noise(vec2(p.x, p.z), 1.) - noise(vec2(0., p.z), 1.);
    float small_scale_noise = noise(vec2(p.x, p.z), .2) - noise(vec2(0., p.z), .2);
    return p.y + 1.0 * cos(p.x) - 0.3 * small_scale_noise - 1.0 * large_scale_noise;   
}

float fField(vec3 p)
{   
    //pMod3(p, vec3(1.));
    float tile_size = 0.3;
    // Snap point x and y. Snapped to the tile below.
    float tpx = mod(p.x, tile_size);
    float tpz = mod(p.z, tile_size);
    float spx = p.x - tpx;
    float spz = p.z - tpz;
    
    float t00 = bumpy_terrain(vec3(spx, p.y, spz));
    float d00t01 = bumpy_terrain(vec3(spx, p.y, spz - tile_size)) - t00;
    float d00t10 = bumpy_terrain(vec3(spx - tile_size, p.y, spz)) - t00;
    float t11 = bumpy_terrain(vec3(spx - tile_size, p.y, spz - tile_size));
    float d11t01 = bumpy_terrain(vec3(spx, p.y, spz - tile_size)) - t11;
    float d11t10 = bumpy_terrain(vec3(spx - tile_size, p.y, spz)) - t11;
    
    if (tpx + tpz > tile_size) {
        return t00 + d00t10 * (1. - tpx / tile_size) + d00t01 * (1. - tpz / tile_size);
    } else {
        return t11 + d11t01 * tpx / tile_size + d11t10 * tpz / tile_size;// + d11t01 * (1. - tpz / tile_size);
    }
    
    
                              
    
    return mod(p.x, tile_size) * bumpy_terrain(vec3(spx, p.y, spz)) + (tile_size - mod(p.x, tile_size)) * bumpy_terrain(vec3(spx - tile_size, p.y, spz));
    //return bumpy_terrain(p);
}
