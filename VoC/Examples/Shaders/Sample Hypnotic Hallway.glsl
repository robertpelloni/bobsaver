#version 420

// original https://www.shadertoy.com/view/sdt3W2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a)) //basic rotation matrix thingy yay

float t; vec3 glw; //global time and glow variables

float bx(vec3 p, vec3 s) //like a cube right, but better, because it can be SCALED!
{
  vec3 q=abs(p)-s;
  return min(max(q.x,max(q.y,q.z)), 0.) + length(max(q,0.));
}

float cyl(vec3 p, float r) //a cylinder. do you know where the ends of it are? I sure don't...
{
  return length(p.xz)-r; 
}

float tor(vec3 p, vec2 t) //mmn donut shape - ITS A TORUS OKAY?
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float crys(vec3 p, vec3 pp) //makes a cool fluidy warping crystal thingy, p = result centre, pp = kifs centre
{
  for(float i=0.;i<4.;i++) //blah blah blah kifs yay funky lots of cubes
  {
      pp.xy*=rot(i - 2.+0.1); //rotate it and do fun stuff with "i"
      pp.xy=abs(pp.xy)-i*0.2; //free duplication tactics here
      pp.xy=abs(pp.xy)-2.1; //more high performance cloning
      pp.yz*=rot(i); //some more rotation just to make sure it's REALLY messed up by now
  }
  float b=bx(pp*0.9,vec3(2))-0.03; //create a rando cube in the middle lets go
  b=mix(b,bx(p,vec3(1)),0.5); //mix is actually amazing with SDFs, this turns the whole mess of cubes into something actually interesting and cool. comment out to see the mess instead
  float g=length(p); //i just calculated the distance to the centre of this world or something
  glw+=0.01/(0.01+g*g)*mix(vec3(1,0,0.2),vec3(0.2,0.5,1),sin(t/4.)*0.5+0.5); //glow glow glow glow glow glow glow glow glow
  return b; //"box"
}

vec2 mp(vec3 p) //scene goes here yes
{  
  float i = clamp(10.-t,0.,10.); //smooth intro morph variable yay cool
  float z = (sin(t/3.)*0.5+0.5)*1.5; //slow z warping for better effect
  float ta = 1.-pow(1.-mod(t,3.) * 0.3,2.);
  vec3 co=mix(vec3(1,0,0.2),vec3(0.2,0.5,1),sin(-t/4.)*0.5+0.5); //funky colours yup
  vec3 pp=p-vec3(0,0,i+z); //second position for things yes
  vec3 ppp=p; //more positions because why not
  pp.xy*=rot(-t/3.); //rotate it
  ppp.xy*=rot(t*0.1); //rotate it too
  vec2 cry = vec2(crys(ppp,pp),1.); //it's a glowy crystal, go cry about it - but if you wanna see a different varient, swap ppp and pp in this line
  pp=p;pp.yz*=rot(1.57); //reset pp so we can reuse it and also rotate it aprox 90 degrees
  float tr = tor(pp-vec3(0,12.*ta,0), vec2(16.*ta,0.01)); //donut time!
  cry.x=min(cry.x,tr); //add donut we don't really care about the material it's just for glow
  glw+=0.01/(0.01+tr)*co; //do the glowy :D
  pp=p-vec3(0,9,12);pp.x=abs(pp.x)-11.;pp.x*=0.3;//hooray for free cloning technology
  float br=bx(pp,vec3(0.5,30,100))-0.2; //make background walls exist
  pp.z-=mod(t*5.,20.)+5.; pp.z=abs(pp.z)-10.;pp.z=abs(pp.z)-10.;//bars, he says, BARS!
  float g=bx(pp,vec3(0.8,30,2));//glow amount for bars
  br=min(br,g);//combine so that we don't get messyness
  vec3 coco=vec3(1,1,1)-co; //inverted col
  glw+=0.01/(0.01+g)*coco*0.2; //weird outer glowy stuff idk either but hey it looks neat
  ppp=p;ppp.y=abs(ppp.y)-5.;//get position make position mirror on Y;
  vec2 flr = vec2(bx(ppp-vec3(0,4,0),vec3(50,1,100)),2); //make floor/roof stuff
  flr.x=min(flr.x,br); //actually add the side bits to the raymarch so they don't just get sad and become messy
  return flr.x<cry.x?flr:cry; //and that's that - i wanted to add more bits on the floor/roof but it was causing issues with lighting :(
}

vec2 tr(vec3 ro, vec3 rd, float f) //standard raymarching stuff with a distance field multiplier so we can flip things inside out for transparency
{
  vec2 d = vec2(0); //d=distance, duh. But it also keeps track of the material ID
  for(int i = 0; i < 256; i++) //loopy loopy looping loop
  {
    vec3 p=ro+rd*d.x; //the position is HERE!
    vec2 s=mp(p);s.x*=f; //grab the scene SDF
    d.x+=s.x;d.y=s.y; //move and update material id
    if(d.x>64.||s.x<0.001)break; //break if we reached something or went too far
  }
  if(d.x>64.)d.y=0.;return d; //return distance and ID
}

vec3 nm(vec3 p)
{
  vec2 e = vec2(0.001,0); return normalize(mp(p).x-vec3(mp(p-e.xyy).x,mp(p-e.yxy).x,mp(p-e.yyx).x)); //normals hooray
}

vec4 px(vec4 h, vec3 rd, vec3 n) //pixel.. shader? it shades pixels, okay? got it? cool.
{
  vec4 bg=vec4(0.1,.1,0.1,1); //background colour
  if(h.a==0.)return bg; //oh no we hit the background how sad
  vec4 a=h.a==1.?vec4(0.,1.,1.,0.2):vec4(0.1,0.1,0.15,1); //give it some colour, except not because the glow does most of it
  float d=dot(n,-rd); //ahha this surface is pointy - OR IS IT?!
  float dd=max(d,0.); //diffuse lighting that makes things actually look like things instead of not looking like things
  float f=pow(1.-d,4.); //reflecty edges that aren't really reflecty but look reflecty because they're edges
  float s=(pow(abs(dot(reflect(rd,n),-rd)),40.)*10.); //light bright BUT ONLY WHERE IT NEEDS TO BE
  if(h.a>1.)s*=0.05;//make id 2 more matt instead of shiny
  float ao=clamp(1.-mp(h.xyz+n*0.1).x*14.,0.,1.)*0.9; //sorry, we don't want lighting where things are too close to each other :(
  return vec4(mix(a.rgb*(dd-ao)+s,bg.rgb,f),a.a); //mix it all together - you can replace the whole thing with a vec4(a.rgb*oneofthevalueshere,1.) if you just wanna see what a thing looks like
}

void main(void)
{
  t=time; //time is only temporary
  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y); //u? v? u,v, uv!
  uv -= 0.5; uv /= vec2(resolution.y / resolution.x, 1.); //but now in the middle
  float ts=1.,io=1.14; //ooh fun variables to track transparency bits
  vec3 ro=vec3(0,0,-10),rd=normalize(vec3(uv,1.)),oro=ro,ord=rd,cp,cn,rc,cc; //cam pos and ray dir and even more variables for the transparency loop
  for(int i=0;i<4;i++) //transparency loop! increase the iterations for more transparency depth but less performance if you feel like it. 4 seems like a good middle to me.
  {
    vec2 fh=tr(oro,ord,1.); //go find front of object or something
    cp=oro+ord*fh.x;cn=nm(cp); //figure out the position and normal of the hit
    vec4 c=px(vec4(cp,fh.y),ord,cn); //grab shaded colour for pixel
    if(fh.y==0.||c.a==1.) {cc=mix(cc,c.rgb,ts); break;} //oh no it's the background we gotta get out of here!!
    ro=cp-cn*0.01;rd=refract(ord,cn,1./io); //inject ourselves into the object so we can go THROUGH it!
    vec2 bh=tr(ro,rd,-1.);//go through inverted distance field to find the exiting face of the object we're currently traversing because yes.
    cp=ro+rd*bh.x;cn=nm(cp); //figure out position and normal again because we forgot it already duh
    oro=cp+cn*0.01;ord=refract(rd,-cn,io); //inject ourselves back.. out? outject ourselves? whatever, we back outside again now
    if(dot(ord,ord)==0.)ord=reflect(rd,-cn); //TOTAL INTERNAL REFRACTION D: (but actually it looks sick so whatever)
    cc=mix(cc,c.rgb,ts);ts-=c.a; //finally we update the colour
    if(ts<=0.)break; //if we're still transparent, keep going. If not... time to BREAK OUT OF THIS LOOP!
  }
  glFragColor=vec4(cc+glw,1.); //dude we gotta see things somehow, this does that
}
