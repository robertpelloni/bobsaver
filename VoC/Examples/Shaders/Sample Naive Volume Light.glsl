#version 420

// original https://www.shadertoy.com/view/ws33R7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define MULTILIGHT //second light
#define USESHADOW //shadows only work for simple shapes and get very glitchy with multiple lights
//#define MULTICOLOR //uncomment this to see the artifacts that happen when multicolored lights interact

vec2 e = vec2(0.0035f,-0.0035f); 
float tt,lr=3.0; //lr is light radius
vec3 ld,fo,glow; //light direction vector, background color, accumulated glow

mat2 r2(float a) { 
    return mat2(sin(a + 1.57), sin(a), sin(a + 1.57 * 2.), sin(a + 1.57));
}

float smin(float d1, float d2) { //smooth minimum
  float h=clamp(.5+.5*(d2-d1)/0.2,0.0,1.0);
  return mix(d2,d1,h)-0.2*h*(1.-h);
}

float bo(vec3 pos, vec3 b)
{
    vec3 d = abs(pos) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float noi(vec3 p) { //triplanar sampling for some reflection detail
    float ns = 0.0;//texture(iChannel0,p.xy*.3).r*.3;
    //ns+=texture(iChannel0,p.xz*.3).r*.3;
    //ns+=texture(iChannel0,p.yz*.3).r*.3;
    return ns;
}

vec3 getAlbedo(float mi) { // seperated this for convenience
  if(mi<.4)return vec3(1.,.4,.0);
  if(mi>.6)return vec3(0,0,1);
  return vec3(1);
}

vec4 mp(vec3 p) {//we need extra data for lights, but a vec4 is enough
    vec2 l,h,g,t=vec2(p.y,.5); //using evvvvils method for material id's
    t.x=min(t.x,bo(abs(p)-vec3(4,0,4),vec3(.5,12.,.5)));
  t.x=min(t.x,-length(p)+12.);
    h=vec2(length(p-vec3(0,2,0))-2.3,1.2); //lets add some reflective stuff, just to show we can
    t=t.x<h.x?t:h; //how we mix material id's
    h=vec2(bo(abs(p+vec3(0,-2.6+sin(tt*.4),0))-vec3(0,0,2.9),vec3(4.6,.5,.5)),2.9); //and some transparent stuff, for the same reason
    t=t.x<h.x?t:h;
  vec3 np = p+vec3(0,-6.5,cos(tt*.5)*4.);np.yz*=r2(tt*.3); np.xz*=r2(tt*.2); //make it spin
    h=vec2(bo(np,vec3(2.5,.2,.2)),10.5); //light geometry, and our lights of course also have materials
#ifdef MULTILIGHT
  g=vec2(bo(p+vec3(sin(tt*.5)*3.,-5.,cos(tt*.5)*3.),vec3(.2,.2,4.)),10.1); //more light geometry, define MULTILIGHT to see ...
#ifndef MULTICOLOR
  h.x=smin(h.x,g.x); //...soft minimum for smooth transition or...
#else
  h=vec2(smin(h.x,g.x),h.x<g.x?h.y:g.y); // ... ugly artifacts when multicolored lights interact since we only guess one light direction
#endif
#endif
  glow+=(0.1/(0.1+pow(abs(h.x),2.))*.5)*getAlbedo(fract(h.y)); //accumulate some glow on our lights for better looks
  t.x*0.9;h.x*=.9;
  t=t.x<h.x?t:h; // final mixdown
  
    return vec4(t,h); //return dist and mat at xy, lights only on zw
}

vec3 tr(vec3 p, vec3 r) { //do it all in the trace, lights, materials, shadows, everything
  vec4 m = vec4(0.001);float t=0.,sig,tf,ff;
  vec3 no,acc=fo, sr; //some helpers 
  for(int b=0;b<2;b++) { //stay bouncy
    sig=1.;tf=.75*float(b); //sign (are we inside yet?) and a correction factor for reflections and transparency, because I don't want full transparency or perfect reflections 
    for(int i=0;i<120;i++) {
      p=p+r*m.x; //baby steps
      m =abs(mp(p)); //a vec4 because we also need distance to closest light and its material
      t+=m.x; //total distance
      if(t>30.) return mix(fo,acc,ff*tf); //we went too far, use the last calculated fog color and correction factor to make sure far reflective objects get fogged correctly
      if(m.x<0.001f) { //we hit something
        mat4 drs = mat4(mp(p+e.xyy),mp(p+e.yyx),mp(p+e.yxy),mp(p+e.xxx)); //grab everything we need for normals and area light direction, so we don't need to calculate everything twice
        no=normalize(e.xyy*drs[0].x+e.yyx*drs[1].x+e.yxy*drs[2].x+e.xxx*drs[3].x); //normals as usual
        ld=-normalize(e.xyy*drs[0].z+e.yyx*drs[1].z+e.yxy*drs[2].z+e.xxx*drs[3].z); //light direction 
        sr=ld;ld=normalize(no*.05+ld); //store for shadows, then bias by normal to fake away edge cases and pretend our lights have volume
        float dif=(1.-exp2(-2.*pow(max(0.,lr-m.z/lr),2.)))*max(.0,dot(no,ld)), //our diffuse light, similar to how we do...
        aor=t/50.,ao=exp2(-2.*pow(max(0.,1.-mp(p+no*aor).x/aor),2.)), //... ambient occlusion!
        sp=pow(max(dot(reflect(-ld,no),-r),0.),4.), //specular
        mi=fract(m.y),ri=trunc(fract(m.y*.1)*10.),si=trunc(m.y*.1); //encoded material properties, >10 means luminant, >1 means reflective, >2 means transparent, .1-.9 mark colors... so 11.2 is a reflective white light
        vec3 lc=getAlbedo(fract(m.w)); //encoded light material
        vec3 nr,alb=getAlbedo(mi); //we have a helper for albedo, since we also use it for light color and glow
        if(si>0.){dif=1.;sp=0.;} //luminant material
        ff=exp(-.00012*t*t*t); //fog factor
        acc=mix(fo,mix((sp*lc)*dif+alb*(.4*ao+0.6)*(lc*dif)+glow*.1,acc,tf),ri>=1.?ff+tf:ff); //mixdown, respect limits in reflection pass
        if(ri<1.) {b=1;break;} //are we cool yet?
        tf=.5; //increase opacity of transparent objects in the next bounce
        nr=ri<2.?refract(r,-no,1.-.8*noi(p)):refract(r,no*sig,.9-.8*noi(p)); //nope, not cool, so refract or reflect?
        if(nr.x+nr.y+nr.z==0.){nr=reflect(r,no);ri+=1.;} //handle refraction edge cases
        r=nr;p=p+r*.05; //our new ray
        if(ri<2.) break; //reflect
        sig=-sig; //refract
      }
    }
    #ifdef USESHADOW //soft shadows
    //done in the bounce, so we have shadows in reflections and on reflective objects as well
    vec3 so=p+sr*.01,sco=vec3(1); 
    float st=0., sh = 1.; 
    vec4 sd=vec4(.01,0,.01,0);
    if(trunc(m.y*.1)<=0.) { //don't cast shadows on luminant objects
        for(int i=0; i<80;i++) {
          so=so+sr*sd.x; sd=abs(mp(so)); float ri = trunc(fract(sd.y*.1)*10.); 
          if(trunc(sd.y*.1)>0.) { break; } //we are close to a light, so bail
      if(sd.x<.0001) {//we hit geometry and are most likely in total shadow...
        if(ri>=2.)  { sd.x=0.01; } //... but maybe we hit something transparent
        else {sh=0.0; break;} 
      } 
          sh=min(sh,sd.x/st*24.); st+=sd.x; //accumulate shadow
      if(ri>=2.) { sh=max(sh,.4); sco=mix(getAlbedo(fract(sd.y)),vec3(1),sh); }//make transparency great again
          if(st>lr*4.){  break; } //out of light radius, so bail
        }
        acc=acc*.5+acc*.5*sh*sco; //keep some ambient
    }
    #endif
  }
  return acc;
}

void main(void)
{
    //basic setup
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
    tt = mod(time,3000.0);
    vec3 ro=vec3(sin(tt*.25)*10.,4.,cos(tt*.25)*10.),
        cw=normalize(vec3(0.,1.5+sin(tt*.25)*1.5,0.)-ro),
        cu=normalize(cross(cw,vec3(0,1,0))),
        cv=normalize(cross(cu,cw)),
        rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5));
    fo=vec3(0.1,.2+uv.y*.2,.3+uv.y*.2); //background fog color
    vec3 co = tr(ro,rd); //the grand trace
    glFragColor = vec4(co,1.f);
}
