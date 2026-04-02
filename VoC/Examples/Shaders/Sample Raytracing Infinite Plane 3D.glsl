#version 420

// original https://www.shadertoy.com/view/wsBSWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Created by Per Bloksgaard/2019
//Raytracing an infinite plane in 3D and mapping a grid onto it.

mat3 setupRotationMatrix(vec3 ww)
{
  vec3 uu = normalize(cross(ww,vec3(0.,1.,0.)));
  vec3 vv = normalize(cross(uu,ww));
  return mat3(uu,vv,ww);
}

void main(void)
{
  vec3 vCamPos = vec3(cos(time*0.5)*1.6,0.,sin(time*0.5)*1.6);
  vec3 vCamTarget = vec3(0.,-1.3,0.);
  vec3 vCamForward = normalize(vCamTarget-vCamPos);
  vec3 vCamRight = normalize(cross(vCamForward,vec3(0.,1.,0.)));
  vec3 vCamUp = normalize(cross(vCamRight,vCamForward));
  vec3 vPlanePos = vec3(0.,-1.,0.);
  vec3 vPlaneRight = vec3(1.,0.,0.);
  vec3 vPlaneUp = vec3(0.,0.,1.);
  vec3 vForwardRot = normalize(vec3(cos(time*0.5),sin(time*0.3)*0.9,cos(time*0.7)*0.2));
  mat3 m = setupRotationMatrix(vForwardRot);
  vPlaneRight *= m;
  vPlaneUp *= m;
  vec3 vPlaneNormal = normalize(cross(vPlaneRight,vPlaneUp));
  float fPlaneDeltaNormalDistance = dot(vPlanePos,vPlaneNormal) - dot(vPlaneNormal,vCamPos);
  vec3 color = vec3(0.);
  for(int m=0; m<2; m++)
  {
    for(int n=0; n<2; n++)
    {
      vec2 s = (-resolution.xy+2.*(gl_FragCoord.xy+(vec2(float(m),float(n))*0.5-0.5)))/resolution.y;
      vec3 vRayDir = normalize(s.x*vCamRight+s.y*vCamUp+vCamForward*1.3);
      float t = fPlaneDeltaNormalDistance / dot(vPlaneNormal,vRayDir);
      vec3 hitPos = vCamPos + vRayDir*t;
      vec3 delta = hitPos - vPlanePos;
      vec2 bary = vec2(dot(delta, vPlaneRight),dot(delta, vPlaneUp));
      vec2 grid = (70.7+t*0.1)-pow(vec2(2.5-t*0.03),abs(vec2(0.5)-fract(bary*4.))*10.2);
      color += vec3(clamp(min(grid.x,grid.y),0.,1.))*clamp(1.-t*0.15,0.,1.)*step(0.,t);
    }
  }
  glFragColor = vec4(color*0.25,1.);
}
