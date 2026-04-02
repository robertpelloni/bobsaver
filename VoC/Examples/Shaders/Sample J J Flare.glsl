#version 420

// original https://www.shadertoy.com/view/wlBBWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Created by Jaromir Mulders
//www.jaromirmulders.nl

#define M_PI 3.14159265359

float hash21(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float noise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float flareLine(vec2 p, vec2 width){

  float sphere = length(p);
  sphere = smoothstep(width.x,0.,sphere);    
       
  vec2 s = vec2(0.5,1.);
    
  float line = abs(p.y+smoothstep(s.x,s.y,cos(p.x)*0.2));
  line+= abs(p.y-smoothstep(s.x,s.y,cos(p.x)*0.2));
   
  line = smoothstep(width.y,0.0,line);
  line*= sphere;  
    
  return line;
}

float sinSphere(vec2 p, float scale, float offset){

  float s = sin(length(p*scale)+offset);
    
  return smoothstep(0.98,0.7,s)-smoothstep(1.,0.6,s);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
    
    uv*=1.2;
    
    float sLen = length(uv);
    float n = hash21(uv);
    float n2 = noise(uv*15.+time*0.08);
    
    float l1 = flareLine(uv + vec2(0.,0.),
                         vec2(.9,0.03) + vec2(cos(time*0.265)) *vec2(0.11,0.01) );
    float l2 = flareLine(uv + vec2(-0.08,0.01),
                         vec2(.5,0.013) + vec2(cos(time*0.287)) *vec2(0.12,0.005));
    float l3 = flareLine(uv + vec2(0.09,-0.011),
                         vec2(.7,0.018) + vec2(cos(time*0.289)) *vec2(0.13,0.0023));
    
    float lCurve = cos(uv.x*M_PI*0.6)*0.2;
    float lUv = abs(uv.y+lCurve);
    lUv+= abs(uv.y -lCurve);
    
    float curveLine = length(lUv);
    curveLine = smoothstep(0.8,0.,curveLine);
    
    vec2 sUv = uv*1.5;
    float line = smoothstep(.15+n2*0.08,0.,abs(sUv.y));
    float s = length(sUv);
    float sphere = smoothstep(.8,-0.5,s);
    float lAnim = fract(hash21(vec2(time*0.1)));
    lAnim = max(0.9,lAnim);
    float wSphere = smoothstep(.1+lAnim*0.03,-0.02,s);
    float d = dot(abs(sUv.x*1.),abs(sUv.y*0.75));
    float star = smoothstep(.07,-0.1,d)*5.;
    float sSphere = line*star*sphere;
    sSphere = pow(sSphere,2.);
    
    float bulb = length(uv*1.9+n2*-0.015);
    bulb = bulb * smoothstep(1.,0.3,bulb);
    bulb = smoothstep(0.3,.5,bulb);
    
    vec2 rUv = uv;
    float emit = abs(sin(atan(rUv.y,rUv.x)*.7+.2));
    emit+= abs(sin(atan(rUv.y,-rUv.x)*0.8+.1));
    emit*=0.5;
    emit*=smoothstep(.9,0.,sLen) - bulb*0.3 ;
    emit = pow(emit,2.5);
    emit = (emit*mix(n,1.,0.97))*0.9;

    float rRep = 1.5;
    float rLen = length(uv*2.5);
    float angle = atan(rUv.x,rUv.y);
    float rAngle = sin(angle*rRep+n2*0.9+time*0.5);
    float rays = (abs(rAngle))*smoothstep(1.+n2*0.05,0.,rLen);
    rays*= clamp(.1/rLen,0.,1.);
    rays-=smoothstep(.8,0.,rLen)*2.;
    float aId = floor(angle*rRep);
    float rId = hash21(vec2(aId));
    rays = clamp(rays* abs(sin(angle*0.3+0.1))*0.3,0.,1.) ;
    
    float r1 = sinSphere(uv+n2*0.1,0.9,0.0);
    float r2 = sinSphere(uv+n2*-0.023,1.,0.0);
    float r3 = sinSphere(uv+n2*0.05,1.1,0.0);
    vec3 ripple = vec3(r1,r2,r3)*mix(sin(angle*0.7+time*0.23),1.,0.5);
    
    
    vec3 col = vec3(0.);

    col+=l1*vec3(0.1,0.1,.3);
    col+=smoothstep(0.3,1.,l1)*vec3(1.)*0.3;
    
    col+=l2*vec3(0.2,0.5,0.6);
    col+=smoothstep(0.3,1.,l2)*vec3(1.)*0.3;

    col+=l3*vec3(1.5,0.3,1.);
    col+=smoothstep(0.3,1.,l3)*vec3(1.)*0.3;
    
    col+=vec3(sSphere*1.5)*vec3(.8,.05,0.)*2.;
    col+=vec3(wSphere)*vec3(1.1);
    
    col+=ripple*0.075;
    
    col+=rays*vec3(.4,0.3,0.2)*100.;
    col+=mix(vec3(0.34,0.5,0.6),vec3(.9,0.05,0.1),emit)*emit;
    
    col = pow(col,vec3(0.4545));
    
    glFragColor = vec4(col,1.);
    //glFragColor = vec4(ripple,1.);
}
