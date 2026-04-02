#version 420

// original https://www.shadertoy.com/view/WslyDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
The shader was made using Bonzomatic.
You can find the original shader here: http://lezanu.fr/LiveCode/VirtualMeadow.glsl
*/

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
  return max(p.x, max(p.y,p.z));
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);  
}

float herb(vec3 p, float s) {
  
  p /= s;
  
  p.y+=3.0;
  p.z += abs(p.x)*0.3;
  float d = box(p, vec3(sin((p.y*0.7+3.0)*0.5),6.0,0.2));
  
  return d*s*0.7;
}

float rnd2(vec2 uv) {
  return fract(dot(sin(uv*427.512+uv.yx*652.477),vec2(417.884)));
  
}

float field(vec3 p, float repeat) {
    
  vec2 gridid = floor(p.xz/repeat-0.5);
  float id = rnd2(gridid);
  p.xz = (fract(p.xz/repeat-0.5)-0.5)*repeat;
  
  p.xz *= rot(id*6.3);
  
  return herb(p, 0.5 + rnd2(gridid+3.7)*0.8);
  
}

float ground = 0.0;
float grass(vec3 p) {
  
  //ground = (texture(iChannel0, p.xz*0.0002).x-0.1)*30.0;
  p.y += ground;
  
  p.xz += sin(p.zx*vec2(0.08,0.05) + p.y*0.1 + time*3.0 + dot(sin(time*0.3+p.xz*0.004),vec2(3,4)))*0.5*max(0.0,-p.y);
  
  float d = field(p,7.0);
  p.xz *= rot(0.3);
  p.x+=45.7;
  d = min(d, field(p,5.0));
  p.xz *= rot(0.9);
  p.x-=13.9;
  d = min(d, field(p,4.0));
    
  d=min(d, -p.y);
  
  return d;
}

float mistelement(vec3 p, float repeat) {
  
  p.z += time*10.0+sin(time*0.5-p.z*0.01)*10.0;
  p.xyz += sin(p.zxy*vec3(0.09,0.08,0.1) + vec3(1,0.7,0.5)*time)*5.0;
  
  
  p = (fract(p/repeat-0.5)-0.5)*repeat;
  
  float d=length(p)-0.2;
  
  return d*0.8;  
}

float mist(vec3 p) {
  vec3 bp=p;
  float d=mistelement(p,35.0);
  p.xz *= rot(0.2);
  p.yz *= rot(0.4);
  d=min(d, mistelement(p+vec3(18.25),31.0));
  //p.xz *= rot(0.2);
  //d=min(d, mistelement(p-vec3(18.25),13));
    
  d += max(0.0,-(30.0+bp.y)*0.5);
  
  return d;
}

float bari = 0.0;
float bar1(vec3 p, float repeat) {
  
  
  p.xz = (fract(p.xz/repeat-0.5)-0.5)*repeat;
  
  p.y += 30.0;
  vec3 bp=p;
  
  p.y = abs(p.y)-5.0;
    
  float d = box(p, vec3(0.2,3.0,25.0));
  
  bp.y -= 10.0;
  bp.z = abs(bp.z)-10.0;
  bp.z = abs(bp.z)-5.0;
  d = min(d, box(bp, vec3(0.5,20.0,2.0)));
  
  return d;
}

float bar(vec3 p) {
  float d=bar1(p, 200.0);
  p.xz *= rot(-1.0);
  d=min(d, bar1(p, 230.0));
  
  return d;
}

float mimi = 0.0;
float map(vec3 p) {
  
  float d = grass(p);
  float mi = mist(p);
  mimi+=0.01/(0.1+abs(mi));
  d=min(d, mi);
  
  bari = bar(p);
  d=min(d, bari);
  
  return d;
}

float sss(vec3 p, vec3 l, float d) {
  return smoothstep(0.0,1.0,map(p+l*d)/d);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
    
  float time2 = mod(time, 300.0);

  vec3 s=vec3(0,-60,-120.0 - sin(time2)*30.0);
  vec3 t=vec3(0,-20,0);
  
  s.xz *= rot(time*0.3);

  float adv = time2*40.0;
  s.z += adv;
  t.z += adv;
  
  vec3 cz = normalize(t-s);
  vec3 cx = normalize(cross(cz, vec3(sin(time2*0.2)*0.3,1,0)));
  vec3 cy = normalize(cross(cz, cx));
  float fov = 1.0;
  vec3 r=normalize(cx*uv.x + cy*uv.y + fov*cz);
  
  vec3 p=s;
  for(int i=0; i<70; ++i) {
    float d=map(p);
    if(d<0.001) break;
    if(d>400.0) break;
    p+=r*d;
  }
  
  vec3 l=normalize(-vec3(1,1.3,2));
  
  // copy the values before the light stepping
  float factor = ground;
  float mimi2=mimi;
  float bari2=bari;
  
  float sub = 0.0;
  float steps=20.0;
  for(float i=1.0; i<steps; ++i) {
    float dist = i*5.0/steps;
    sub += sss(p,l,dist);
  }
  sub *= 2.0/steps;
  sub *= clamp(-(p.y+ground)*0.1+0.3,0.0,1.0);
  float fog = 1.0-clamp(length(p-s)/400.0,0.0,1.0);
  
  float grass = 0.0; //texture(iChannel0, p.xz*0.0005).x;
  vec3 diff = vec3(0.7,0.9,0.4-grass*0.7);
  if(bari2<0.01) diff=vec3(1.0,0.8,0.6);
    
  vec3 col=vec3(0);
  col += sub * diff;
  col *= fog;
  
  col += vec3(1,0.9,0.5) * mimi2;
  
  vec3 sky = mix(max(vec3(0),vec3(0.5,.6,1.0)+r.y*2.0), vec3(0.9,.7,0.1)*3.0, pow(max(0.0,dot(r,l)),10.0));
  col += pow(1.0-fog, 3.0)*sky;
  
  col = smoothstep(0.0,1.0,col);
  col = pow(col, vec3(0.4545));
  
  glFragColor = vec4(col, 1);
}
