#version 420

// original https://www.shadertoy.com/view/wsyXDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SkyColorTop         vec3(39,  98,  176) /255.
#define SkyColorButtom      vec3(140, 185, 245) /255.
#define MountainOneBCol     vec3(140, 95,  84 ) /255.
#define MountainOneSCol     vec3(189, 178, 149) /255.
#define MountainTwoBCol     vec3(150, 87,  60 ) /255.
#define MountainTwoSCol     vec3(209, 166, 119) /255.
#define MountainThreeBCol   vec3(158, 107, 55 ) /255.
#define MountainThreeSCol   vec3(214, 127, 64 ) /255.
#define MountainFourBCol    vec3(112, 37,  0  ) /255.
#define MountainFourSCol    vec3(227, 77,  27 ) /255.
#define PoltColorBase       vec3(112, 37,  0  ) /255.
#define PoltColorSecond     vec3(227, 77,  27 ) /255.
#define BushesBase          vec3(82,  56,  0  ) /255.
#define BushesSecond        vec3(130, 85,   0 ) /255.

#define std           uvCoordinate, col
#define mountainOne   MountainOneBCol,   MountainOneSCol,   0.5, 0.4,  0.2,  0.0085, 1.
#define mountainTwo   MountainTwoBCol,   MountainTwoSCol,   0.3, 0.3,  0.35, 0.02,   13.
#define mountainThree MountainThreeBCol, MountainThreeSCol, 0.2, 0.09, 0.25, 0.1,    7.
#define mountainFour  MountainFourBCol,  MountainFourSCol,  0.1, 0.1,  0.2,  0.3,    22.

// HELPERS -----------------------------------------------
float rand(float seed){
    return fract(sin(seed *512.)*42.1);
}

// =======================================================
// DRAWING -----------------------------------------------

float tWave(float x, float amplitude, float frequency){
      return abs((fract(x*frequency) *2.)-1.) * amplitude;   
}

void sky(in vec2 coord, inout vec3 color){
    color = mix(SkyColorButtom, SkyColorTop, coord.y);
}

void mountain(in vec2 coord, inout vec3 color,
              in vec3 col1, in vec3 col2, float beginingHeight, 
              float baseFrecuqncy, float baseAmplitude, float scrollSpeed, float seed ){
    
    
    coord.x += time*scrollSpeed;
    float f  = beginingHeight ;
    float d  = 0.  ;
    
    for(float i = 1.; i<10.; i++){
      
        f +=  tWave( coord.x + rand(i+seed),baseAmplitude / pow(1.95,i) ,baseFrecuqncy * pow(1.95,i));
        
    }
    
        for(float i = 1.; i<4.; i++){
          float t  = tWave( coord.x+ rand(i+seed),baseAmplitude / pow(1.95,i) ,baseFrecuqncy * pow(1.95,i));
              d +=  tWave(coord.x+ rand(i+seed)- coord.y*(t-0.5)*(4.+rand(i+seed)),baseAmplitude / pow(1.95,i) ,baseFrecuqncy * pow(1.95,i));
    }
    
          d    = smoothstep(-0.0015,0.0015, dFdx(d));
       
          f    = 1.-step(f , coord.y);
    
    vec3 cTemp = mix(col2,col1 , d);
         color = mix(color, cTemp, f);
}

void Pols(in vec2 coord, inout vec3 color){
    
    coord.x += time *1.8;
    float f  = smoothstep(0.015, 0.05, fract(coord.x*0.5));
    vec3  c  = mix(PoltColorBase, PoltColorSecond, smoothstep(0.2, 0.4, f));
       color = mix(c,  color, f);
    
}

void Bushes(in vec2 coord, inout vec3 color){
    
    coord.x += time *3.8;
    
     
    float baseAmplitude = 1.;
    float baseFrecuqncy = .1;
    
    float t = 0.;
    float stripes =0.;
       for(float i = 1.; i<8.; i++){
      
        float yC = tWave( coord.y + rand(i),baseAmplitude / pow(1.95,i) ,baseFrecuqncy * pow(1.95,i));
        t +=  tWave( coord.x +yC*10.+ rand(i),baseAmplitude / pow(1.95,i) ,baseFrecuqncy * pow(1.95,i));
        stripes +=tWave( coord.x *yC*10.+ rand(i),baseAmplitude / pow(1.95,i) ,baseFrecuqncy * pow(1.95,i));
    }
    
    float d = (fract(coord.x*1.)-0.5)/0.5;
    float f  = 1. -smoothstep(t, t+ 0.05, abs(d));
   
    float f1 = 1. -smoothstep(stripes, stripes+ 0.05, abs((fract(coord.x*1.)-0.5)/0.5));
    
          f  *= 1.-step(t-0.5, coord.y);
    vec3  c  = mix(BushesBase, BushesSecond, coord.y);
       color = mix(color,  c, mix(f, f*f1, step(0.,d)));
    
}

// =============================================================
// MAIN --------------------------------------------------------

void main(void)
{
    // ---------------------------------------------------------
    // ---COORDINATE SETUP
    
    vec2  uvCoordinate    =  gl_FragCoord.xy/resolution.xy;
    float aCorreection    =  resolution.x/resolution.y;
    
          uvCoordinate.x *=  aCorreection;
         
    // ---------------------------------------------------------

    vec3 col = vec3(0.,0.,0.);

    
    sky(std);
    mountain(std, mountainOne  );
    mountain(std, mountainTwo  );
    mountain(std, mountainThree);
    mountain(std, mountainFour );
    
    Pols(std);
    Bushes(std);
    
    //day night stuff
    //col = mix(PoltColorBase, col, vec3(sin(time*0.1),sin(time*0.1+0.12),sin(time*0.1+0.1)));
    // Output to screen
    glFragColor = vec4(col,1.0);
}
