#version 420

// original https://www.shadertoy.com/view/XlXGRM

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

// Yet Another Christmas Tree by Ruslan Shestopalyuk, 2014/15
// Many thanks to iq, eiffie and paolofalcao for the insight and the code

#define PI                      3.14159265

#define MTL_BACKGROUND          -1.0
#define MTL_GROUND              1.0
#define MTL_NEEDLE              2.0
#define MTL_STEM                3.0
#define MTL_TOP_DEC             4.0
#define MTL_DEC_BINDING         5.0
#define MTL_DEC                 6.0

#define DEC_R                   0.5

#define TREE_H                  4.0
#define TREE_R                  3.0
#define V_DEC_SPACING           1.9

#define NORMAL_EPS              0.001

#define NEAR_CLIP_PLANE         1.0
#define FAR_CLIP_PLANE          100.0
#define MAX_RAYCAST_STEPS       256
#define DIST_EPSILON            0.001
#define MAX_RAY_BOUNCES         2.0

#define GLOBAL_LIGHT_COLOR      vec3(0.8,1.0,0.9)
#define SPEC_COLOR              vec3(0.8, 0.90, 0.60)
#define GLOBAL_LIGHT_DIR        normalize(vec3(-1.2, 0.3, -1.1))
#define BACKGROUND_COLOR        vec3(0.3, 0.342, 0.5)

#define CAM_DIST                13.0
#define CAM_H                   4.0
#define LOOK_AT_H               3.8

#define LOOK_AT                 vec3(0,LOOK_AT_H,0)

#define NEEDLE_LENGTH           0.55
#define NEEDLE_SPACING          0.25
#define NEEDLE_THICKNESS        0.05
#define STEM_THICKNESS          0.02
#define BRANCH_ANGLE            0.423
#define BRANCH_SPACING          1.7

float planeXZ(vec3 p, float offs) {
    return p.y + offs;
}

float planeXY(vec3 p, float offs) {
    return p.z + offs;
}

float planeNegXY(vec3 p, float offs) {
    return -p.z + offs;
}

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float box_u(vec3 p, vec3 b) {
     return length(max(abs(p) - b, 0.0));
}

float coneXY(in vec3 p, float r, float h) {
    return (max(abs(p.y) - h, length(p.xz)) - r*clamp(h - abs(p.y), 0.0, h));
}

float cylinderXZ(vec3 p, vec2 h) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y), 0.0) + length(max(d,0.0));
}

float torusXY(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xy) - t.x, p.z);
    return length(q) - t.y;
}

float D(float d1, float d2) { 
    return max(-d2, d1);
}

float U(float d1, float d2) {
    return min(d2, d1);
}

float I(float d1, float d2) {
    return max(d2, d1);
}

vec2 I(vec2 d1, vec2 d2) {
    return (d1.x< d2.x) ? d2 : d1;
}

vec2 U(vec2 d1, vec2 d2) {
    return (d1.x< d2.x) ? d1 : d2;
}

vec2 rotate(vec2 p, float ang) {
    float c = cos(ang), s = sin(ang);
    return vec2(p.x*c-p.y*s, p.x*s+p.y*c);
}

float repeat(float coord, float spacing) {
    return mod(coord, spacing) - spacing*0.5;
}

vec3 repeatRadially(vec2 p, float n) {
    float ang = 2.0*PI/n;
    vec2 ret = rotate(p, -ang*0.5);
    float sector = floor(atan(ret.x, ret.y)/ang);
    p = rotate(p, sector*ang);
    return vec3(p.x, p.y, sector);
}

float star(vec3 p) {
    p.xy = (repeatRadially(p.xy, 5.0)).xy;
    p.y = p.y - 0.3;
    p.xz=abs(p.xz);
    return dot(p, normalize(vec3(2.0, 1, 3.0)))/3.0;
}

float decoration(in vec3 pos, float type) {
    float d = sphere(pos, DEC_R);
    if (type <= 0.0) {
        // bumped sphere
        d += cos(atan(pos.x, pos.z)*30.0)*0.01*(0.5 - pos.y) + sin(pos.y*60.0)*0.01;
    } else if (type <= 1.0) {
        // dented sphere
        d = D(d, sphere(pos + vec3(0.0, 0.0, -0.9), 0.7));
    } else if (type <= 2.0) {
        // horisontally distorted sphere
        return d += cos(pos.y*28.0)*0.01;
    } else  if (type <= 3.0) {
        // vertically distorted sphere
        d += cos(atan(pos.x, pos.z)*20.0)*0.01*(0.5-pos.y);
    }
    return d;
}

vec2 ground(in vec3 p) {
    p.y += (sin(sin(p.z*0.1253) - p.x*0.311)*0.31+cos(p.z*0.53+sin(p.x*0.127))*0.12)*1.7 + 0.2;
    return vec2(p.y, MTL_GROUND);
}

vec2 decorations(in vec3 p) {
    vec3 pos = p;

    float h = abs(-floor(pos.y/V_DEC_SPACING)/TREE_H + 1.0)*TREE_R;
    vec3 r = repeatRadially(pos.xz, max(1.0, 2.5*h));
    float m = h*113.0 + r.z*7.0 + 55.0; // pick the material ID
    pos.y -= mod(m, 11.0)*0.03;
    pos.xz = r.xy;
    pos.y = mod(pos.y, V_DEC_SPACING) - 0.5;
    pos += vec3(0, 0, -h + 0.2);
    float decType = mod(m, 5.0);
    float dec = decoration(pos, decType);
    
    // binding
    float binding = cylinderXZ(pos - vec3(0.0, 0.5, 0.0), vec2(0.08, 0.1));
    binding = U(binding, torusXY(pos - vec3(0.0, 0.62, 0.0), vec2(0.05, 0.015)));
    
    vec2 res = U(vec2(dec, m), vec2(binding, MTL_DEC_BINDING));
    res.x = I(res.x, sphere(p, TREE_H*2.0 - 0.5));
    return res;
}

vec2 topDecoration(in vec3 pos) {
    pos.y -= TREE_H*2.0 + 0.3;
    pos *= 0.5;
    float d = U(star(pos), cylinderXZ(pos - vec3(0.0, -0.2, 0.0), vec2(0.04, 0.1)));
    return vec2(d, MTL_TOP_DEC);
}

vec2 needles(in vec3 p0) {    
    vec3 p = vec3(p0);
    float r = length(p.xy);
    p.xy = rotate(p.xy, -r*0.5);
    p.z = mod(p.z, NEEDLE_SPACING);     
       
    p.xy = repeatRadially(p.xy, 17.0).xy;
    p.yz = rotate(p.yz, -0.45); // bend in direction of stem
    
    float needle = coneXY(p, NEEDLE_THICKNESS, NEEDLE_LENGTH);
    needle = I(needle, planeXY(p0, 0.1));
    float stem = I(r - STEM_THICKNESS, planeXY(p0, NEEDLE_SPACING-0.04));
    return U(vec2(needle, MTL_NEEDLE), vec2(stem, MTL_STEM));
}

vec2 tree0(vec3 p) {
  p.y += BRANCH_SPACING*0.12;
  float section = floor(p.y/BRANCH_SPACING);
  float numBranches =  max(2.0, 9.0 - section*1.2);
  p.xz = repeatRadially(p.xz, numBranches).xy;
  p.z -= TREE_R*1.27;
  p.yz = rotate(p.yz, BRANCH_ANGLE);
  p.y = repeat(p.y, BRANCH_SPACING);
   return needles(p);
}

vec2 tree(vec3 p) {
    vec2 res = tree0(p);
    p.xz = rotate(p.xz, 0.7);
    p.y -= BRANCH_SPACING*0.4;
   res = U(res, tree0(p));

   vec2 trunk = vec2(coneXY(p.xyz, 0.02, TREE_H*2.0), MTL_STEM);
   res = U(res, trunk);
   res.x = I(res.x, sphere(p - vec3(0.0, TREE_H, 0.0), TREE_H + 1.7));
   return res;
}

vec2 present(vec3 p) {
      float b = box_u(p, vec3(0.5, 0.5, 0.5));
    b = U(b, box_u(p + vec3(0.0, -0.4, 0.0), vec3(0.52, 0.15, 0.52)));
    b = U(b, box_u(p, vec3(0.1, 0.53, 0.53)));
    vec2 pbox = vec2(b, 3.0);
    
    p.xz = abs(p.x) < abs(p.z) ? p.xz * sign(p.x) : vec2(p.z,-p.x) * sign(p.z);
    vec2 pribbon = vec2(box_u(abs(p), vec3(0.1, 0.55, 0.53)), 5.0);
    vec2 res = U(pbox, pribbon);
    return res;
}

vec2 presents(vec3 p) {
       // why, at least one present is better than nothing
       p.xz += vec2(0.4, 2.8);
      return present(p);
}

vec2 distf(in vec3 pos) {
    vec2 res = decorations(pos);
    res = U(res, topDecoration(pos));
    res = U(res, tree(pos));
    res = U(res, ground(pos));
    res = U(res, presents(pos));
   return res;
}

vec3 calcNormal(in vec3 p)
{
    vec2 d = vec2(NORMAL_EPS, 0.0);
    return normalize(vec3(
        distf(p + d.xyy).x - distf(p - d.xyy).x,
        distf(p + d.yxy).x - distf(p - d.yxy).x,
        distf(p + d.yyx).x - distf(p - d.yyx).x));
}

vec2 rayMarch(in vec3 ro, in vec3 rd) {
    float t = NEAR_CLIP_PLANE;
    float m = MTL_BACKGROUND;
    for (int i=0; i < MAX_RAYCAST_STEPS; i++) {
        vec2 res = distf(ro + rd*t);
        if (res.x< DIST_EPSILON || t>FAR_CLIP_PLANE) break;
        t += res.x;
        m = res.y;
    }
    if (t > FAR_CLIP_PLANE) m = MTL_BACKGROUND;
    return vec2(t, m);
}

vec3 applyFog(vec3 col, float dist) {
    return mix(col, BACKGROUND_COLOR, 1.0 - exp(-0.001*dist*dist));
}

vec3 getMaterialColor(float matID) {
    vec3 col = BACKGROUND_COLOR;
    if (matID <= MTL_GROUND) {
        col = vec3(3.3, 3.3, 4.5);
    } else if (matID <= MTL_NEEDLE) {
        col = vec3(0.152,0.36,0.18);
    } else if (matID <= MTL_STEM) {
        col = vec3(0.79,0.51,0.066);
    } else if (matID <= MTL_TOP_DEC) {
        col = vec3(1.6,1.0,0.6);
    } else if (matID <= MTL_DEC_BINDING) {
        col = vec3(1.2,1.0,0.8);
    }  else {
        //  decoration color 
        col = 0.3 + 0.7*sin(vec3(0.7, 0.4, 0.41)*(matID - MTL_DEC));
    }
    return col;
}

float softShadow( in vec3 ro, in vec3 rd, in float mint, in float tmax)
{
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 32; i++)
    {
        float h = distf( ro + rd*t ).x;
        res = min(res, 8.0*h/t);
        t += clamp(h, 0.02, 0.2);
        if( h<DIST_EPSILON || t>tmax ) break;
    }
    return clamp(res, 0.0, 1.0);    
}

vec3 render(in vec3 ro, in vec3 rd) {
    
    vec3 resCol = vec3(0.0);
    float alpha = 1.0;
    for (float i = 0.0; i < MAX_RAY_BOUNCES; i++) {
      vec2 res = rayMarch(ro, rd);
      float t = res.x;
      float mtlID = res.y;
      vec3 pos = ro + t*rd;
      vec3 nor = calcNormal(pos);
      vec3 ref = reflect(rd, nor);

      vec3 mtlColor = getMaterialColor(mtlID);
      vec3  lig = GLOBAL_LIGHT_DIR;

      float ambient = 0.03;
      float diffuse = clamp(dot(nor, lig), 0.0, 1.0);
      float specular = pow(clamp( dot(ref, lig), 0.0, 1.0), 10.0);
      
      diffuse *= softShadow(pos, lig, 0.01, 1.0);
      vec3 col = mtlColor*(ambient + GLOBAL_LIGHT_COLOR*(diffuse + 1.20*specular*SPEC_COLOR));

      col = applyFog(col, t);
      
      //  blend in (a possibly reflected) new color 
      resCol += col*alpha;

      if (mtlID <= MTL_DEC) break;
      ro = pos + ref*DIST_EPSILON;
      alpha *= 0.6;
      rd = ref;
    }
    return vec3(clamp(resCol, 0.0, 1.0));
}

void main(void) {
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= resolution.x/resolution.y;
    float time2 = 40.0 + time;
    float ang = 0.1*time2;
    vec3 camPos = vec3(CAM_DIST*cos(ang), CAM_H + cos(ang)*2.0, CAM_DIST*sin(ang));
    vec3 cw = normalize(LOOK_AT - camPos);
    vec3 cp = vec3(0.0, 1.0, 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    vec3 viewDir = normalize(p.x*cu + p.y*cv + 2.5*cw);
    vec3 col = render(camPos, viewDir);
    
    glFragColor=vec4(col, 1.0);
}

