#version 420

// original https://www.shadertoy.com/view/MlyBR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Circle(vec2 uv, float radius, vec2 offset, float blur)
{  
   float distance = length(uv-offset);
   return smoothstep(radius, radius - blur, distance);
}

vec2 getUV()
{
   vec2 uv = gl_FragCoord.xy / resolution.xy;
   uv -= .5;
   uv.x *= resolution.x / resolution.y;
   return uv;
}

void main(void)
{
   vec3 red = vec3(1.,0.,0.);
   vec3 white = vec3(1.);
   vec3 black = vec3(0);
   vec3 grey = vec3(.65);
   vec3 darkred = vec3(.9,0.,0.);
   vec3 pink = vec3(1.,.25,.5);
   vec3 turqoise = vec3(.3,1.,1.);
   vec3 yellow = vec3(1.,1.,0);
  
   vec2 uv = getUV();
    
   float eyeball = Circle(uv, .5, cos (time) * vec2(.05), 0.2);
   float iris = Circle(uv, .3, cos(time) * vec2(.12), 0.05);
   float pupil = Circle(uv, .1, cos(time) * vec2(.15), 0.01);
   
   float shadeE = Circle(uv, .5, vec2(0), 0.01);
    
   float shadeI = Circle(uv, .3, cos(time) * vec2(.1), 0.01);
    
   float reflex = Circle(uv, .2, cos(time) * vec2(.12) + vec2(-.1,.1), 0.3);
   float reflex2 = Circle(uv, .06, cos(time) * vec2(.12) + vec2(.1,-.1), 0.08);
    
   float base1 = Circle(uv, .7, vec2(0), 0.01);
   float base2 = Circle(uv, .9, vec2(0), 0.01);
   float base3 = Circle(uv, 1.1, vec2(0), 0.01);
    
   float baseshadow = Circle(uv, .55, vec2(0.), 0.1);
   
   pupil = pupil - reflex - reflex2;
   iris = iris - pupil - reflex - reflex2;
   shadeI = shadeI - iris - reflex - reflex2;
   eyeball = eyeball - shadeI - iris - pupil - reflex - reflex2; 
   shadeE = shadeE - eyeball - shadeI - iris - pupil - reflex - reflex2;
    
   float eye = eyeball + shadeE + iris + shadeI + pupil + reflex + reflex2;  
   
   baseshadow = baseshadow - eye;
   base1 = base1 - baseshadow - eye;
   base2 = base2 - base1 - baseshadow - eye;
   base3 = base3 - base2 - base1 - baseshadow - eye;
       
   vec3 shadeEC = shadeE * grey;
   vec3 shadeIC = shadeI * darkred;
   vec3 eyeballC = eyeball * white;
   vec3 irisC = iris * red;
   vec3 pupilC = pupil * black;
   vec3 reflexC = reflex * white;
    
   vec3 base1C = base1 * pink;
   vec3 base2C = base2 * turqoise;
   vec3 base3C = base3 * yellow;
    
   vec3 baseshadowC = baseshadow * black;
     
   vec3 color = baseshadowC + base1C + base2C + base3C + eyeballC + irisC + pupilC + reflexC + shadeEC + shadeIC;
    
   glFragColor = vec4(color, 1.);  
}
