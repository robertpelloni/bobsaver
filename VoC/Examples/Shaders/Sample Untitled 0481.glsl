#version 420

// original https://www.shadertoy.com/view/WlcGRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 getRd(vec3 o, vec3 lookAt, vec2 uv) {
    vec3 dir = normalize(lookAt - o);
    vec3 right = normalize(cross(vec3(0,1,0), dir));
    vec3 up = normalize(cross(dir, right));
    return dir + right*uv.x + up*uv.y;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;  
}
float sdTube(vec3 p, float r) {
    return length(p.xy) - r;
}
#define pi acos(-1.)
#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))

float sdRuby (vec3 p, float r){
  //p.z 
  p = abs(p);
  p.z -= r;
  p.yz *= rot(0.125*pi);
  p.zx *= rot(-0.125*pi);
  return p.z;
}

#define pi acos(-1.)

float mpow(float num, float times) {
    for (float i = 0.; i < times; i++) {
        num *= num;
    }
    return num;
}

float getScale(float z) {
  //return 1;
  
  return 2.;
  float sep = 3.;
  z = mod(z, sep);
  float id = floor(mod(z, sep));
  if (id == sep - 1.) {
    
      return 1. + mpow(sin(fract(z - sep + 1.)*pi), 4.);
  } else {
    
      return 1.;
  }
}

float r21(vec2 u){
    return fract(sin(u.y*3515125.1 + u.x *124215.125125)*1224115.125235);
}
float r31(vec3 u){
    return fract(sin(u.y*3515125.1 + u.x *124215.125125 + u.z*12525.215215215)*1224115.125235);
}
float valueNoise(vec3 uv){
    vec3 id = floor(uv);
    vec3 fd = fract(uv);
    fd = smoothstep(0.,1., fd);
    
    float ibl = r31(id + vec3(0,-1,0));
    float ibr = r31(id + vec3(1,-1,0));
    float itl = r31(id + vec3(0));
    float itr = r31(id + vec3(1,0,0));
    
    
    float jbl = r31(id + vec3(0,-1,1));
    float jbr = r31(id + vec3(1,-1,1));
    float jtl = r31(id + vec3(0,0, 1));
    float jtr = r31(id + vec3(1,0, 1));
    
    
    float ibot = mix(ibl, ibr, fd.x); 
    float iup =  mix(itl, itr, fd.x);
    float jbot = mix(jbl, jbr, fd.x);
    float jup =  mix(jtl, jtr, fd.x);
    
    float i = mix(ibot, iup, fd.y);
    float j = mix(jbot, jup, fd.y);
    
    return j;
    float h = mix(i, j, fd.z); 
        
    float res = h;
    
    return res;
}

float fbm(vec3 uv){
  uv.z = mod(uv.z, 20.);
    float res = 0.;
  float amp = 1.;
  float gain= 0.5;
  float lac = 2.;
  
  for (float i = 0.; i < 1.;i++){
    uv = abs(uv);
    res += valueNoise(uv*lac)*amp;    
    amp *= gain;
    lac *=2.;    
  }

    return res;
}

#define dmin(dA, dB) (dA.x < dB.x) ? dA : dB
vec3 camOffs(float z){
  z *= 0.2;
  return vec3(
    sin(z) + sin(z*0.2)*0.4,
    cos(z),
    0
  )* ( 1. - getScale(z)) * 0.5;
}

vec3 pipeOffset(float z, float idx) {
  float zScale = z*0.2;
  float scale = 1.;
  float scaleMod = 0.5 - getScale(zScale ) ;
  if (idx == 0.) {
    return vec3(
      cos(z),
      sin(z),
      0
    )*scale*scaleMod;    
  } else if (idx == 2.) {
    return vec3(
      cos(z + 2.4),
      sin(z + 2.4),
      0
    )*scale*scaleMod;    
  } else if (idx == 3.) {
    return vec3(
      cos(z + 4.6),
      sin(z + 4.6),
      0
    )*scale*scaleMod*0.6;    
  } else if (idx == 4.) {
    return vec3(
      cos(z + 5.1),
      sin(z + 5.4),
      0
    )*scale*scaleMod*2.;    
  }
}

#define dmod(p, x) (mod(p, x) - x*0.5)

float getTube(vec3 p, float idx) {
  float d = 10e3;
  p.z *= 0.5;
  if (idx == 0.) {
    vec3 pPipe = p - pipeOffset(p.z, 0.);
    float dTube = sdTube(pPipe,0.2);
    
    pPipe.xy *= rot(p.z*1.6 + sin(time + p.z));
    vec2 uv = vec2(atan(pPipe.x, pPipe.y));
    
      
    dTube -= sin(uv.x*10. + sin(uv.y)*1. + time*5.)*0.07;
    
    return dTube/2.;  
  } else if (idx == 2.) {
    vec3 pPipe = p - pipeOffset(p.z, 2.);
    float dTube = sdTube(pPipe,0.2);
    
      float dbetween = 0.2;
      vec3 pSphere = dmod(p+ vec3(0,0,time*0.1), dbetween) ;
      dTube = max(dTube, sdSphere(pSphere, 0.08));  
    
    return dTube;
  } else if (idx == 3.) {
    
    vec3 pPipe = p - pipeOffset(p.z, 3.);
    float dbetween = 0.2;
    vec3 pRuby= pPipe + vec3(0,0,time*0.1);
    pRuby.xy *= rot(0.2 + time*0.1 + sin(time + p.z));
    
    pRuby.z = dmod(p.z, dbetween);
    
    float id = floor(p.z);
    
    pRuby.y *= 0.9;
    float dTube = sdTube(pPipe,0.1);
    
    float dRuby = sdRuby(pRuby, 0.056);
    
    dTube = min(dTube, dRuby);
    
    //dTube = max(dTube, sdRuby(pRuby, 0.5));
      
    
    return dTube;
  } else if (idx == 4.) {
    vec3 pPipe = p - pipeOffset(p.z, 4.);
    float dTube = sdTube(pPipe,0.2) - fbm(vec3(p.x*1.,p.y*3.,p.z))*0.07;
    
    
    return dTube;
  }
  
 
  return d;
}

vec2 map(vec3 p){
  p.xy -= 5.;
  p.xy = dmod(p.xy, 10.);
  vec2 d = vec2(10e3, 100);
  
  d = dmin(d, vec2(getTube(p, 0.), 0.));
  d = dmin(d, vec2(getTube(p, 2.), 2.));
  d = dmin(d, vec2(getTube(p, 3.), 3.));
  d = dmin(d, vec2(getTube(p, 4.), 4.));
  
  //d = dmin(d, vec2(sdRuby(p - vec3(0,0,time + 3), 0.2), 3.));
  
  
  
  return d/3.;
}

vec3 getNormal(vec3 p) {
    vec2 t = vec2(0.006,0);
    return normalize(
      vec3(map(p).x) - vec3(
        map(p + t.xyy).x,
        map(p + t.yxy).x,
        map(p + t.yyx).x
      )  
    );
}

#define spectra(inp) (0. + 0.3*sin(vec3(0.4,0.7,5.1) + inp))

vec3 glow = vec3(0);
vec4 render(vec2 uv) {
  
  vec3 col = vec3(0);
  vec3 ro = vec3(0.,0.,0. + time*3.) ;
  vec3 lookAt = ro + vec3(0. + sin(time*0.25)*0.6,0. + sin(time*0.25)*0.6,5.);
  ro += camOffs(ro.z);
  
  vec3 rd = getRd(ro, lookAt, uv);
  
  vec2 t = vec2(0);
  vec3 p = ro;
  
  for (int i = 0; i < 150; i++) {
      vec2 d = map(p);
      
      glow += spectra(d.x*20.)*0.0002;
      if (d.x < 0.001) {
        // collision
        
        vec3 posLightA = lookAt - vec3(0,3,2);// + vec3(cos(time*0.2), sin(time*0.2), 0);
        
        float diff = 0.;
        float spec = 0.;
        
        vec3 n = getNormal(p);
        
        vec3 l = normalize(posLightA - p);
        
        if (d.y == 0.) {
          float fres = max(pow(1. - dot(-rd, n), 5.), 0.);
          float diff = max(dot(n,l),0.);
          float spec = max(dot(normalize(ro - p), n),0.);
          col += vec3(0.1) * (spec + diff);
          //col = vec3(1.);
        } else if (d.y == 1.) {
          float fres = max(pow(1. - dot(rd, n), 5.), 0.);
          float diff = max(dot(n,l),0.);
          float spec = max(dot(normalize(ro - p), n),0.);
          col += vec3(0.03) *(fres*diff);
        } else if (d.y == 2.) {
          float fres = max(pow(1. - dot(rd, n), 5.), 0.);
          float diff = max(dot(n,l),0.);
          float spec = max(dot(normalize(ro - p), n),0.);
          col += vec3(0.1) *(fres);
        } else if (d.y == 3.) {
          float fres = max(pow(1. - dot(-rd, n), 1.), 0.);
          float diff = max(dot(n,l),0.);
          float spec = max(dot(normalize(ro - p), n),0.);
          col += vec3(2) *(spec + diff);
        }else  {
          float fres = max(pow(0.6 - dot(rd, n), 1.), 0.);
          float diff = max(dot(n,l),0.);
          float spec = max(dot(normalize(ro - p), n),0.);
          col += vec3(0.06) * fres;
        }
        
        //col *= spectra(d.y*1 + 5);
        break;
      }
      if (d.x > 2000.) {
        // wall
        col = vec3(0.0);
        break;
      }
      t.x += d.x;
      p = ro + t.x * rd;
  }
  col += glow;
  col = pow(col, vec3(0.44));
  
  return vec4(col, 0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    vec4 col = render(uv);

    col.g *= 0.5;
    col.b *= 0.2;
    col *= 1.6;
    glFragColor = vec4(col);
}
