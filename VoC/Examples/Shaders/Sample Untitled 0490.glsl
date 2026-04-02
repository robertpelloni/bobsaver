#version 420

// original https://www.shadertoy.com/view/wtd3zX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Inspired by nusan!
// He has really good IFS and refraction techniques.
// Check him out https://www.shadertoy.com/user/nusan

#define dmin(a, b) (a.x < b.x) ? a : b
vec3 ACESFilm( vec3 x )
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return max(vec3(.0), min(vec3(1.0), (x*(a*x+b))/(x*(c*x+d)+e) ) );
}

vec3 getRd(vec3 ro, vec3 lookAt, vec2 uv) {
  vec3 dir = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0,1,0), dir));
  vec3 up = normalize(cross(dir, right));
  
  return dir*1. + right*uv.x*0.3 + up*uv.y*0.3;
}

float sdObjA(vec3 p, float r){  
  p.y *= 0.5;
  p = abs(p);
  p -= r;
  float d = max(p.x, p.y);
  d = max(d, p.z);
  d = max(d, dot(p + 0.2, normalize(vec3(1))));
  return d;
}

float sdCube(vec3 p, vec3 r){
  p = abs(p);
  p -= r;
  float d = max(p.x, p.y);
  return max(d, p.z);
}

#define rot(x) mat2(cos(x), -sin(x), sin(x), cos(x))
#define pi acos(-1.)
vec2 sdMainGeom(vec3 p) {
    vec2 d = vec2(10e3);
    d = dmin(d, vec2(sdObjA(p, 0.5), 1.));
    //d = dmin(d, vec2(sdObjA(p - vec3(0,1,0), 0.5), 3.));
    p = abs(p);
    p -= 0.5;
    p.xz *= rot(0.25*pi);
    d = dmin(d, vec2(sdCube(p, vec3(0.1,2.,0.1)), 2.));
  
  d.x *= 0.5;
  return d;
}

float mpow(float a, float b) {
  for(float i = 0.; i < b; i++) {
      a = a * a;
  }
  return a;
}

float timeMod() {
  float t = time * 0.2;
  return floor(t) + smoothstep(0.,1.,fract(t));
}
#define dmod(p, x) mod(p, x) - x*0.5

vec2 map(vec3 p){
  vec2 d = vec2(10e3);
  

  
  float tMod = mpow(sin(time*0.2),5.);
  
  for (float i = 0.; i < 7.; i++) {
    p.x -= 2. + ( smoothstep(1.,0.,time*0.1) * 5.  ) ; // TODO: smoothstep this from beggining of shader
    
    p.y -= 0.7;
    
    p.xy *= rot(0.6*pi + timeMod());
    p.zy *= rot(0.3*pi );
    p = abs(p);
    
  }
  
  
  d = dmin(d, sdMainGeom(p));
 
  return d;
}

vec3 getNormal(vec3 p) {
    vec2 t= vec2(0.001, 0.);
  return normalize(map(p).x - vec3(
    map(p - t.xyy).x,
    map(p - t.yxy).x,
    map(p - t.yyx).x
  ));
}
#define spectra(x, t) (0.5 + 0.2*sin(vec3(0.5,0.8,0.7)*t + x) )

#define zoom 46.
#define rotSpeed 0.2

float random( vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.1);
}

float noise(vec2 p) {
    vec2 i = ceil(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3. - 2. * f);
       float a = random(i);
    float b = random(i + vec2(1., 0.));
    float c = random(i + vec2(0., 1.));
    float d = random(i + vec2(1., 1.));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(in vec2 p) { 
    float s = .0;
    float m = .0;
    float a = .5;    
    for(int i = 0; i < 5; i++) {
        s += a * noise(p);
        m += a;
        a *= .5;
        p *= 2.;
    }
    return s / m;
}

vec3 carToPol(vec3 p) { // learned this here -- https://www.shadertoy.com/view/WsSXWm
    float r = length(p);
    float the = acos(p.z/r);
    float phi = atan(p.y,p.x);
    return vec3(r,the,phi);
}

vec4 render(vec2 uv) {
  vec3 col = vec3 (0);
  
  vec3 ro = vec3(sin( sin( time*rotSpeed)*pi/2. -2. )*zoom,sin(time + cos(time)),cos(sin(time*rotSpeed)*pi/2. -2. )*zoom);
  vec3 lookAt = vec3(0);
  vec3 rd = getRd(ro, lookAt, uv);
  
  vec3 glow = vec3(0);
  float t = 0.;
  vec3 p = ro; 
  float side = 1.;  // thanks nusan for refraction logic! 
  
  float bounces = 0.;
  
  float colStrength = 1.;
  
  for (int i = 0; i < 220; i++) {
      vec2 d = map(p);
      d.x *= side;
    
      glow += spectra(d.x, 13. + sin(time) * 4.)*0.6;
      if (d.x < 0.001) {
        vec3 n = getNormal(p)*side;
        vec3 posLightA = vec3(0,3.,-4);
        vec3 colLightA = vec3(0.3,0.5,0.9);
        vec3 posLightB = vec3(0,-4.,3);
        vec3 colLightB = vec3(0.5,0.7,0.9);
        
        vec3 lA = normalize(posLightA - p);
        vec3 lB = normalize(posLightB - p);
        vec3 hA = normalize(lA - rd);
        vec3 hB = normalize(lB - rd);
        
        float diffA = max(dot(lA, n), 0.);
        float diffB = max(dot(lB, n), 0.);
        
        float specA = max(dot(n,hA), 0.);
        float specB = max(dot(n,hB), 0.);
        
        float fres = pow(1. - max(dot(n, -rd),0.), 5.);
        
        vec3 colA = diffA * colLightA;
        vec3 colB = diffB * colLightB;
        //col = vec3(1);
        
        
        if (d.y == 1.) {
         
          col += (colA + colB)*glow*colStrength*fres  + fres*0.1;
          
          //col += fres * glow * 0.1*colStrength;
          
          colStrength *= 0.9;
          
          rd = refract(rd, n, 1. + 0.01);
          
          d.x = 0.6;
            
          side *= -1.;
          bounces += 1.;
           
          
        } else if (d.y == 2.) {
          
          
          //col += (colA + colB*0.1)*glow*colStrength + fres*0.6;
          
          col += fres*(colA + colB) + colA*0.8;
          
          rd = reflect(rd, n);
          
          d.x = 0.2;
          colStrength *= 0.4;
          
          bounces += 1.;
        }else if (d.y == 3.) {
         
          col += (colA + colB)*glow*colStrength * vec3(0.9,0.9,0.2) + fres*0.1;
          
          colStrength *= 0.6;
          
          rd = refract(rd, n, 1. + 0.0);
          
          d.x = 0.6;
            
          side *= -1.;
          bounces += 1.;
        
        
        
      }
        
        if (bounces > 5.) break;
        //break;
        //break; 
      }
      
      if (length(p) > 50.) {
        rd.yz *= rot(0.5*pi);    
        
        vec3 pPolar = carToPol(rd);
        
        float fA = fbm(pPolar.yz*6.);
        vec3 fB = fbm(pPolar.yz*6. + fA*6. + time*0.1) * spectra(fA, 90.);
        
        col += fB* colStrength*0.1;
        
        //col = vec3(0);
        break; 
      }
    col += glow*0.00006;
    t += d.x;
    p = ro + rd * t;
  }
  
  
  //col += smoothstep(0.,1., pow(t.x - 54., 7.)) * vec3(0.8,0.3,0.7);
  col *= 0.2;
  col = ACESFilm(col);
  col = pow(col, vec3(0.44));
  return vec4(col, 0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    vec4 col = render(uv);

    glFragColor = vec4(col);
}
