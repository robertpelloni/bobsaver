#version 420

// original https://www.shadertoy.com/view/ttsXWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
The shader was made using Bonzomatic.
You can find the original shader here: http://lezanu.fr/LiveCode/HangingPlants.glsl
*/

float smin(float a, float b, float h) {
  float k=clamp((a-b)/h*.5+.5,0.0,1.0);
  return mix(a,b,k) - k*(1.0-k)*h;
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float mat=0.0;
float at=0.0;
float map(vec3 p) {
  
  vec3 bp2 = p;
  
  float tt = time*0.5;
  p.xz += sin(p.zx*vec2(0.1,0.07)+tt*1.3)*2.0;
  //p.y += sin(p.x*0.1+tt)*5 + sin(p.y*0.25+tt)*3;
  
  p.y+=100.0;
  float t2=sin(time*0.3 + p.y*0.005)*0.5;
  p.yz *= rot(t2*0.5);
  p.xy *= rot(t2);
  p.y-=100.0;
  
  float s=32.0;
  for(float i=0.0; i<5.0; ++i) {
    p.xz*=rot(0.3+i);
    p.xz+=s;
    p.xz=abs(p.xz);
    p.xz-=s;
    s*=0.6;
  }
  
  float zone = 30.0;
  p.xz = (fract(p.xz/zone-.5)-.5)*zone;
  
  vec3 bp=p;
  
  float d = 10000.0;
  float prevd = length(p.xz)-1.0;
  float off=p.y;
  
  float dist=4.0;
  p.y = (fract(p.y/dist-.5)-.5)*dist;
  p.y=abs(p.y);
  p.y=smin(p.y,-p.y,-1.0);
  p.y=dist*0.5-smin(dist*0.5-p.y,-(dist*0.5-p.y),-1.0);
  
  p.y-=dist*0.25;
  
  for(float i=0.0; i<7.0; i++) {
    float t=time*0.2+i + off*0.1+22.7;
    p.xy *= rot(t);
    p.yz *= rot(t-1.2);
    d = smin(d, length(p-vec3(0,1.3,0))-1.0, 0.3);
  }
  
  
    
  at += 0.2/(0.2+abs(d));
  
  mat=clamp((d-prevd+0.1)/0.3,0.0,1.0);
  d = smin(d, prevd, 0.3);
  
  d = smin(d, bp.y-sin(bp.x*0.02)*10.0-sin(bp.z*0.034)*8.0, -2.0);
    
  d *= 0.7;
    
  return d;
}

void cam(inout vec3 p) {
  
  p.yz *= rot(-0.5);
  p.xz *= rot(time*0.2);
  
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  
  // this fixes glitches when time is too high, but cause a cam cut every two minutes
  // time = mod(time, 120.0);

  vec3 s=vec3(5,0,-40);
  vec3 r=normalize(vec3(-uv, 1.0));
  
  cam(s);
  cam(r);
  
  float maxdist = 300.0;
  
  vec3 p=s;
  float dd=0.0;
  for(int i=0; i<100; ++i) {
    float d=map(p);
    if(abs(d)<0.001) {
      break;
    }
    if(dd>maxdist) {dd=maxdist; break;}
    p+=d*r;
    dd+=d;
  }
  
  float curmat = mat;
  float curat = at;
  
  vec3 col=vec3(0);
  
  vec2 off=vec2(0.05,0);
  vec3 n=normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
  
  vec3 l= normalize(-vec3(1,3,2));
  vec3 h=normalize(l-r);
  float fog = pow(1.0-clamp(dd/maxdist,0.0,1.0), 1.0);
  float fre=pow(1.0-abs(dot(n,r)),2.0);
  
  float sss=smoothstep(0.0,1.0,map(p+l*10.0)/10.0)+smoothstep(0.0,1.0,map(p+l*5.0)/5.0)+smoothstep(0.0,1.0,map(p+l*1.0));
  float spec = max(0.0, dot(n,h));
  
  vec3 sky = mix(vec3(1,0.3,0.2), vec3(1.0,0.6,1.0)*2.0, pow(abs(r.y),2.0) * pow(1.0-fog,1.0));
  
  col += (dot(n, l)*0.5+0.5) * fog * (vec3(0.2,0.6,0.3)*0.5) * curmat;
  col += max(dot(n, l),0.0) * fog * (pow(spec,10.0)*2.0);
  col += sky*sss*fog * 1.0 * (1.0-curmat) * 0.5;
  
  col += pow((1.0-fog)*1.7, 3.0) * sky;
  col += sky*fre*fog;
    
  col += pow(curat * 0.05,0.8) * sky;
  
  col *= 1.2-length(uv);
  
  col = 1.0-exp(-col*2.0);
  col = pow(col, vec3(1.5));
  
  
  glFragColor = vec4(col, 1);
}
