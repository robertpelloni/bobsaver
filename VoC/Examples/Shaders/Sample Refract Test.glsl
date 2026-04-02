#version 420

// original https://www.shadertoy.com/view/slXGWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float box(vec3 p,vec3 b){
    vec3 q = abs(p)-b;
    return length(max(vec3(0.),q))+min(0.,max(q.x,max(q.y,q.z)));
}
float diam(vec3 p,float s){
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.57735027;
}
//from Iq
float checkersTextureGradBox( in vec2 p, in vec2 ddx, in vec2 ddy )
{
    vec2 w = max(abs(ddx), abs(ddy)) + 0.01;  
    vec2 i = 2.0*(abs(fract((p-0.5*w)/2.0)-0.5)-abs(fract((p+0.5*w)/2.0)-0.5))/w;
    return 0.5 - 0.5*i.x*i.y;                  
}

mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
vec2 sdf(vec3 p){
   vec3 op = p;
   vec2 h;
   h.x = length(p)-1.;
   h.y = 1.;
  
  p.xz*=rot(.7885+time*.125);
  p.xz = abs(p.xz)-2.;
  p+=vec3(0.,.25,0.);
  p.xz *=rot(.785);
  p.xy *=rot(.785+time);
  vec2 t;
  t.x = mix(box(p,vec3(.7)),diam(p,.7),(sin(time*.66)*.5+.5)*1.2)*.7; // Very nice result mixing box and diam
  t.y = 2.;
  h = t.x < h.x ? t:h;
  
  t.x = dot(op+1.,vec3(0.,1.,0.));
  t.y = 3.;
 
  h = t.x < h.x ? t:h;
   return h;
}

#define q(s) s*sdf(p+s).x
vec2 nv=vec2(-.0001,.0001);
vec3 norm(vec3 p){return normalize(q(nv.xyy)+q(nv.yxy)+q(nv.yyx)+q(nv.xxx));}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    
 vec3 col=vec3(.1);
  vec3 ro=vec3(.0,.0,-5.),rd=normalize(vec3(uv,1.)),rp=ro;
  vec3 light=vec3(1.,2.,-3.);
  
  bool inside = false;
  vec3 refAcc = vec3(.0);
  for(float i=0.;i<=69.;i++){ // Difference from Art of Code : One big march
    
      vec2 d = sdf(rp); // Usual things

      d.x = abs(d.x); // So, when you march "inside",  sdf is negative (the S of sdf)
      //On tutorial there is a "side" that * by -1 so that the ray always march "ahead" 
      // So far, never have to use negative distance per say, so doing an abs to 
      // always have positive distance.
            //EDIT : Looks like can  create some artifact, bref, beware, adapt improvise, overcome

      rp+=rd*d.x; 
      if(d.x <=0.001){ //  If we hit a surface
          
        if(d.y == 1.){ // The boring sphere
          vec3 n = norm(rp);
           col = vec3(1.)*dot(normalize(light-rp),n);
           break;
        } else if (d.y == 3.){ // The Checker floor
             vec3 n = norm(rp);
            vec2 ddx_uvw = dFdx( rp.xz ); 
            vec2 ddy_uvw = dFdy( rp.xz ); 
           col = vec3(1.)*dot(normalize(light-rp),n)*checkersTextureGradBox(rp.xz,ddx_uvw,ddy_uvw);
           break;
        } else if(d.y==2.) { // the Refractive (?) surface
              
              float IOR = 1.45;
            if(!inside){ // Need to track if it's inside or outside
              refAcc += vec3(-10.2,.0,.0); // Add some "tint" 
              vec3 n = norm(rp);
              rd = refract(rd,n,1.0/IOR); // Less dense to more dense => 1./IOR
              rp-=n*.001*5.; // The almighty offset du cul, but here we need to go "inside" so -n
              inside = true;
            } else if (inside) {
            i/=2.;
                refAcc += vec3(.1,.2,.3); // Add some "tint" 
     
               vec3 n = -norm(rp); // norm will give always the norm that "get out", so whe need to negate to have the norm "inside"
        
               vec3 _rd = refract(rd,n,IOR); // More dense to les dense => IOR  . Headache when multiple refract materials :D
          
               if(dot(_rd,_rd)==0.){ // Total Internal Reflection
                    _rd = reflect(rd,n);
               }
               rd=_rd;
                rp-=n*.001*5.; // Another offset to get out.
              }
        }
       }  
        
  }   
  col +=refAcc;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
