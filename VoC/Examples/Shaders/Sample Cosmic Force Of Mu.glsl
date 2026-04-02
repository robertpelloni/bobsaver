#version 420

// original https://www.shadertoy.com/view/MtKBRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718
#define time time
#define resolution resolution.xy
#define size 0.544726
#define lineSize 0.174972
#define blur 0.227794
#define grid 4.3651814
#define grid2 4.1270218
#define morph 2.30923
#define delayAmount 0.044175148
#define speed 0.466905

float impulse( float k, float x )
{
    float h = k*x;
    return h*exp(1.0-h);
}

float plot(float dis){
   float pct = smoothstep(dis,dis+blur,0.5)-smoothstep(lineSize+dis,lineSize+dis+blur,0.5);     
  return   pct ;
}

vec3 wooper(vec2 st, float timeCheck){
    
    vec3 color = vec3(0.0);
    vec2 pos = vec2(0.5)-abs(st);

    float r = length(pos)*2.0;
    float a = atan(pos.y,pos.x);
    
    float gridSine = 5.+ (grid2*sin(timeCheck/5. * PI));
    
    r = fract(impulse(r,gridSine)*grid);
    
    float morphSine = 0.2 + ( 1.+sin(timeCheck/3. * PI) /2.)*morph;
    float morphSine2 = 0.2 + ( 1.+sin(timeCheck/5. * PI) /2.)*morph;
    float morphSine3 = 0.2 + ( 1.+sin(timeCheck/9. * PI) /2.)*morph;
    
    float f = ( size*cos(a*6. + timeCheck/3.) + size*cos(a*2. + timeCheck/2.))/2.;
    float p = plot(1.-smoothstep(f,f+0.9,r*morphSine));
    float f2 = ( size*cos(a*4. + timeCheck/3.) + size*cos(a*3. + timeCheck*7.))/2.;
    float p2 = plot(1.-smoothstep(f2,f2+0.9,r*morphSine2));
    float f3 = ( size*cos(a*7. + timeCheck/30.) + size*cos(a*3. + timeCheck*7.))/2.;
    float p3 = plot(1.-smoothstep(f3,f3+0.9,r*morphSine3));
    
    color.r = p;
    color.g = p2 *st.x;
    color.b = p3;
 
   return(color);
}

vec3 powerParticle(vec2 st){
  
    st.y += ((st.x*0.05)*sin(time/10.*PI)+(st.x*0.1)*sin(time/12.*PI))/2.;
    st.x += ((st.y*0.05)*sin(time/10.*PI) + (st.y*0.1)*sin(time/12.*PI))/2.;
    
    vec2 pos = vec2(0.25+0.25*sin(time))-abs(st);

    float r = length(pos);
    float d = distance(st,vec2(0.5))* (sin(time/8.));
    d = distance(vec2(.5),st);
   vec3 colorNew = vec3(0);
   
   float delay = delayAmount;
   float timerChecker = time * speed ;
    for(int i=0;i<10;i++) {
     
      vec3 colorCheck = wooper(st, timerChecker+ float(i)*delay)* (1.-(float(i)/10.0));
      colorNew+= colorCheck ;
    }
    
    return(colorNew);
}

vec3 rgb2hsb( in vec3 c ){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz),
                 vec4(c.gb, K.xy),
                 step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r),
                 vec4(c.r, p.yzx),
                 step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
                d / (q.x + e),
                q.x);
}

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void main(void) {
    vec2 res = vec2(0);
    res.x = resolution.x*0.5625;
    res.y = resolution.y;
    vec2 st = gl_FragCoord.xy/res;
    st.x -= 0.35;
    vec3 powerColor = powerParticle(st);
    vec3 hue = rgb2hsb(powerColor);
    hue.x = mod(time/10.,1.);
    hue.y = 0.5;
    float d = 1.-distance(vec2(.5),st)*2.;
       
    glFragColor = vec4( (hsb2rgb(hue)*d )+(powerColor*d*0.5),1.0);
     
}
