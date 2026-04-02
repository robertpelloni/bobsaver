#version 420

// original https://www.shadertoy.com/view/lljczD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Round_trips by julien Vergnaud @duvengar-2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// ====================================================================

// Derived from Simple_animated_Truchet by @Shane
// [url]https://www.shadertoy.com/view/llfyWX[/url]

// Mouse control direction

#define PI     3.14159265359
#define TWO_PI (PI*2.)

// vec2 to float hash function taken from @Shane - Based on IQ's original.

float hash21(vec2 p){ return fract(sin(dot(p, vec2(141.213, 289.867)))*43758.5453); }

// Standard 2D rotation formula.

mat2 rot(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

//distance field chain ring

float df_c2(vec2 pos, float rad, float dir,float r, float off){
    
    

  
 float shp  = length(pos - vec2( r*dir * rad * off, .0)) -rad/3.;
  
    return   shp;
}

float df_c1(vec2 pos, float rad, float dir,float r, float off){
    
    

  
 float shp  = length(pos + vec2( r*dir * rad * off, .0)) -rad/3.;
  
    return   shp;
}

void main(void)
{
    
    vec2 uv=gl_FragCoord.xy;
    
    // I   //  Screen coordinates is formated to go from -1. to 1.
    
    vec2 p = -1.+ 2.* uv / resolution.xy;
    p.x *= resolution.x / resolution.y;
    
      
   
    // II  //  Moove & Rescale screen space
    
    p *= 1. + dot(p, p)*.05;        // fish eye
    p += vec2(.0, time/12.);       // moove along Y axis
    //p *= .7*floor(resolution.x/200.); // rescale space
 p*=3.;
    
     // III //  Make truchet lines
           //  store tile id & Divide screen into grid 
           //  & store direction in a checkerboard way.
    
    vec2 id = ceil(p);
    
    float dir = mod(id.x + id.y, 2.) * 2. -1.;  
    
    
    p = fract(p) - .5;  // or // p -= id + .5; 
        
           //  Truchet tiles orientation randomisation
    float r =  hash21(id) > .5 ? 1. : -1.;
    
    p.y *= r;
    
           //  Applying symetry on diagonal axis to avoid drawing two arcs
           //  Tricks form @shane
    
    p *= sign(p.x + p.y);
      
           //  Drawing the two arc's strokes directly with a tickness of t
           //  The tricks to draw a contour was taken from a @FabriceNeyret2 
           //  comment in this shader https://www.shadertoy.com/view/MtXyWX
    
    p             -= .5; 
   
  

  
           //  Adjusting the arcs clarity (I don't know how to call that)
    
    

  
    // IV  //  RENDER
    
           //  Animate flow
     
    vec2 pos  = p ;
    vec2 pos2 = p ;
    vec2 pp   = p ;  
                                   
    
    //if(mouse*resolution.xy.z > 0.){
    //    float m = smoothstep(.0,-1. + 2. * resolution.x, -1. + 2. * mouse*resolution.xy.x);
    //    m*= 20.;
    //    pos  *= rot(m *  dir);
    //    pos2 *= rot(m * -dir);
    //    pp *= rot(dir * r);        // magic tricks here*
    //
    //}else{
        pos  *= rot(time *  dir);
        pos2 *= rot(time * -dir);
        pp   *= rot(r * dir);      // magic tricks here
                                   // * use the random state r to flip again the sections
                                   // and get the inner / outer truchet together.
        

    //}

           //  Part into cells  & convert into polar coordinates
     
    const float num = 6.;                              // partitions number
    
    float ang  = atan(pos.y, pos.x);                   // Pixel angle.     
    float ang2 = atan(pp.y, pp.x);                     // offset angle WITHOUT flow
    float ang3 = atan(pos2.y, pos2.x);                 // pixel angle with opposite rotation 
   
    //float ctr  = floor(ang  / TWO_PI * num ) +.5  ;     // the cell centers.
    
    float ctr = round(ang / TWO_PI * num);
    
    
   // float ctr2 = floor(ang2 / TWO_PI * num ) + .5;     // 
    float ctr3 = round(ang3 / TWO_PI * num );
    
          pos  = rot(ctr  * TWO_PI / num) * pos;        // Converting to polar coordinates
       
          pos2 = rot(ctr3 *  TWO_PI / num) *pos2;       //
    
          pos.x  -= .5;                                // p.x = radius, p.y = angle.
          //pp.x   -= .5;
          pos2.x -= .5;                                // Translate coordinates
      
           //  render the objects
      
  
    
    float t = .094;                                    // thickness
    float rd = .115;                                   // offset radius on each side of 
                                                       // the original truchet line
    
    vec2 p1  = vec2(sin(ang2)* rd,cos(ang2) * -rd);    // Two mirored points
    vec2 p2  = vec2(sin(ang2)* -rd,cos(ang2) * rd);    // inner or outer around ang2 (main angle)
    
    float line1 = abs(length(p - p1) - .5) - t ;       // two mirored lines
          line1 = 1. - smoothstep(.01,.2, sqrt(line1));// abs() draw the contour
    
    float line2 = abs(length(p - p2) - .5) - t ;    
          line2 = 1. - smoothstep(.01,.2, sqrt(line2));

    float ball  = smoothstep(.01,.02, df_c1( pos , .14, dir,r, .7));             // 6 mirored balls per section
    float ball2 = smoothstep(.01,.02, df_c2( pos2, .14, dir,r, .7));             // pos and pos2 are 
                                                                                 // in reflected rotation
  
        
    // V   //   Coloring
    
    
    vec4 c= vec4(.1);
  
    c  = vec4(line2 *cos(sin(r * ang))      + line1 * cos(sin(r * ang3)));       // first two opposite gradient
    c *= vec4(line2 *cos(sin(r * ang * 2.)) + line1 * cos(sin(r * ang3 * 2.)));  // second two gradient  
    c *= .3 + line1;
    c -= .1 * sin(2. * cos(8. * uv.x + uv.y) - hash21(uv));                      // texture
    c -= ball-ball2;                                                             // balls
    
     vec2 uu  = 1. - 2. * uv / resolution.xy;                                   // vigneting
    float v  = 1. - smoothstep(.7, 1.4, length(uu*uu));
   
    c *= vec4(v); 
    c+= vec4(.0,.0,.1,1.);
 
    glFragColor=c;    
    
}
