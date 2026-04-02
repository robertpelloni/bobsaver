#version 420

// original https://www.shadertoy.com/view/mdSGzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

vec2 hash22(vec2 p){
    vec2 a = vec2(94.86, 43.46);
    vec2 b = vec2(72.67, 13.48);
    p = vec2(dot(p, a), dot(p, b));
    return fract(sin(p*10.29)*48.47);
}

vec3 hash23(vec2 p){
    vec2 a = vec2(92.8, 438.7);
    vec2 b = vec2(73.6, 12.8);
    vec2 c = vec2(34.7, 73.18);

    vec3 r = vec3(dot(p, a), dot(p, b), dot(p, c));
    return fract(sin(r*10.29)*48.47);
}
vec3 analytic_sphere(vec2 p, float r) {
    //return sphere_coord;
    float l = length(p);
    float h = r*cos(l*PI/2./(r*1.5));
    p = normalize(p/r)*asin(length(p/r)) / PI;
    //p *= smoothstep(0., 0.001, sign(p));
    return vec3(p, h);
}

vec3 calcNormal(vec2 p, float r){
    vec2 e = vec2(1.0, -1.0) * 0.001;    
    return normalize(
      e.xyx*analytic_sphere(p + e.xy, r) +
      e.yxx*analytic_sphere(p + e.yx, r) +
      e.xxx*analytic_sphere(p + e.xx, r));
}

vec2 voro(vec2 uv, float ntiles, out vec3 normal, out vec3 col_boule)
{
    vec2 uv_id = floor (uv*ntiles);
    vec2 uv_st = fract(uv*ntiles);

    vec2 m_neighbor, m_diff, m_neighbor_id;
    float m_dist_s, m_dist = 10.;
    vec2 idx = vec2(0.,0.);
    int K = 1;
    vec2 point;
    for (int j = -K; j<=K; j++)
    {
        for (int i = -K; i<=K; i++)
        {
            vec2 neighbor = vec2(float(i), float(j));
            if (uv_id + neighbor == vec2(0.,0.)){
                point = (mouse*resolution.xy.xy-.5*resolution.xy)/resolution.y*ntiles;
            }
            else{
                point = hash22(uv_id + neighbor);
                point = float(K)/2.+float(K)/2.*sin(2.*PI*point+time/1.);
            }
            vec2 diff = neighbor + point - uv_st;
            float dist = length(diff);
            if (dist < m_dist)
            {
                m_dist = dist;
                m_dist_s = dist;
                m_diff = diff;
                m_neighbor = neighbor+point;
                m_neighbor_id = neighbor;
            }
        }
    }
    
    // mla suggestion
    vec2 neighbor_id = m_neighbor_id + uv_id;
    vec2 neighbor_coord = m_neighbor + uv_id - neighbor_id;
    
    m_dist=100.;
   
    for (int j = -K-1; j<=K+1; j++)
    {
        for (int i = -K-1; i<=K+1; i++)
        {
            vec2 neighbor = vec2(float(i), float(j));
            if (neighbor_id + neighbor == vec2(0.,0.)){
                point = (mouse*resolution.xy.xy-.5*resolution.xy)/resolution.y*ntiles;
            }
            else{
                point = hash22(neighbor_id + neighbor);
                point = float(K)/2.+float(K)/2.*sin(2.*PI*point+time/1.);
            }
            vec2 new_neighbor = point+neighbor;
            vec2 diff = new_neighbor - neighbor_coord;
            float dist = length(diff);
            if (dist < m_dist && length(neighbor_coord-new_neighbor)>.0001)
                    m_dist = dist;
        }
    }
    float neighbor_radius = m_dist/2.;
    
    
    float d = 1.-smoothstep(-.02, -0., length(m_neighbor-uv_st)-neighbor_radius);
    
    float r = neighbor_radius;
    vec2 p = m_neighbor-uv_st;
    float l = length(p);
    vec3 sphere = analytic_sphere(p, r);
    float h = r*cos(l*PI/2./r);
    col_boule = hash23(neighbor_id);
    normal = calcNormal(p, r);
        
    return vec2(d, h);
}

float smooth_damier(vec2 uv){
    float a = (.32035*atan(sin(PI*uv.x)/0.01)+.5);
    float b = (.32035*atan(sin(PI*uv.y)/0.01)+.5);
    return a*(1.-b)+b*(1.-a);
}

vec3 phong(vec3 lightDir, vec3 normal, vec3 rd, vec3 col) {
  // ambient
  vec3 ambient = col*(.5+.5*normal.z);

  // diffuse
  float dotLN = clamp(dot(lightDir, normal), 0., 1.);
  vec3 diffuse = col * dotLN;

  // specular
  float dotRV = clamp(dot(reflect(lightDir, normal*.8), -rd), 0., 1.);
  vec3 specular = 2.*col* pow(dotRV, 12.);

  return ambient*.4 + diffuse + specular;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    // Time varying pixel color
        
    vec3 normal;
    vec3 col_boule;
    vec2 v = voro(uv, 4., normal, col_boule);
    
    vec3 rd = vec3(uv, 2.);
    vec3 ld = vec3(-.4,-.4, 2.);//lightdir
    
    
    vec3 rr = refract(rd, normal, .1);
    vec3 ro = vec3(uv, v.y);
    float depth = -ro.z/rr.z;
    vec2 st = (v.x > 0.06) ? (ro+rr*depth).xy : uv;

    
    vec3 col = v.y*1.*max(vec3(0.), v.x*phong(ld, normal, rd, col_boule+.3));
    
    float damier = smooth_damier(st*4.);
    
    col += v.y*1.*max(vec3(0.), v.x*phong(ld, normal, rd, vec3(damier*.4)*v.x));
    
    
    float dotLN_damier = clamp(dot(ld, vec3(0.,0.,1.)), 0., 1.)*(1.-v.x);
    float dotRV_damier = clamp(dot(reflect(ld, vec3(0.,0.,1.)*.8), -rd), 0., 1.)*(1.-v.x);
    col += .5*damier* pow(dotRV_damier*.99, 10.) + .4*damier * dotLN_damier;

    // Output to screen
    glFragColor = vec4(col*.8, 1.0);
}
