#version 420

// original https://www.shadertoy.com/view/td2yWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro)) + sin(ro)*cross(ax,p);
}

float linedist(vec2 p, vec2 a, vec2 b) {
  float k = dot(p-a,b-a)/dot(b-a,b-a);
  return distance(p, mix(a, b, clamp(k,0.,1.) ));
}

float hash(float a, float b) {
    return -1.+2.*fract(sin(dot(vec2(a,b), vec2(12.4348,74.38483)))*48573.2394);
}

float scene(vec3 p ) {
    float scale  = 0.2;
    vec3 id = floor(p*scale);
    float idhash = hash(hash(id.y, id.x), id.z);
    float hash1 = hash(idhash, id.y)*6.28;
    float hash2 = hash(id.x, idhash)*6.28;
    vec3 ax = normalize(vec3(cos(hash1), sin(hash1)*cos(hash2), sin(hash1)*sin(hash2)));
    float ro = hash(hash1+id.y, idhash)*6.28;
    p = (fract(p*scale)-0.5)/scale;
    p = erot(p, ax, ro+time*0.7);
    p += vec3(hash(hash1,hash2+6.), hash(hash1+5.,hash2), hash(hash2,hash1+3.))*1.;
    float sphere = length(p)-1.;
    return min(.5,linedist(vec2(p.z, sphere), vec2(-0.1,0.), vec2(0.1,0.))-0.1);
}

vec3 norm(vec3 p) {
    mat3 k = mat3(p,p,p) - mat3(0.01);
    return normalize(scene(p) - vec3(scene(k[0]), scene(k[1]), scene(k[2])));
}

void main(void)
{
  vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
  uv = erot(vec3(uv,0.), vec3(0,0,1), cos(time*0.5)*0.5).xy;
  vec3 cam = normalize(vec3(1,uv));
  vec3 init = vec3(time,0,cos(time*0.4)*2.);
  cam=erot(cam,vec3(0,1,0),cos(time/8.)*0.3);
  cam=erot(cam,vec3(0,0,1),time/4.);
  vec3 p = init;
  bool hit = false;
  for (int i = 0; i< 100; i++) {
      float dist = scene(p);
      if (dist*dist < 0.00001) { hit = true; break; }
      if (distance(p,init)>30.) break;
      p+=cam*dist;
  }

  uv *=32.;
  uv += vec2(sin(time*1.), cos(time*1.5))*2.;
  //uv = erot(vec3(uv,0.), vec3(0,0,1), cos(time*0.5)*0.5).xy;

  glFragColor = cos(uv.y)*cos(uv.x) < 0. ? vec4(0.2,0.5,0.9,1.) : vec4(0.);
  if (hit) {
      vec3 n = norm(p);
      vec3 rf = reflect(cam, n);
    float shadow = scene(p+rf) + .5;
      float factor = shadow*length(sin(rf*3.)*0.5+0.5)/sqrt(2.);
      vec3 col = mix(vec3(0.3,0.25,0.1), vec3(0.8,0.6,0.2), factor) + pow(factor*0.8, 6.);
    glFragColor.xyz = mix(col, glFragColor.xyz, pow(distance(p, init)/30., 50.));
  }
}
