#version 420

// original https://www.shadertoy.com/view/7stSzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi acos(-1.)

float noise(vec2 st){
    return fract(sin(dot(vec2(12.23,74.343),st))*43254.);  
}

float noise2D(vec2 st){
  
  //id,fract
  vec2 id =floor(st);
  vec2 f = fract(st);
  
  //nachbarn
  float a = noise(id);
  float b = noise(id + vec2(1.,0.));
  float c = noise(id + vec2(0.,1.));
  float d = noise(id + vec2(1.));
  
  
  //f
  f = smoothstep(0.,1.,f);
  
  //mix
  float ab = mix(a,b,f.x);
  float cd = mix(c,d,f.x);
  return mix(ab,cd,f.y);
}

mat2 rot45 = mat2(0.707,-0.707,0.707,0.707);

mat2 rot(float a){
  float s = sin(a); float c = cos(a);
  return mat2(c,-s,s,c);
}
float fbm(vec2 st, float N, float rt){
    st*=3.;
 
  float s = .5;
  float ret = 0.;
  for(float i = 0.; i < N; i++){
     
      ret += noise2D(st)*s; st *= 2.9; s/=2.; st *= rot((pi*(i+1.)/N)+rt*8.);
      //st.x += time;
  }
  return ret;
  
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;

    uv.x += time*0.1;
    float fa1 = fbm(uv*1.*rot(2.2)  ,5., 3.);
    float fb1 = fbm(uv*1.*rot(5.3) + vec2(3. ,3. ) ,5., 5.);
  

  float fa2 = fbm(uv*2.*rot(2.) - vec2(8. ) + fa1 ,2., 8.);
  float fb2 = fbm(uv*2.*rot(1.) + vec2(3.,4. ) + fb1 ,5., 6.);
  
  float fa3 = fbm(uv*1.*rot(1.5) + vec2(6. ) + fa2 ,5., 1.);
  float fb3 = fbm(uv*1.*rot(1.8) + vec2(1. ,47. ) + fb2, 3., 2.);
  
  
  vec3 col = vec3(0.);
  
  
    col= mix(col, vec3(0.5,0.,0.),fb3);
  col= mix(col,vec3(1.),fb3*fa3);
  col= mix(col,vec3(0.9,0.6,0.2),fa3*(uv.y*0.5+0.5));
  //col= mix(col,vec3(0.2,0.,0.9),fb3*pow(abs(uv.x*0.9),10.) );
  col= mix(col,vec3(0.8,0.4,0.3), smoothstep(0.3,1.,fb3) );
  col= mix(col,vec3(0.2,0.1,0.1), smoothstep(0.3,.2,fa3) );
  col *= (fb3+0.5);

  col.yz *= rot(5.6);
  //col.xy *= rot(time);
  col = pow(col,vec3(0.8));
    glFragColor = vec4(col,1.);;
}
