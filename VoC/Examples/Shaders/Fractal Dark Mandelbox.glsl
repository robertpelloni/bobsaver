#version 420

// original https://www.shadertoy.com/view/tsBGWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERS 7

float SCALE=0.0;
float MR2=0.0;

float mandelbox(vec3 position){
  vec4 scalevec = vec4(SCALE, SCALE, SCALE, abs(SCALE)) / MR2;
  float C1 = abs(SCALE-1.0), C2 = pow(abs(SCALE), float(1-ITERS));
  vec4 p = vec4(position.xyz, 1.0), p0 = vec4(position.xyz, 1.0);  // p.w is knighty's DEfactor
  for (int i=0; i<ITERS; i++) {
    p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;  // box fold: min3, max3, mad3
    float r2 = dot(p.xyz, p.xyz);  // dp3
    p.xyzw *= clamp(max(MR2/r2, MR2), 0.0, 1.0);  // sphere fold: div1, max1.sat, mul4
    p.xyzw = p*scalevec + p0;  // mad4
  }
  return (length(p.xyz) - C1) / p.w - C2;
}

float color(vec3 p){
    vec3 op = p;
    for (int i=0; i<ITERS; i++) {
        p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;  // box fold: min3, max3, mad3
        float r2 = dot(p.xyz, p.xyz);  // dp3
        p.xyz *= clamp(max(MR2/r2, MR2), 0.0, 1.0);  // sphere fold: div1, max1.sat, mul4
        p.xyz = p*SCALE/MR2 + op;  // mad4
    }
      return length(p);
}

float trace(vec3 o,vec3 d){
    float v=0.0;
    for(int i=0;i<64;i++){
        vec3 p=o+d*v;
        float mv=mandelbox(p);        
        if(mv<0.00001){
            return v;
        }
        v+=mv *1.0;
    }
    return 0.;
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

    
void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.xy)*2.-1.;
    uv.x *= resolution.x/resolution.y;
    uv *= 6.0;
   //SCALE = 2.5 + mouse*resolution.xy.x * 2.0;
   // MR2 = mouse*resolution.xy.x * mouse*resolution.xy.x;
    //SCALE = 2.9 + sin(time*10.0)*.0;
    SCALE = 2.5;
    float mr = 0.5;
    MR2 = mr * mr;
    
      
    vec3 lookingTo = vec3(0.,0.,0.);
    float it = time / 5.;
    vec3 viewer = vec3(
        sin(time*.1) * 6.0,
        cos(time*.17) * 5.0,
        cos(time*.1) * 7.0
    );
    
    vec3 forward = normalize(lookingTo-viewer);
    vec3 rigth = cross(vec3(0.0,1.0,0.0),forward);
    vec3 up = cross(forward,rigth);
    
    vec3 direction = normalize(forward * 5.0 + rigth * uv.x + up * uv.y);
    
    float dist = trace(viewer,direction);
    vec3 col=vec3(0.0);
     vec3 p = viewer + direction * dist;
    
    
    if(dist!=0.) {
        
         float c = color(p);
        
            col = pal(c/50.0, 
                   vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20)
                  //vec3(0.8,0.5,0.4),vec3(0.2,0.4,0.2),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25)
                   //vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25)
                  );

        //col = vec3(1.0);
    };

    
   
   
    float fog = 1.0 / (1.0 + (dist));
    glFragColor.rgb = vec3(col * fog);
}
