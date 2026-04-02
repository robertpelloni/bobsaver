#version 420

// original https://www.shadertoy.com/view/wtjGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
The shader was made using Bonzomatic.
You can find the original shader here: http://lezanu.fr/LiveCode/SableBat.glsl
*/

float time2;
float pi=acos(-1.0);

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);  
}

float smin(float a, float b, float h) {
  float k = clamp((a-b)/h*.5+.5,0.0,1.0);
  return mix(a,b,k) - k * (1.0-k) * h;
}

float wings(vec3 p) {
  
  p.x = abs(p.x);
  
  float flop = pow(max(0.0,sin(time2*4.0 - p.x*0.15)*0.8+0.2),10.0);
  p.xz *= rot(clamp(p.x,0.0,2.0) * 0.3 * flop);
  
  float ang = p.x + p.y*0.5;
  float decal = -2.0;
  p.y -= decal;
  p.xy *= rot(-0.2 * clamp(ang*0.9-ang*ang*0.3, -5.0, 2.0));
  p.y += decal;
  
  vec3 p2 = p;
  float size = 0.4;
  p2.x = (fract(p2.x/size+0.5)-0.5)*size;
  p2.y -= clamp(p2.y,-2.0 + cos(p.x*0.5)*1.5,0.0);
  float d = max(length(p2)-0.2, abs(p.x)-5.0);
  
  p.xz *= rot(p.x * 0.012);  
  
  vec3 p3 = p;
  float size2 = 0.3;
  p3.x = (fract(p3.x/size2+0.5)-0.5)*size2;
  p3.y -= clamp(p3.y,-1.0 + cos(p.x*0.5)*0.8,-0.5);
  p3.z =abs(p.z+0.1)-0.15;
  d = smin(d, max(length(p3)-0.17, abs(p.x)-4.2), 0.2);
  d = smin(d, p.z+0.16, -0.12);
  
  
  d*=0.5;
  
  return d;
  
}

float body(float d, vec3 p) {
  
  vec3 bp = p;
  vec3 bp2 = p;
  
  p.y-=0.4;
  p.zy *= rot(abs(p.y)*0.2);
    
  vec3 p2 = p;
  
  p2.y -= clamp(p2.y,-1.0,2.0);
    
  d = smin(d, length(p2)-0.5 + p.y*0.19, 0.8);
  d = smin(d, length(bp+vec3(0,1.3,-0.9))-0.9, 0.2);
  //bp.x=abs(bp.x)-0.4;
  bp.x=smin(bp.x,-bp.x, 0.2)+0.4;
  bp.xy *= rot(bp.x*0.5);
  d = smin(d, -(length(bp+vec3(0,1.3,-1.4))-0.12), -0.6);
  d = smin(d, -(length(bp+vec3(-0.17,0.7,-1.4))-0.1), -0.2);
  
  bp2.x = abs(bp2.x);
  bp2.xz *= rot(-bp2.x*0.3 + bp2.y*0.14);
  bp2.yz *= rot(-0.6);
  bp2 -= vec3(0.1,0.0,-1.2);
  float hear = length(bp2 + vec3(-0.5,2.5,-1.2))-0.6;
  hear = smin(hear, -(length(bp2 + vec3(-0.5,2.5,-1.6))-0.6), -0.3);
  hear = smin(hear, -(length(bp2 + vec3(-0.9,2.1,-1.1))-0.1), -0.4);
  
  d=smin(d, hear, 0.17);
  
  return d;
}

float claws(float d, vec3 p) {
  
  p.x=-abs(p.x);
  vec3 bp=p;
  
  p += vec3(0.5,-2.0,0);
  
  p.zy *= rot(sin(time2*4.0+1.0)*0.5+0.3);
  p.y -= 0.5;
  
  p.x=-abs(p.x);
  p.xz *= rot(0.4);
  p.x=-abs(p.x);
  p.xz *= rot(0.2);
  
  float donut = length(vec2(length(p.zy)-0.6, p.x)) - 0.2;
  donut = smin(donut, -(length(p-vec3(0,1,-0.4))-0.7), -1.4 + clamp(-bp.x*0.5,0.0,1.0)-0.4);
  bp.xy *= rot(0.15);
  donut = smin(donut, max(length(bp.xz+vec2(0.2,0.0))-0.12, abs(bp.y-1.0)-1.0), 0.2);
  d = smin(d, donut, 0.2);
  
  return d;
  
}

float noise(vec2 p) {
  vec2 ip=floor(p);
  p=fract(p);
  p=smoothstep(0.0,1.0,p);
  vec2 st=vec2(37,133);
  vec4 val = fract(sin(dot(ip, st) + vec4(0,st.x, st.y, st.x+st.y))*2375.655);
  vec2 v = mix(val.xz,val.yw, p.x);
  return mix(v.x, v.y, p.y);
}

float mat = 0.0;
float map(vec3 p) {
  
  vec3 tp = p;
  tp.z += time2*10.0;
  tp.y += sin(time2*0.7)*5.0;
  float f = noise(tp.xz*0.08)*0.5;
  f += noise(tp.xz*0.16)*0.25;
  f += noise(tp.xz*0.32)*0.125;
  f = abs(f-0.5);
  float d2 = 8.0-tp.y + f*13.0;
  d2 *= 0.7;  
  
  
  p.yx *= rot(sin(time2*0.7) * 0.3);
  p.yz *= rot(-0.7 + sin(time2) * 0.3);
  
  
  p.y += sin(time2*4.0 + 2.5 + abs(p.x)*0.4)*0.3;
  
  float d = wings(p);
  
  d = body(d, p);
  
  d = claws(d, p);
  
  
  d = min(d, d2);
  
  mat = abs(d-d2)<0.01?1.0:0.0;
  
  return d;
}

void cam(inout vec3 p) {
  
  p.yz *= rot(sin(time2)*0.2+0.2);
  p.xz *= rot(2.7 + time2*0.4);
  p.yz *= rot(sin(time2)*0.1-0.1);
   
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  
  // We mod the time2 to make it repeat, because as we scroll the ground, the lack of precision start to be visible
  time2 = mod(time, 50.0);

  vec3 s=vec3(0,0,-18);
  vec3 r=normalize(vec3(-uv, 1));
  
  cam(s);
  cam(r);
  
  vec3 p=s;
  float i=0.0;
  float dd=0.0;
  for(i=0.0; i<100.0; ++i) {
    float d=map(p);
    if(d<0.001) {
      i += d/0.001;
      break;
    }
    if(dd>100.0) {
      dd=100.0;
      break;
    }
    p+=r*d;
    dd+=d;
  }
  
  float curmat=mat;
  
  vec2 off=vec2(0.01,0);
  vec3 n = normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
  
  float itfog = pow((1.0-i/100.0)*1.1,3.0);
  float fog = 1.0-clamp(dd/100.0,0.0,1.0);
  
  vec3 l=normalize(-vec3(1,3,-2));
  vec3 h=normalize(l-r);
  float fre=pow(1.0-abs(dot(n,r)),3.0);
  
  float ao = clamp(map(p+n*0.5)/0.5,0.0,1.0);
    
  vec3 col = vec3(0);
  vec3 diff = mix(vec3(0.4,0.5,0.9)*2.0, vec3(0.9,0.6,0.5)*2.0, curmat);
  col += max(0.0, dot(n,l)) * fog * ao * (diff +  2.0*pow(max(0.0,dot(h,n)), 10.0)*(1.0-curmat));
  col += (n.y * 0.5 + 0.5) * vec3(1,0.5,0.3) * 0.8 * fog;
  col += fre * vec3(1,0.7,0.5) * 3.0 * fog * ao * (-n.y*.5+.5) * (1.0-curmat*0.6);
  
  vec3 rr = normalize(p);
  vec2 skyuv = vec2(abs(atan(rr.x,rr.z)), rr.y);
  float ff = (-noise(skyuv*vec2(4,30))*0.1-noise(skyuv*vec2(6,19)*2.0)*0.05) * 0.33;
  vec3 sky = mix(vec3(1,0.7,0.5)*0.3, vec3(1.0,0.2,0.2)*3.0, pow(max(0.0,r.z), 80.0)) * pow(max(0.0,-r.y*0.5+1.2 + ff),5.0);
  col += sky * pow((1.0-fog)*1.2, 3.0);
          
  glFragColor = vec4(col, 1);
}
