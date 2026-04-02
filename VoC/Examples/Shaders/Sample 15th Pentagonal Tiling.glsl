#version 420

// original https://www.shadertoy.com/view/4lBXRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Pentagonal tiling of type 15th
// by Tomkh @2015

// Prototyped in PolyCube:
//   http://polycu.be/edit/?h=OewoGS - derivation of unit cell and BSP
//   http://polycu.be/edit/?h=ckcP5s - shader

// Background:
//   One pentagonal prototile can cover a plane.
//   This is a newly discovered type of pentagonal tiling,
//   few months ago only 14 types were known.

// Method used:
//   First tiles and edges in unit cell are found,
//   then BSP is calculated for the edges,
//   and generated into shader code.

// Do you like colors? 
//  Put 0 if not ;)
//  Put 1 for unique coloring
//  Put 2 for isohedral coloring
#define USE_COLORS 2

const int iterations = 64;
const float dist_eps = .001;
const float ray_max = 200.0;
const float fog_density = .04;
const float fog_start = 16.;

const float cam_dist = 13.5;

//---------------------------------------------
// Tiling code

#define N 5
vec3 edge[N];
mat3 u2t[24];
mat3 s2u, u2s;

#define REC0(nx,ny,nd) n=vec3(nx,ny,nd);d=dot(n.xy,q)-n.z;if(d<0.){
#define REC1 }else{
#define END }
#define LEAF0(nx,ny,nd,type,tile) REC0(nx,ny,nd) c=type; m=u2t[tile];
#define LEAF1(type,tile) REC1 c=type; m=u2t[tile];

void initTiling()
{
// Auto-generated unit cell, tile transformations and edges
u2s = mat3(8.175694346,-9.400439218,0,2.638958434,0.707106781,0,0,0,1);
s2u = mat3(0.023116785,0.307319821,0,-0.086273015,0.267280376,0,0,0,1);
u2t[0] = mat3(0.866025404,-0.5,0,-0.5,-0.866025404,0,-0.448287736,-1.673032607,1);
u2t[1] = mat3(0.5,0.866025404,0,0.866025404,-0.5,0,2.897777479,-3.60488426,1);
u2t[2] = mat3(0.5,-0.866025404,0,0.866025404,0.5,0,2.897777479,3.60488426,1);
u2t[3] = mat3(1,0,0,0,1,0,0,0,1);
u2t[4] = mat3(0.866025404,0.5,0,-0.5,0.866025404,0,-2.380139389,-0.258819045,1);
u2t[5] = mat3(0.866025404,-0.5,0,-0.5,-0.866025404,0,-2.380139389,0.258819045,1);
u2t[6] = mat3(0.5,0.866025404,0,0.866025404,-0.5,0,0.965925826,-5.536735913,1);
u2t[7] = mat3(0.866025404,0.5,0,0.5,-0.866025404,0,0.258819045,-6.243842694,1);
u2t[8] = mat3(0.5,-0.866025404,0,0.866025404,0.5,0,0.965925826,5.536735913,1);
u2t[9] = mat3(-0.866025404,-0.5,0,-0.5,0.866025404,0,1.673032607,6.243842694,1);
u2t[10] = mat3(1,0,0,0,1,0,-2.638958434,-0.707106781,1);
u2t[11] = mat3(0.5,0.866025404,0,0.866025404,-0.5,0,-0.965925826,-7.468587565,1);
u2t[12] = mat3(0.866025404,0.5,0,0.5,-0.866025404,0,-2.380139389,-6.950949475,1);
u2t[13] = mat3(-1,0,0,0,-1,0,1.931851653,0,1);
u2t[14] = mat3(-1,0,0,0,-1,0,10.107545999,-9.400439218,1);
u2t[15] = mat3(-0.866025404,-0.5,0,0.5,-0.866025404,0,11.073471825,-3.346065215,1);
u2t[16] = mat3(-0.866025404,0.5,0,0.5,0.866025404,0,11.073471825,3.346065215,1);
u2t[17] = mat3(-0.5,-0.866025404,0,-0.866025404,0.5,0,-2.121320344,7.916875301,1);
u2t[18] = mat3(-0.866025404,-0.5,0,-0.5,0.866025404,0,4.311991041,6.950949475,1);
u2t[19] = mat3(-0.5,0.866025404,0,-0.866025404,-0.5,0,-2.121320344,-7.916875301,1);
u2t[20] = mat3(-0.866025404,-0.5,0,0.5,-0.866025404,0,13.005323478,-1.414213562,1);
u2t[21] = mat3(-0.866025404,0.5,0,0.5,0.866025404,0,13.005323478,1.414213562,1);
u2t[22] = mat3(-0.5,-0.866025404,0,-0.866025404,0.5,0,-0.189468691,9.848726954,1);
u2t[23] = mat3(-0.5,0.866025404,0,-0.866025404,-0.5,0,-0.189468691,-9.848726954,1);
edge[0] = vec3(0,-1,0);
edge[1] = vec3(0.707106781,-0.707106781,0);
edge[2] = vec3(0.258819045,0.965925826,-0.866025404);
edge[3] = vec3(-0.258819045,0.965925826,-1.5);
edge[4] = vec3(-0.965925826,-0.258819045,-1.866025404);
}

vec2 dTile(in vec2 p)
{
   // Transform to unit cell space
   vec3 p2 = s2u * vec3(p, 1.);
   
   // Repeat
   p2.xy = fract(p2.xy);
   
   // Transform back
   vec2 q = vec2(u2s * p2);
   
   vec3 n;
   int c;
   float d;
   mat3 m;

// Auto-generated BSP
REC0(0.707106781,-0.707106781,6.464101615)
 REC0(0.866025404,-0.5,3.60488426)
  REC0(0.258819045,-0.965925826,1.5)
   REC0(0.258819045,0.965925826,0.5)
    LEAF0(0.258819045,0.965925826,-0.866025404,2,0)
    REC1
     REC0(0,1,0)
      LEAF0(0.965925826,0.258819045,1.866025404,0,3)
      LEAF1(2,5)
      END
     LEAF1(6,13)
     END
    END
   REC1
    LEAF0(-0.707106781,0.707106781,-1.366025404,0,10)
    LEAF1(6,13)
    END
   END
  REC1
   REC0(0.707106781,0.707106781,0)
    LEAF0(0.707106781,-0.707106781,2.732050808,2,0)
    LEAF1(3,1)
    END
   REC1
    LEAF0(0.5,0.866025404,0.258819045,1,4)
    LEAF1(2,5)
    END
   END
  END
 REC1
  REC0(0.258819045,0.965925826,-1.866025404)
   REC0(0.258819045,-0.965925826,4.598076211)
    LEAF0(0.965925826,-0.258819045,4.232050808,5,2)
    REC1
     LEAF0(0.866025404,-0.5,5.536735913,3,6)
     LEAF1(5,8)
     END
    END
   REC1
    REC0(0.5,-0.866025404,6.243842694)
     LEAF0(0.965925826,0.258819045,3.232050808,4,7)
     LEAF1(5,8)
     END
    LEAF1(10,9)
    END
   END
  REC1
   REC0(0.5,0.866025404,0.258819045)
    LEAF0(0.965925826,-0.258819045,4.232050808,1,4)
    REC1
     LEAF0(0.866025404,-0.5,5.536735913,3,6)
     LEAF1(5,8)
     END
    END
   REC1
    REC0(0.866025404,-0.5,5.536735913)
     LEAF0(0.707106781,-0.707106781,4.098076211,2,5)
     LEAF1(3,6)
     END
    REC1
     LEAF0(0.965925826,-0.258819045,6.598076211,5,8)
     LEAF1(3,11)
     END
    END
   END
  END
 END
REC1
 REC0(0.258819045,0.965925826,-4.598076211)
  REC0(0.258819045,0.965925826,-5.598076211)
   REC0(-0.258819045,0.965925826,-10.196152423)
    LEAF0(-0.965925826,-0.258819045,-5.464101615,6,14)
    LEAF1(8,16)
    END
   REC1
    LEAF0(-0.5,-0.866025404,3.346065215,7,15)
    LEAF1(8,16)
    END
   END
  REC1
   REC0(-0.707106781,0.707106781,-11.062177826)
    LEAF0(0.707106781,0.707106781,0.5,7,15)
    LEAF1(8,21)
    END
   REC1
    REC0(-0.965925826,0.258819045,-7.964101615)
     LEAF0(0.707106781,0.707106781,0.5,7,15)
     LEAF1(9,22)
     END
    REC1
     LEAF0(-0.866025404,0.5,-7.916875301,9,17)
     LEAF1(11,19)
     END
    END
   END
  END
 REC1
  REC0(-0.258819045,0.965925826,-7.098076211)
   REC0(-0.866025404,0.5,-9.848726954)
    REC0(-0.5,-0.866025404,1.414213562)
     LEAF0(-0.965925826,0.258819045,-10.330127019,7,20)
     LEAF1(9,22)
     END
    REC1
     LEAF0(-0.707106781,0.707106781,-11.062177826,8,21)
     LEAF1(9,22)
     END
    END
   REC1
    REC0(-0.866025404,0.5,-7.916875301)
     LEAF0(0.965925826,-0.258819045,7.964101615,9,17)
     LEAF1(11,23)
     END
    LEAF1(11,19)
    END
   END
  REC1
   REC0(0.258819045,0.965925826,-3.232050808)
    LEAF0(0.707106781,-0.707106781,7.330127019,10,9)
    REC1
     REC0(0.707106781,-0.707106781,8.696152423)
      LEAF0(-0.965925826,-0.258819045,-4.098076211,10,18)
      LEAF1(11,19)
      END
     LEAF1(11,23)
     END
    END
   REC1
    REC0(0.5,-0.866025404,6.950949475)
     LEAF0(0.258819045,-0.965925826,4.598076211,3,11)
     LEAF1(4,12)
     END
    REC1
     LEAF0(0.707106781,-0.707106781,8.696152423,10,18)
     LEAF1(11,23)
     END
    END
   END
  END
 END
END

   // Transform to prototile
   q = vec2(m * vec3(q,1));
   
   // Calculate closest distance to edges
   float sd = 1.;
   for(int i=0; i<N; ++i) {
      vec3 n = edge[i];
      sd = min(sd, abs(dot(n.xy,q)-n.z));
   }

#if USE_COLORS == 2
   float sh = (mod(float(c),6.)+3.)*(1./9.);
#else
   float sh = float(c)*(1./12.);
#endif
   
   return vec2(sh,sd);
}

//---------------------------------------------

const float bump = .1;
const float ground = .2;

float dField(in vec3 p)
{
   float d = p.y + ground;
   
   vec2 tile = dTile(p.xz);
   float d3;
   //d3 = min(.05,smoothstep(0.,1.,tile.y*20.)*.05)*.5;
   d3 = min(.05,tile.y)*.5;
   d3 += tile.y*.3;
   d3 = min(d3,bump);
   //d3 = smoothstep(0.,1.,d3/cut)*cut;
   d -= d3;
   return d;
}

vec3 dNormal(in vec3 p, in float eps)
{
   vec2 e = vec2(eps,0.);
   return normalize(vec3(
      dField(p + e.xyy) - dField(p - e.xyy),
      dField(p + e.yxy) - dField(p - e.yxy),
      dField(p + e.yyx) - dField(p - e.yyx) ));
}

vec4 trace(in vec3 ray_start, in vec3 ray_dir)
{
   float ray_len = 0.0;
   vec3 p = ray_start;
   
   // Intersect with ground plane first
   
   if (ray_dir.y >= 0.) return vec4(0.);
   
   float dist;
   dist = (ray_start.y + ground - bump)/-ray_dir.y;
   p += dist*ray_dir;
   ray_len += dist;
   if (ray_len > ray_max) return vec4(0.);
   //return vec4(p, ray_len);
   
   for(int i=0; i<iterations; ++i) {
         dist = dField(p);
      if (dist < dist_eps*ray_len) break;
      if (ray_len > ray_max) return vec4(0.0);
      p += dist*ray_dir;
      ray_len += dist;
   }
   return vec4(p, ray_len);
}

vec3 shade(in vec3 ray_start, in vec3 ray_dir,
   in vec3 light_dir, in vec3 fog_color, in vec4 hit)
{   
   vec3 dir = hit.xyz - ray_start;
   vec3 norm = dNormal(hit.xyz, .015);//*hit.w);
   float diffuse = max(0.0, dot(norm, light_dir));
   float spec = max(0.0,dot(reflect(light_dir,norm),normalize(dir)));
   spec = pow(spec, 32.0)*.7;

   vec2 tile = dTile(hit.xz);
   float sh = tile.x;
   float sd = min(tile.y,.05)*20.;
#if USE_COLORS == 0
   vec3 base_color = vec3(.5);
#else
   vec3 base_color =
    vec3(exp(pow(sh-.75,2.)*-10.),
         exp(pow(sh-.50,2.)*-20.),
         exp(pow(sh-.25,2.)*-10.));
#endif
   vec3 color = mix(vec3(0.),vec3(1.),diffuse)*base_color +
      spec*vec3(1.,1.,.9);
   color *= sd;
   
   float fog_dist = max(0.,length(dir) - fog_start);
   float fog = 1.0 - 1.0/exp(fog_dist*fog_density);
   color = mix(color, fog_color, fog);

   return color;
}

void main(void)
{
   initTiling();
   
   vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5) / resolution.y;
    
   vec3 light_dir = normalize(vec3(.5, 1.0, .25));
   
   // Simple model-view matrix:
   float ms = 2.5/resolution.y;
   float ang, si, co;
   ang = -time*.25;
   si = sin(ang); co = cos(ang);
   mat4 cam_mat = mat4(
      co, 0., si, 0.,
      0., 1., 0., 0.,
     -si, 0., co, 0.,
      0., 0., 0., 1.);
   ang = cos(-time*.5)*.4 + .8;
   ang = max(0.,ang);
   si = sin(ang); co = cos(ang);
   cam_mat = cam_mat * mat4(
      1., 0., 0., 0.,
      0., co, si, 0.,
      0.,-si, co, 0.,
      0., 0., 0., 1.);

   vec3 pos = vec3(cam_mat*vec4(0., 0., -cam_dist, 1.0));
   vec3 dir = normalize(vec3(cam_mat*vec4(uv, 1., 0.)));

   vec3 color;
   vec3 fog_color = vec3(min(1.,.4+max(-.1,dir.y*.8)));
   vec4 hit = trace(pos, dir);
   if (hit.w == 0.) {
      color = fog_color;
   } else {
      color = shade(pos, dir, light_dir, fog_color, hit);
   }
   
   // gamma correction:
   color.x = pow(color.x,.7);
   color.y = pow(color.y,.7);
   color.z = pow(color.z,.7);
   
   glFragColor = vec4(color, 1.);
}
