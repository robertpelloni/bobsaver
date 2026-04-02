#version 420

// original https://www.shadertoy.com/view/tdlGRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592657

mat2 rot2D(float a){
   float c =cos(a);
   float s = sin(a);
   
   return mat2(c,s,-s,c); 
}

vec3 getColor(float v){
   float r = cos((v-0.78)*PI);
   float g = cos((v-0.52)*PI);
   float b = cos((v-0.20)*PI);
   
   return vec3(r,g,b);
}

vec2 hash2(vec2 uv){
   float drive = 1.0+time*0.2*PI; 
   float r = fract(sin(dot(uv,vec2(3.7345236,PI))*PI*128493.0)); 
   float r1 = fract(sin(dot(uv,vec2(r,PI))*PI*14327.0)); 
   
   return vec2(r,r1)*rot2D(drive);
}

float noise2D(vec2 uv){
   vec2 p = floor(uv);
   vec2 f = fract(uv);
   vec2 e = vec2(1,0);
   vec2 p00 = p;
   vec2 p10 = p+e;
   vec2 p11 = p+e.xx;
   vec2 p01 = p+e.yx;
   float v00 = dot(f-e.yy,hash2(p00));
   float v10 = dot(f-e.xy,hash2(p10));
   float v11 = dot(f-e.xx,hash2(p11));
   float v01 = dot(f-e.yx,hash2(p01));
    
   f = f*f*f*(f*(f*6.-15.)+10.); 
   
   return mix(mix(v00,v10,f.x),mix(v01,v11,f.x),f.y);
}

float fbm(vec2 uv){
    float freq = 0.2;
    float ampli = 3.0;
    float ret   = 0.5;
    for (int i=0;i<8;i++){
       ret+= noise2D(uv*freq)*ampli;
       //0.3425617
       uv +=vec2(ret,ret);
       //freq*=ret;
       freq*=2.0;
       ampli*=0.45;
    }
    return ret;
}
 

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy-vec2(0.5);
    float as =  resolution.x/resolution.y;
    uv.x*=as;

    // Time varying pixel color
    vec3 col = vec3(0);
    
    float a = atan(uv.y,uv.x);
    uv *= 2.;
    float v = fbm(uv*2.);
    col = getColor(v*0.45);
    col = smoothstep(0.,1.,col);
    col = pow(col,vec3(0.8));
    // Output to screen
    glFragColor = vec4(col,1.0);
}
