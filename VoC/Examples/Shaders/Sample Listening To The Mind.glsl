#version 420

// original https://www.shadertoy.com/view/Ws3yzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/////////////////////////////////////////////////////////////
////         ....  Listening to the mind...              ////
/////////////////////////////////////////////////////////////
// Brasil/Amazonas/Manaus
// Created by Rodrigo Cal (twitter: @rmmcal)🧙🧞
// - Started: 2020/10 - Published: 2020/10
// - https://www.shadertoy.com/view/Ws3yzS
/////////////////////////////////////////////////////////////
// -----------------------------------------------------------
//
//  Listening to the mind => 🎧🧠
//  
//    Pass: Mente&Ouvinte 
//  
//      ... @rmmcal 2020/20 
//
//  Inspiration/Wiki: 
//     => https://en.wikipedia.org/wiki/Gyroid
//  
// -----------------------------------------------------------
/////////////////////////////////////////////////////////////
//

float dist(vec3 p){
    p *= 1.;
    float d = 100.;

    float a = p.z*fract(time*.1)*0.01;
    d = 1.4-abs(sin(p.x)*cos(p.y)+sin(p.y)*cos(p.z)+sin(p.z)*cos(p.x))-cos(p.z*2.-fract(time)*3.1415926*2.)/120.;

    vec3 tv = p*21.+time*3.;
    vec3 ctv = cos(tv);
    d += .02*( smoothstep(-1.0,1.5, .5 - abs(ctv.x + ctv.y + ctv.z)) ) *abs(fract(time*1.)*2.-1.)*2.;

    //d -=  texture(iChannel3,vec2(sqrt(abs(p.z*.01)),0.)).r*.1;
  
    return d;
}

vec3 normal3d(vec3 p)
{
  vec3 eps = vec3(.001,0.0,0.0);
  vec3 nor;
  float ref;
  nor.x = dist(p+eps.xyy) - dist(p-eps.xyy);
  nor.y = dist(p+eps.yxy) - dist(p-eps.yxy);
  nor.z = dist(p+eps.yyx) - dist(p-eps.yyx);
  return -normalize(nor);
}

void main(void)
{
    float time2 = (time*.5);
    vec2 aspectRatio = vec2(1., resolution.y/resolution.x);
    vec2 uv = gl_FragCoord.xy/resolution.xy; 
    vec2 p = (uv-.5)*aspectRatio;

    vec3 cpos = vec3(0.0,0.0,-20.0);
    vec3 cdir = vec3(0.0,0.0,  0.0);
    
    cpos += vec3(time/3.,0.0,(cos(time*.08)*11.)) * clamp(pow(time*.2,8.),0.,1.);
    
    vec3 ray = vec3(sin(p.xy)*1.,.5);
   
    vec3 g;
    for (int i = 0; i < 250; i++)
    {
        float d = dist(cpos);
        cpos += ray*d;
        if (d < 0.01) break;
        if (d > 128.) break;
        g += vec3(1.,-0.3,.1)/(d*3000.);
    }
    vec3 n  = normal3d(cpos);
    vec3 an  = abs(n);
    
    vec3 col = vec3(1.,0.7,0.)*vec3((an.x+an.y+an.z)*.4);
    
    col +=  vec3(4.,0.,10.)*vec3( smoothstep(-.2,01.5, .4-abs(cpos.z-fract(time*0.1)*20.+20.)) );
   
    vec3 tv = cpos*21.+time*3.;
    vec3 ctv = cos(tv);
    
    col +=  vec3(0.,1.,1.)*vec3( smoothstep(-.0,5.5, 1.6-abs(cos(tv.y*.1)+cos(tv.x*.1)+cos(tv.z*.1)  )) );
    col +=  vec3(0.4,.5,0.)*vec3( smoothstep(-3.0,2.5, .5 - abs(ctv.x + ctv.y + ctv.z)) );
    col +=  vec3(1.,0.,01.)*vec3( smoothstep(-.0,1.5, .5 - abs(ctv.x + ctv.y + ctv.z)) );
    col *= n.z*.3+.7;
    col = mix( vec3(1.),col,smoothstep(-50.,40., -cpos.z));
 
    vec3 neon = g*abs(fract(time*.2)*2.-1.)*.5;
    col += neon;
    col = mix( col, vec3(1.5)+ g*2., length(p)*1.2-.1);
    
    col = mix(vec3(0.5*length(col)), col , cos(time*.5)*clamp(0.,1.,time*.01));
    col = mix(col,vec3(0.) ,   smoothstep(0.,1.,length(p)+1.-1.*clamp(0.,1.,time*.5)));
    
    glFragColor = vec4(col,1.0);
}
