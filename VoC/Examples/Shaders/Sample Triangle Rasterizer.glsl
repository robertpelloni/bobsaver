#version 420

// original https://www.shadertoy.com/view/3djGRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 c2 = vec3(.8,0.9,1.);//points
vec3 c1 = vec3(1.,0.9,.7);//tradict
vec3 c0 = vec3(.7,0.7,1.);//barycenterCircle
vec3 c3 = vec3(1,1,1);//background
vec3 c4 = vec3(1.,0.2,.6);//barycenter
vec3 c5 = vec3(.6,1.,.2);//barycenter
vec3 c6 = vec3(0.2,.6,1.);//barycenter

float R;
const int samples = 50;
vec2 g;
vec4 color;

const float PI = 3.14159265;

float cLength(vec2 p){
  if(abs(p.x)>abs(p.y))return abs(p.x);
  return abs(p.y);
}

void rasterize(vec2 uv){

}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float asp = resolution.y/resolution.x;
    uv-=0.5;
    uv.y *= asp;
    uv *= 0.4;
    color = vec4(c3,1.0);

    
    //time = time*0.6;
    
    float r = 0.1;
    
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy-0.5;
    
    float t0 = time+sin(time*2.);
    float t1 = time+cos(time*2.);
    float t2 = time-sin(time*2.);

    vec2 p0 = vec2(r*sin(t0-2.*PI/3.),r*cos(t0-2.*PI/3.));
    vec2 p1 = vec2(r*sin(t1),r*cos(t1));
    vec2 p2 = vec2(r*sin(t2-4.*PI/3.),r*cos(t2-4.*PI/3.));
   
      
    float m0 = (p1.y-p0.y)/(p1.x-p0.x);
    float m1 = (p2.y-p1.y)/(p2.x-p1.x);
    float m2 = (p0.y-p2.y)/(p0.x-p2.x);
    
    //ax + by + c = 0
    //y = m(x-p.x) + p.y ;
    //mx + (-1)y + ( -mp.x + p.y ) = 0;

    float d0 = abs(m0*uv.x + (-1.)*uv.y+ (-m0*p0.x+p0.y))
                     /length(vec2(m0,-1));
    float d1 = abs(m1*uv.x + (-1.)*uv.y+ (-m1*p1.x+p1.y))
                     /length(vec2(m1,-1));
    float d2 = abs(m2*uv.x + (-1.)*uv.y+ (-m2*p2.x+p2.y))
                     /length(vec2(m2,-1));

    float po = 100.;
    vec2 grid = fract(uv*po);
    vec2 st = uv-(grid-0.5)/po ;
    //α＝{(By-Cy)(Px-Cx)+(Cx-Bx)(Py-Cy)}/{(By-Cy)(Ax-Cx)+(Cx-Bx)(Ay-Cy)}
    //β＝{(Cy-Ay)(Px-Cx)+(Ax-Cx)(Py-Cy)}/{(By-Cy)(Ax-Cx)+(Cx-Bx)(Ay-Cy)}
    //γ＝１−αーβ
      float Ax = p0.x;
      float Ay = p0.y;
      float Bx = p1.x;
      float By = p1.y;
      float Cx = p2.x;
      float Cy = p2.y;
      float Px = st.x;
       float Py = st.y;
    float alpha = ((By-Cy)*(Px-Cx)+(Cx-Bx)*(Py-Cy))/((By-Cy)*(Ax-Cx)+(Cx-Bx)*(Ay-Cy));
     float beta =  ((Cy-Ay)*(Px-Cx)+(Ax-Cx)*(Py-Cy))/((By-Cy)*(Ax-Cx)+(Cx-Bx)*(Ay-Cy));
    float gamma = 1.-alpha-beta;

    if(grid.x<0.05)color=vec4(c0,1);
    if(grid.y<0.05)color=vec4(c0,1);
    if(cross(vec3(p1-p0,0),vec3(st-p0,0)).z < 0. &&
        cross(vec3(p2-p1,0),vec3(st-p1,0)).z < 0. &&
       cross(vec3(p0-p2,0),vec3(st-p2,0)).z < 0. ){
        color = vec4(c4*alpha + c6*beta + c0 * gamma,1.);
         if(grid.x<0.05)color=vec4(c3,1);
         if(grid.y<0.05)color=vec4(c3,1);
    }
        
    //edges
    float w = 0.001;
    if((abs(d0)<w ||
         abs(d1)<w||
        abs(d2)<w)
      &&length(uv)<0.1){
        color = vec4(c4*alpha + c6*beta + c0 * gamma,1.);
        //color = mix(color,vec4(c4,1),max(sin(time)+0.3,0.));
    }
    //vertices
  
      if(length(uv-p0)<0.006) color = vec4(c4,1);
      if(length(uv-p1)<0.006) color = vec4(c6,1);
      if(length(uv-p2)<0.006) color = vec4(c0,1);

    // Output to screen
    //if(abs(length(uv)-r)<0.007)glFragColor=vec4(c1,1);
    if(length(uv-g)<R)color*=vec4(c2,1);
    glFragColor = color;
    
}
