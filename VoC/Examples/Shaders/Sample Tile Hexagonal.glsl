#version 420

// original https://www.shadertoy.com/view/mttcRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hexdist(vec2 uv){
    vec2 p=abs(uv);
    
    float c=dot(p,normalize(vec2(1.,1.732)));
   
    
    float x=abs(p.x);
   // 
    float d=max(c,x);
    return d;
}
vec4 HexCoords(vec2 uv){
     
    vec2 r=vec2(1.,1.732);
    vec2 h=r*0.5;
    vec2 a=mod(uv,r)-h;
    vec2 b=mod(uv-h,r)-h;
    //vec2 a=fract(uv)-0.5;
    //vec2 b=fract(uv-0.5)-0.5;
    // col.rg=fract(uv-sin(time))-0.5;
   
    //float d=hexdist(uv);
    // d=step(d,0.3);
    //d=sin(d*10.+time*2.);
    //col+=d;
   // col.rg=a;
   
   
   vec2 gv=dot(a,a)<dot(b,b)?a:b; 
   vec2 id=uv-gv;
      
   float x=0.;
   x=atan(gv.x,gv.y);
   
  
   
  // x=(floor(x/1.046)+3.)/6.;//1.046=3.14/3=60°
   x=mod(x+time*2.,6.28);
   x=floor(x/1.046)/6.;
   
   float y=0.5-hexdist(gv);
   
   return vec4(x,y,id.x,id.y);
}
void main(void)
{
  
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.0);
    
    uv*=9.;
    
    vec2 r=vec2(1.,1.732);
    vec2 h=r*0.5;
    vec2 a=mod(uv,r)-h;
    vec2 b=mod(uv-h,r)-h;
    //vec2 a=fract(uv)-0.5;
    //vec2 b=fract(uv-0.5)-0.5;
    // col.rg=fract(uv-sin(time))-0.5;
   
    //float d=hexdist(uv);
    // d=step(d,0.3);
    //d=sin(d*10.+time*2.);
    //col+=d;
   // col.rg=a;
    //col.rg=dot(a,a)<dot(b,b)?a:b;
    vec4 hc = HexCoords(uv+vec2(100.,12.));
    float c=smoothstep(0.01,0.08,hc.y*sin(hc.z*hc.w+time));
    
    vec3 color=mix(vec3(0.9,0.19,0.8),vec3(0.3,0.4,0.87),hc.x);
    //c*=hc.x;
    col+=c;
    col*=color;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
