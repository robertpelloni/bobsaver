#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3dXBWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 z,v,e=vec2(0.01,0);
float t,tt;vec3 np,bp,no,po,ld,al,g; //global variables

mat2 r2(float r){ return mat2(cos(r),sin(r),-sin(r),cos(r)); }

// SDF taken from evvvvil thanx to him learn a lot from his code ;)
float cy(vec3 p,vec3 r){ return max(abs(length(p.xz)-r.x)-r.y,abs(p.y)-r.z/2.); }
vec2 fb( vec3 p,float s,float m) 
{
  for(int i=0;i<4;i++){
    p=abs(p);
    p.xy*=r2(.48);
    p.yz*=r2(s*sin(p.z*.5)*.3);
  }

  vec2 h,t=vec2(cy(p,vec3(2,.3,.4)),m);//Make thin hollow tube 
  h=vec2(cy(p,vec3(2,.1,.6)),2.5); //Make white hollow tube
  t=t.x<h.x?t:h; //(blend geometry together while retaining material ID)
  h=vec2(cy(p,vec3(2.,.4,.2)),3.5); //Make black hollow tube
  t=t.x<h.x?t:h; //(blend geometry together while retaining material ID)
  return t;
}

vec2 road( vec3 p, float r){
  vec2 h,t=vec2(cy(p,vec3(r,.5,1)),5.);
  h=vec2(cy(p,vec3(r,.5,5)),3);
  h.x=abs(h.x)-.1;
  h.x=max(h.x,abs(p.y)-.6);
  t=t.x<h.x?t:h;
  t.x=max(t.x,-(abs(p.z)-.8));
  h=vec2(cy(p,vec3(r,1.2,.5)),2.5); 
  //g+=0.1/(2.01+h.x*h.x*100.);//Glow trick by Balkhan, which I tend to rinse and use as a party trick.
  t=t.x<h.x?t:h;
  t.x=max(t.x,-(abs(p.z)-1.8));
  h=vec2(cy(p,vec3(r,0.5,.125)),1.5);
  //g+=0.1/(2.01+h.x*h.x*100.);
  h.x=abs(h.x)-.005;
  //h.x=max(h.x,abs(p.y)-.2);
  
  t=t.x<h.x?t:h;
  //t.x=max(t.x,-(abs(p.z)-.8));
    
  return t;
}

vec2 map( vec3 p ){
    vec3 pp = p, pp2 = p;

    pp.xy *= r2(tt);
    pp.xz *= r2(-tt*3.);
    pp2.xy *= r2(-tt);
    pp2.xz *= r2(tt*2.);

    vec2 h,t=road(pp2, 5.);
      
      h=road(pp, 8.);
      t=t.x<h.x?t:h;

      h=road(pp2, 11.);
      t=t.x<h.x?t:h;

      h=road(pp, 14.);
      t=t.x<h.x?t:h;

      return t;
}

float calcAO( in vec3 pos, in vec3 nor ){
    float ao = 0.0;

    vec3 v = normalize(vec3(0.7,0.5,0.2));
    for( int i=0; i<12; i++ )
    {
        float h = abs(sin(float(i)));
        vec3 kv = v + 2.0*nor*max(0.0,-dot(nor,v));
        ao += clamp( map(pos+nor*0.01+kv*h*0.2).x*3.0, 0.0, 1.0 );
        v = v.yzx; if( (i&2)==2) v.yz *= -1.0;
    }
    ao /= 12.0;
    ao = ao + 2.0*ao*ao;
    return clamp( ao*2.5, 0.0, 1.0 );
}

vec2 march( in vec3 ro, in vec3 rd, in float _max, in int iter ){ //main trace  / raycast / raymarching loop function 
    vec2 h,t= vec2(.1); //0.1 is near plane
      
      for(int i=0;i<iter;i++){ //march for iter amount of iterations
        h=map(ro+rd*t.x);     //get distance to geom
        if(h.x<.00001||t.x>_max) break; //conditional break we hit something or gone too far
        t.x+=h.x;t.y=h.y; //huge step forward and remember material id
      }
  
      if(t.x>_max) 
          t.y=0.;//if we hit far plane return material id = 0, we will use it later to check if we hit something
  
      return t;
}

void main(void)
{
    vec2 uv=(gl_FragCoord.xy/resolution.xy-0.5)/vec2(resolution.y/resolution.x,1); //get UVs
      tt=mod(time,62.9); //modulo time to avoid glitchy artifact and also nicely reset camera / scene
      vec3 lp=vec3(0., 5. , cos(tt)*2.);//vec3(3.+cos(tt*.2)*10.,6.+sin(tt*.4)*5.,-6); //light position
  
      vec3 ro= lp*mix(vec3(1),vec3(-1,3.2,1),ceil(cos(tt))), // ray origin = camera position
      cw=normalize(vec3(sin(tt*.4)*2.,cos(tt*.2)*10.,0)-ro), //camera forward vector
      cu=normalize(cross(cw,vec3(0,1,0))), //camera left vector ?
      cv=normalize(cross(cu,cw)), //camera up vector ?
      rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo; //ray direction */
      
      lp+=vec3(0,5.+sin(tt)*.5,5); // light position offset animation
      co=vec3(.09)-length(uv*.8)*.107, fo=vec3(.1); // background with pseudo clouds made from noise
      z=march(ro,rd,50.,128);
      t=z.x; // let's trace and get result
      
      if(z.y>0.){ // we hit something 
        po=ro+rd*t; // get position where we hit
        ld=normalize(lp-po); //get light direction from light pos
        no=normalize(map(po).x-vec3(map(po-e.xyy).x,map(po-e.yxy).x,map(po-e.yyx).x));

        if(z.y==1.5) al=vec3(1.);
        if(z.y==2.5) al=vec3(1., .05, 0.);
        if(z.y==3.5) al=vec3(.6);
        if(z.y==5.) al=vec3(.7, .5, 0);
        if(z.y>5.) al=vec3(.1, .4, .7);
        float dif=max(0.,dot(no,ld)), // diffuse lighting
           fr=pow(1.-abs(dot(rd,no)),4.);
        //spo=exp2(15.).r, // Gloss specular map made from noise
        float sp=pow(max(dot(reflect(-ld,no),-rd),0.),20.),
        ldd=length(lp-po), attn=1.0-pow(min(1.0,ldd/25.),4.0); 
        float ao = calcAO(po, no);
        co = al * (fr+ attn) * dif * vec3(ao) ;
        //co=dif*al*fr*attn;
    }

    glFragColor = vec4( pow(co+g*.2,vec3(.45)),1);
}
