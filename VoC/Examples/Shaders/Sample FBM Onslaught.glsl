#version 420

// original https://www.shadertoy.com/view/sl3GWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi acos(-1.)
#define eps 1./resolution.y

float noise(vec2 st){
    return fract(sin(dot(vec2(12.23,74.343),st))*4254.);  
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

float voronoi(vec2 uv){
  
    float d = 100.;
    vec2 uvFL = floor(uv);
    vec2 uvFR = fract(uv);
  
    for(float i = -1.; i <= 1.; i++){
      for(float j = -1.; j <= 1.; j++){
        
        vec2 nachbar = vec2(i,j);
        
        d = min(d, length( uvFR - noise(uvFL + nachbar)  - nachbar));
      }
    }
    return d;
}
void main(void)
{
  
  vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
  
  uv.x+=time*0.4+10.;
  vec3 col = vec3(0.0);
  
  float fa1 = smoothstep(0.2, 0.9,
              abs( fract(fbm(uv + length(uv)*0.5,5., 2.)*2.)-0.5) );
  
  
  float fb1 = fbm(uv*2. + vec2(3. ,3. ) ,5., 5.);
  
  

 // float fa2 = fbm(uv*2.*rot(2.) - vec2(8. ) + fa1 ,2., 3.);
  
  //float fa2fr = smoothstep(0.2, 0.5,
  //            abs( fract(fa2*10.)-0.5) );
  
  float fb2 = fbm(uv*3.+ fa1/5. ,4., 3.);
  
  //float fb2fr = smoothstep(0., 0.9,
  //            abs( fract(fb2*2.)-0.5) );
 
 // float fa3 = fbm(uv+ fa2 ,5., 1.);
   //float fb3 = fbm(uv*1.*rot(1.8) + vec2(1. ,47. ) + fb2 , 3., 2.);
  
  //softer version
   float fb3 = fbm(uv*1.*rot(1.7) + vec2(1. ,47. ) + fb2*.5 , 3., 2.);
   
   
   float fb3b = fbm(uv*2. + fb1*2. + vec2(sin(uv.x/4.),0.), 2., 2.);
    float fb3c = fbm(uv + fb1*2. + vec2(3.), 4., 2.);

    col = mix(col, vec3(0.,1.,1.),pow(fb3*1.1, 5.));
    
    col = mix(col, vec3(atan(vec2(uv.x,uv.y+0.4))*.8, 0.), pow(fb3,1.6));
    //col = mix(col, vec3(0.,sin(uv.y),0.9), pow(fb2, 15.));
    col = mix(col, vec3(0.,0.,0.),fa1*.9);    
    col *= 1.5;
    
    //col = mix(col, vec3(.4,0.9,0.9),pow(fb2,9.));
    //col = pow(col*vec3(0.9,0.99,0.9), vec3(1.));

   
   /*
    col = mix(col, vec3(0.9,sin(vec2(uv.yy))), pow(fb3, 3.))*2.3;
    
    col = mix(col, vec3(0.8,sin(uv.y),.0), pow(fb2, 8.)*4.)*1.2;
    
    col = mix(col, vec3(0.,0.,0.),fa1*0.99);
    //col = mix(col, vec3(1.),fa2*0.1);
    
    //col = mix(col, vec3(0.),voronoi(uv*2.));
    //
    col = mix(col, vec3(.9,0.9,0.9),pow(fb2,4.))*1.3;
   
   */
   
   
    col = sin(vec3(1.,2.,9.)/80. + col + 6.1);
    //col = mix(vec3(1.,0.,0.), vec3(1.), clamp(col*3.,0.,1.));
    col = mix(col, vec3(.0,0.0,0.2),voronoi(uv*3.))*1.;
    float dasBit = pow(dot(normalize(vec3(1.)),normalize(vec3(uv,1.))),9.);
    col = mix(col, vec3(.9,0.9,0.9),pow(fb2,5.))*1.3 +dasBit;  
    
    //col = mix(col, vec3(.9, .0 ,1.), );
    
    col = mix(col, vec3(4.3), pow(fb3b, 4.) );
    col = mix(col, vec3(2.,6.,9.)*.1, pow(fb3c, 4.) );
    //col = mix(col, vec3(0.9,0.4,0.)*1., pow(fb3, 7.) );
    
    //when I use Flux it's this: 
    //glFragColor = vec4(col*vec3(0.9,0.8,.4),1.0); //lol
    //but that is actually only there because I forgot flux the first time lol
    col *= 1.4;
    //col =pow(col,vec3(1.,0.9, 1.));
    glFragColor = vec4(col*vec3(0.8,0.65,.2),1.0);
}

