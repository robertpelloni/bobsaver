#version 420

// original https://www.shadertoy.com/view/3lySWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 Rot (float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
    
}

    float box (vec3 p, vec3 s){
                return length (max(abs(p) - s, 0.0));
                }

    float sphere (vec4 dim, vec3 p){
            float retValue = length(p - dim.xyz)-dim.w;
            return retValue;
                }

    //Raymarhing for the dust see my sheets or Art of Code
       vec2 GetDist(vec3 p){
            vec2 retValue;
            //sphere         
           float dSphere = sphere(vec4(1.0,3.5,5.0,1.5),p);
           float dPlane = dot(vec3(p.x,p.y-4.4,p.z), normalize(vec3 (0.0,1.0,0.0)));//the vec 3 is the normal of the plane
                                     //  if(dSphere< 0.0 && dSphere >-0.2) dSphere = abs(dSphere);//makes it hollow ie removes the negative number, if statement makes a sphere within
           dSphere = abs(dSphere);// hollows it out the goblet so the fluid sphere shows        
           float d = max(dSphere, dPlane) - 0.01;//max gives intersection of a plane, the number: thickness
            
           //fluid levels
           float wave =sin(time*2.0)* sin(15.0*p.x+time*2.0)*0.08;//fluid moves
           float fSphere = sphere(vec4(1.0,3.5,5.0,1.4),p);
           
                      //1 vec3 pT= p;//trying to get fluid to rotate too not working
                       //1pT.xz *=Rot(time*0.5);
                      //1 float FPlane = dot(vec3(pT.x ,p.y-4.1-wave,pT.z), normalize(vec3 (0.0,1.0,0.0)));
           float FPlane = dot(vec3(p.x ,p.y-4.1-wave,p.z), normalize(vec3 (0.0,1.0,0.0)));        
           float dF = max(fSphere, FPlane) - 0.01;
           
           d = min (d, dF);//blend them
                      
            //box
            float bPlane = p.y;// - sin(p.x)/10.0;// plane for the ground then
            vec3 bp = p-vec3(1.0  , 1.0  , 5.0  );//box position
               bp.xz *= Rot(time*0.5);//rotates it
            float scale = mix (0.8,4.0, smoothstep(-1.0, 0.5, bp.y));//gives the tapered column
            bp.xz *= scale;
            float db = box( bp , vec3(1.0));
            float boxpos = min( db, bPlane)/scale*0.3;// the 0.3 sharpens and reduces artifact
           
               if (db < bPlane || dSphere < bPlane){retValue.y = 6.0;// sets the object colour with the colour multiplyier 
                          }else retValue.y = 1.0;//set an absoute value for an if statement
           if (fSphere<0.0) {
                           retValue.y +=.9;//this fraction is liberated to create a red colour of tyhe fouid
                                             //so if negative ie inside then fluid sphere is made red
                    //    vec2 ref = GetLight(p.xy);    
                            }
           
            retValue.x = min(d, boxpos);                    
            return retValue;
        }
        vec2 RayMarch(vec3 ro, vec3 rd){
            float dO = 0.0;
            vec2 retVal;
            for(int i = 0; i < 100; i++){
                vec3 p = ro + dO * rd;
                retVal = GetDist(p);
               
                   float dS = retVal.x;
                dO += dS;
                if( dS < 0.01 || dO > 100.0){
                    break;
                    }
              }
              retVal.x = dO;
            return retVal;           
       }

        vec3 GetNormal (vec3 p){
            vec2 e = vec2(0.01, 0.0);
            vec2 retVal = GetDist(p);
              float d = retVal.x;
          
            vec3 n = d - vec3(GetDist(p-e.xyy).x,GetDist(p-e.yxy).x, GetDist(p-e.yyx).x);           
            n = normalize(n);
            return n;           
       }
        vec2 GetLight(vec3 p){
             vec3 lightPos = vec3( 5.0, 8.0, 4.0);

            lightPos.xz += vec2(sin(time), cos(time));
            vec3 light = normalize(lightPos - p);
            vec3 n = GetNormal(p);           
            vec2 dif = vec2(clamp(dot(n,light), 0.0, 1.0), 0.0);// so no negative numbers, last one just a value
            //for the shadow
            vec2 retVal  = RayMarch(p + n * 0.01 * 3.0, light);//this 3.0 is a work around
            float d = retVal.x;
            if (d < length (lightPos - p )) dif.x *= 0.1;                                                    
            dif.y = retVal.y;
            return dif;
        }
     
vec2 Rain(vec2 uv, float t){//this calculates the offset
    //uv*=2.;//trial and error these 2
    t*= 7.;
    vec2 a = vec2(3., 1.);//aspect ratio chganges dot roundness
    
    vec2 st = uv*a;
    vec2 id = floor(st);
    st.y += t* 0.22;                //this moves the box down
    float noise = fract(sin(id.x*716.37)*769.46);
    st.y += noise;//makes boxes different levels pseudo rand
    uv.y +=noise;
    id = floor(st);//need to reset
    st =fract(st)- 0.5;            //this gives the initial boxes, corners of which -0.5 to 0.5
    
     
    t+=fract(sin(id.x*76.37+id.y*1453.7)*769.46)*6.283;//varies timing of the drops falling
    
    float y = -sin(t+sin(t+sin(t)*0.5))*.4;    //positions dot in the box gives the movement
    vec2 p1 = vec2(0.0, y);
    
    vec2 offset1 = (st-p1)/a;                //this relates to where the UV is in relation to the droplet
    float d = length(offset1);                //this puts the dot in the box
    float m1 = smoothstep( 0.07, 0.0, d);        //mask 1 draws the dot
    
    vec2 offset2 = fract(uv*a.x * vec2(1.0,2.0))-0.5/vec2(1.,2.);
    d=length(offset2);//draws the trailing dots
    
    float m2 = smoothstep(.3*(0.5-st.y), 0.0, d)* smoothstep(-.1,0.1, st.y-p1.y);//shape of the trailing drops
   // if(st.x>0.46||st.y>0.49) m1 = 1.;
    
    return vec2(m1*offset1*20.+m2*offset2*10.);
               
}

void main(void)
{
            vec3 RGB = vec3(0.1, 0.1, 0.1);
            vec2 uv = (gl_FragCoord.xy/resolution.xy)*2.0-1.0;   
            vec3 mp = vec3(0.0);//(mouse*resolution.xy.xyz/resolution.xyz)*2.-1.;         
            vec3 col = vec3(0.5);
               float t = time*0.5;
    
            vec3 ro = vec3(mp.x -=0.0 , mp.y += 5.0 ,-2.0  );
   // uv.x += sin(uv.y*50.0)*0.1;
            vec2 RainDist = Rain(uv*5., t);
            RainDist += Rain(uv*7., t);
            uv-=RainDist*0.5;
    
            uv.x += sin(uv.y*90.)*0.0051;
            uv.y += sin(uv.x*170.)*0.001;
    
            vec3 rd = normalize(vec3(uv.x,uv.y,1.0));
            vec2 retVal = RayMarch(ro,rd);
            float d = retVal.x;
           
            vec3 p= ro+rd*d;
    
            vec2 diff = GetLight(p);
            
            diff/=2.0;// brightness factor
            float grad = p.y /28.0;//number trial and error
            if (retVal.y == 1.0){
                if (p.y > 0.1){RGB = vec3( 0.2 * grad, 0.3 * grad, 0.8* grad);//sky
                }else RGB = vec3( 0.2, 0.5, 0.1);//ground
            }
            float fluidCol = fract(retVal.y);//takes the fractionaql component to make it red
            fluidCol *=10.0;
                                     
            col = vec3(diff.x + RGB.r*fluidCol, diff.x + RGB.g, diff.x + RGB.b * retVal.y);
               
        //    col = vec3(RainDist, 0.0);//the r g channels
    
            glFragColor = vec4(col, 0.1);
}
