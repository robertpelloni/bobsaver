#version 420

// original https://www.shadertoy.com/view/WsfcW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Compass and Straight Edge by eiffie
//a day into home quarantine and I'm bored enough to try creating
//the regular polygons using a compass and straight edge
//i got to 9... almost :)
//there is no math here just a recreation of the chalk scribbles
#define tym time
#define rez resolution.xy
#define tau 6.283

float hash(vec2 v){return fract(sin(dot(v,vec2(117.0,113.3)))*4036.123);}
vec2 norm(float a){return vec2(cos(a),sin(a));}
vec3 compass(vec2 v, vec2 c, float r){
  v-=c;
  return vec3(10.0,0.3*length(v),abs(length(v)-r));
}
vec3 edge(vec2 v, vec2 a, vec2 b){
  vec2 p=b-a;a=v-a;p*=clamp(dot(a,p)/dot(p,p),0.0,1.0);
  return vec3(distance(a,p),0.3*min(length(a),length(v-b)),10.0);
}
void main(void) {
  vec2 U = gl_FragCoord.xy;
  vec4 O = glFragColor;

  vec2 p=2.0*(2.0*U.xy-rez)/rez.x;
  float rnd=hash(U)*0.8+0.2;
  vec3 blue=vec3(0.5,0.6,0.7),red=vec3(0.9,0.6,0.5),green=vec3(0.6,0.7,0.5),col=vec3(10.0);
  float time=mod(tym*0.4,6.5);//time=6.1;
  if(time<1.0){//isosceles triangle
    for(int i=0;i<3;i++){
      float a=tau*float(i)/3.0+tau/12.0;
      col=min(col,compass(p,norm(a)*0.285,0.5));
      a+=tau/2.0;
      col=min(col,edge(p,norm(a)*0.58,norm(a+tau/3.0)*0.58));
    }
  }else if(time<2.0){//square
    for(int i=0;i<3;i++){
      float a=tau*float(i)/3.0+tau/12.0;
      col=min(col,compass(p,norm(a)*0.285,0.5));
    }
    col=min(col,edge(p,vec2(0.0,-1.0),vec2(0.0,0.75)));
    p.y+=0.285;
    for(int i=0;i<4;i++){
      float a=tau*float(i)/4.0;
      col=min(col,edge(p,norm(a)*0.5,norm(a+tau/4.0)*0.5));
    }
  }else if(time<3.0){//pentagon
    p.x+=0.25;
    for(int i=0;i<3;i++){
      float a=tau*float(i)/3.0+tau/12.0;
      col=min(col,compass(p,norm(a)*0.285,0.5));
    }
    col=min(col,edge(p,vec2(0.0,-1.0),vec2(0.0,0.75)));
    col=min(col,edge(p,norm(tau/12.0),-norm(tau/12.0)));
    col=min(col,edge(p,vec2(0.0),norm(-tau/12.0)*0.58));
    p-=norm(tau/12.0)*0.285;
    for(int i=0;i<5;i++){
      float a=tau*float(i)/5.0;
      col=min(col,compass(p,norm(a)*0.5,0.58));
      a+=tau/10.0;
      col=min(col,edge(p,norm(a)*0.9,norm(a+tau/5.0)*0.9));
    }
  }else if(time<4.0){//hexagon
    col=compass(p,vec2(0.0),0.5);
    for(int i=0;i<6;i++){
      float a=tau*float(i)/6.0;
      col=min(col,compass(p,norm(a)*0.5,0.5));
      a+=tau/12.0;
      col=min(col,edge(p,norm(a)*0.87,norm(a+tau/6.0)*0.87));
    }
  }else if(time<5.0){//heptagon
    col=compass(p,vec2(0.0),0.5);
    col=min(col,compass(p,vec2(-0.5,0.0),0.5));
    col=min(col,edge(p,vec2(0.0),vec2(-0.5,0.0)));
    col=min(col,edge(p,vec2(-0.25,-0.44),vec2(-0.25,0.44)));
    for(int i=0;i<7;i++){
      float a=tau*float(i)/7.0;a+=tau/19.7;
      col=min(col,compass(p,norm(a)*0.5,0.44));
      a+=tau/14.0;
      col=min(col,edge(p,norm(a)*0.84,norm(a+tau/7.0)*0.84));
    }
  }else if(time<6.0){//octagon
    col=compass(p,vec2(0.5,0.0),1.0);
    col=min(col,compass(p,vec2(-0.5,0.0),1.0));
    col=min(col,edge(p,vec2(0.5,0.0),vec2(-0.5,0.0)));
    col=min(col,edge(p,vec2(0.0,-0.88),vec2(0.0,0.88)));
    col=min(col,compass(p,vec2(0.0,0.0),0.5));
    for(int i=0;i<4;i++){
      float a=tau*float(i)/4.0;
      col=min(col,compass(p,norm(a)*0.5,0.7));
      a+=tau/8.0;
      col=min(col,edge(p,vec2(0.0),norm(a)*0.95));
    }
    for(int i=0;i<8;i++){
      float a=tau*float(i)/8.0;
      col=min(col,edge(p,norm(a)*0.5,norm(a+tau/8.0)*0.5));
    }
  }else{//9gon
    col=compass(p,vec2(0.5,0.0),1.0);
    col=min(col,compass(p,vec2(-0.5,0.0),1.0));
    col=min(col,edge(p,vec2(0.5,0.0),vec2(-0.5,0.0)));
    col=min(col,edge(p,vec2(0.0,-0.88),vec2(0.0,0.88)));
    col=min(col,compass(p,vec2(0.0,0.0),0.5));
    col=min(col,compass(p,vec2(0.5,0.0),0.7));
    p.x-=0.5;
    for(int i=0;i<9;i++){
      float a=tau*float(i)/9.0;
      col=min(col,compass(p,norm(a),0.7));
      a+=tau/9.0;
      col=min(col,edge(p,norm(a),norm(a+tau/9.0)));
    }
  }
  col=smoothstep(vec3(3.0/rez.y),vec3(0.0),col)*0.85+vec3(0.0,0.0,0.15);
  O=vec4(rnd*(red*col.r+green*col.g+blue*col.b),1.0);

  glFragColor = O;
}
