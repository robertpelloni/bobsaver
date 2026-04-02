#version 420

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

vec3 trans(vec3 p, float m)
{
  return mod(p, m) - m / 2.0;
}

float distanceFunction(vec3 pos, int depth){
    float dim = 16.0/pow(3.0,float(depth));
    float dist;
    vec3 pos2 = abs(trans(pos,dim)) - dim/3.0;
    dist = -max(-pos2.x, -pos2.y);
    dist = max(dist,-max(-pos2.x, -pos2.z));
    dist = max(dist, -max(-pos2.y, -pos2.z));
    return dist;
}
float baseDistanceFunction(vec3 pos){
    float dim = 16.0;
    float dist;
    vec3 pos2 = abs(trans(pos,dim*2.0/3.0)) - dim/6.0;
    if (pos2.x>pos2.y && pos2.x<pos2.z || pos2.x<pos2.y && pos2.x>pos2.z)
        dist = pos2.x;
    else if (pos2.y>pos2.x && pos2.y<pos2.z || pos2.y<pos2.x && pos2.y>pos2.z)
        dist = pos2.y;
    else
        dist = pos2.z;
    return dist;
}
float distanceFunction(vec3 pos){
    float dist;
    dist = baseDistanceFunction(pos);
    dist = max(dist, distanceFunction(pos, 1));
    dist = max(dist, distanceFunction(pos, 2));
    dist = max(dist, distanceFunction(pos, 3));
    dist = max(dist, distanceFunction(pos, 4)); // if too spongy get black screen instead?
    //dist = max(dist, distanceFunction(pos, 5));
    //dist = max(dist, distanceFunction(pos, 6));
    //dist = max(dist, distanceFunction(pos, 7));
    return dist;
}

vec3 getNormal(vec3 p)
{
  const float d = 0.0001;
  return
    normalize
    (
      vec3
      (
        distanceFunction(p+vec3(d,0.0,0.0))-distanceFunction(p+vec3(-d,0.0,0.0)),
        distanceFunction(p+vec3(0.0,d,0.0))-distanceFunction(p+vec3(0.0,-d,0.0)),
        distanceFunction(p+vec3(0.0,0.0,d))-distanceFunction(p+vec3(0.0,0.0,-d))
      )
    );
}
 
void main() {
  vec2 pos = (gl_FragCoord.xy*2.0 -resolution) / resolution.y;
 
  vec3 camPos = vec3(0.0, 0.0, 01.*(-time*1.9+sin(time/6.0)+cos(time/2.0))*3.0);
  vec3 camDir = vec3(cos(time*.2), 0.0, sin(time*.2));
  //camDir = vec3(0,0,-1);
  vec3 camUp = vec3(0.0, 1.0, 0.0);
  vec3 camSide = cross(camDir, camUp);
  float focus = 1.8;
  camPos += camUp*((mouse.y-0.5)*10.0);
  camPos += camSide*((mouse.x-0.5)*10.0);
 
  vec3 rayDir = normalize(camSide*pos.x + camUp*pos.y + camDir*focus);
 
  float t = 0.0, d=0.0;
  vec3 posOnRay = camPos;
 
  for(int i=0; i<100; ++i)
  {
    d = distanceFunction(posOnRay);
    t += d;
    posOnRay = camPos + t*rayDir;
  }
 
  float depth = pow((length(posOnRay - camPos)) * 0.001, 1.2);
  vec3 normal = getNormal(posOnRay);
  vec3 lightDir = vec3(-0.3, 0.02, 0.57);

  vec3 color;
  if(abs(d) < 0.5)
  {
    float diff1 = clamp(dot(lightDir, normal)*0.9-depth, 0.0, 1.0);
    float diff2 = clamp(dot(-rayDir, normal)*0.9-depth, 0.1, 0.7);
    color = vec3(diff1+diff2-diff1*diff2)+vec3(0.0, 0.1, 0.0);
  } else {
    color = vec3(0.05);
  }
  glFragColor = vec4(color, 1.0);
}
