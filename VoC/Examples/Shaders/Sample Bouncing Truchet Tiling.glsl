#version 420

// original https://www.shadertoy.com/view/NdV3Wh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Hash221(vec2 p)
{
  p = fract(p*vec2(234.34,456.23));
  p+= dot(p,p+34.32);
  return fract(p.x+p.y);

}

void main(void)
{

        //Control Variables
        float tiling = cos(time/2.)*20.+20.;
        float t = time;
        float width = .1;

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    //Rotation Variables
    float Angle = (3.141592653589*t)/10.;
    float A = cos(Angle);
    float S = sin(Angle);
    
    //Rotate UV
  uv*=mat2(A,-S,S,A);
  
  //Scale Uv by Tiling
    vec2 bv = uv*tiling;
    
    //Make Grid
    vec2 gv = fract(bv)-.5;
    
    //Set ids
    vec2 id = floor(bv);
    
    //Random Flipping
    float n = Hash221(id);
    if(n<sin(t/2.)*.5+.5)gv.x*=-1.;
    
    //Color masks
    float c = length(uv);
    float c2 = length(gv);
    
    //Get Distances for lines
    float d = abs(abs(gv.x+gv.y)-.5);
    float d2 = length(gv-sign(gv.x+gv.y+0.001)*.5)-.5;
    
    //SmoothLines
    float s = smoothstep(.01,-.01-1.5/resolution.y,abs(d)-width); // Change d to d2 for Circular lines
   
    // visualize
    vec3 col = vec3(s);
    //if(gv.x >.48||gv.y>.48) col += 1.; //Draw Outline of each grid square
    col.r *= sin(c-t); // Animated red Channel
    col.g *= cos(c2+t)/2.; //Animated green channel
    col.rgb -= c/1.; // Create Vignette
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
