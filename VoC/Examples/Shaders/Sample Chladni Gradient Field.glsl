#version 420

// original https://www.shadertoy.com/view/NlXGz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define HASHSCALE1 443.8975

#define KALEIDOSCOPE_SPEED_X    4.0
#define KALEIDOSCOPE_SPEED_Y  -10.0
#define KALEIDOSCOPE_SPLITS     8.0

#define PI 3.14159265359

//reference：https://www.shadertoy.com/view/XdtBWH
vec2 kaleidoscope(vec2 uv, vec2 offset, float splits)
{
    // XY coord to angle
    float angle = atan(uv.y, uv.x);
    // Normalize angle (0 - 1)
    angle = ((angle / PI) + 1.0) * 0.5;
    // Rotate by 90°
    angle = angle + 0.25;
    // Split angle 
    angle = mod(angle, 1.0 / splits) * splits;
    
    // Warp angle
#ifndef LINEAR
    float a = (2.0*angle - 1.0);
    angle = -a*a + 1.0;
    
    //angle = -pow(a, 0.4) + 1.0;
#else
    angle = -abs(2.0*angle - 1.0) + 1.0;
#endif
    
    angle = angle*0.1;
    
    // y is just dist from center
    float y = length(uv);
    //y = (y*30.0);
    
#ifdef FIX_X
    angle = angle * (y*3.0);
#endif
    
    return vec2(angle, y) + offset;
}
//repeat the position in 'pos' every 'q' degree in polar space
vec2 fan(in vec2 pos, in float q) 
{
    pos-= vec2(0.5,0.5);
    pos.x*=resolution.x/resolution.y;
    //q = q / 180. * 3.14159265;
    //float ang = atan(pos.x, pos.y),
    //len = length(pos.xy );
    //ang = mod(ang + q/2., q) - q/2.;
    //pos.xy = len * vec2(sin(ang), cos(ang));
    return pos;
}

float hash11(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float lerp(float a, float b, float t)
{
    return a + t * (b - a);
}

float noise(float p)
{
    float i = floor(p);
    float f = fract(p);
    
    float t = f * f * (3.0 - 2.0 * f);
    
    return lerp(f * hash11(i), (f - 1.0) * hash11(i + 1.0), t);
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;   
    float signuvx = -sign(uv.x - 0.5);
    float signuvy = sign(uv.y - 0.5);
    ////////////////////////////////////////
    

    uv = fan(uv,45.);
    vec2 UV = uv;
    
    vec2 A = vec2(sin(1.) * 4. * 0.005, 
                  sin(1.) * -10. * 0.005);
    uv = kaleidoscope(uv, A, 8.);//8份对称

    uv = abs(uv * 2. - 1.);
    uv.x *= resolution.x/resolution.y;

    float m = 3. + sin(time*0.2*noise(time*0.03))*2.;
    float n = 4. + sin(time*0.3*noise(time*0.1))*3.;
    float L = 1.;
    float value = cos(PI*n*uv.x/L)*cos(PI*m*uv.y/L)-cos(PI*m*uv.x/L)*cos(PI*n*uv.y/L);
    value = (value + 1.)*0.5;
    float finalValue = 10000.;
    float stepx = 1.0 / resolution.x;
    float stepy = 1.0 / resolution.y;
    float directionx = 0.;
    float directiony = 0.;
    //for (float ny = -1.; ny <= 1.; ny++) {
    //    for (float nx = -1.; nx <= 1.; nx++) {
    //        if (nx == 0. && ny == 0.) {
    //            continue;  // ourselves!
    //       }
    //        float tempValue = cos(PI*n*(uv.x+ nx * stepx)/L)*cos(PI*m*(uv.y+ ny * stepy)/L)-cos(PI*m*(uv.x+ nx * stepx)/L)*cos(PI*n*(uv.y+ ny * stepy)/L); 
    //       if (tempValue < finalValue){
     //           finalValue = tempValue;
                
      //          if(abs(nx)>abs(ny)){
     //               nx = sign(nx)*ny;
     //               ny = sign(ny)*nx;
      //          }
     //           directionx = (nx * signuvx +1.)*0.5 ;
     //           directiony = (ny * signuvy +1.)*0.5 ;
      //      }
      //  }
    //}
    
    //float a = (atan(UV.x, UV.y)+PI)/PI*0.5;
    float a = atan(UV.x, UV.y);
    
    for(float angle = 0.;angle < 2.*PI; angle+=PI*0.125*0.5){//对于所有的方向，计算出当前粒子所在位置对应的运动方向
        float nx = cos(angle);
        float ny = sin(angle);
        
         float tempValue = cos(PI*n*(uv.x + nx * stepx)/L)*cos(PI*m*(uv.y + ny * stepy)/L)-cos(PI*m*(uv.x+ nx * stepx)/L)*cos(PI*n*(uv.y+ ny * stepy)/L); 
            if (tempValue < finalValue){
                finalValue = tempValue;
                
                if(a>=0.*PI&&a<0.25*PI){
                    directionx = (nx+1.)*0.5 ;
                    directiony = (ny+1.)*0.5 ;

                }
                else if(a>=0.25*PI&&a<0.5*PI){
                    directionx = (ny+1.)*0.5 ;
                    directiony = (nx+1.)*0.5 ;

                }
                else if(a>=0.5*PI&&a<0.75*PI){
                    directionx = (ny+1.)*0.5 ;
                    directiony = (-nx+1.)*0.5 ;
                }
                else if(a>=0.75*PI&&a<1.*PI){
                    directionx = (nx+1.)*0.5 ;
                    directiony = (-ny+1.)*0.5 ;
                }
                else if(a>=-1.*PI&&a<-0.75*PI){
                    directionx = (-nx+1.)*0.5 ;
                    directiony = (-ny+1.)*0.5 ;
                }else if(a>=-0.75*PI&&a<-0.5*PI){
                    directionx = (-ny+1.)*0.5 ;
                    directiony = (-nx+1.)*0.5 ;
                }else if(a>=-0.5*PI&&a<-0.25*PI){
                    directionx = (-ny+1.)*0.5 ;
                    directiony = (nx+1.)*0.5 ;
                }else if(a>=-0.25*PI&&a<0.*PI){
                    directionx = (-nx+1.)*0.5 ;
                   directiony = (ny+1.)*0.5 ;
                }

            }    
    }
    //glFragColor = vec4(uv.x*0.6,0.0,0.0, 1.0);
    //glFragColor = vec4(UV.x,UV.y,0.0, 1.0);
    //glFragColor = vec4(directionx,directiony,0.0, 1.0);
    glFragColor = vec4(directionx,directiony,value, 1.0);
    //glFragColor = vec4(value,value,value, 1.0);
}
