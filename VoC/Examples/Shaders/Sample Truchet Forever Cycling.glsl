#version 420

// original https://www.shadertoy.com/view/llSczD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Forever_Cycling by julien Vergnaud @duvengar-2017
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

// polynomial smooth min

float smin( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 * (b - a) / k, 0.0, 1.0 );
    return mix( b, a, h ) - k * h * (1.0 - h);
}

//distance field circle

float df_circle(vec2 pos, float rad){

    return (length(pos)-rad);  
}

//distance field chain ring

float df_chain(vec2 pos, float rad, float dir, float off){
    
    // Because the truchet cells are flipped out along the Y axis
    // We need to draw everthing in symetry using direction
    // and offset values as variables for the position.
    // The smin from iq method is used to unify two spheres smothly
    // making the chain block curved.
    
    float shp  = length(pos + vec2(0, dir * rad * off)) -rad; 
    
          shp  = smin(shp, (length(pos - vec2(0, dir * rad * off)) -rad ), .09);;
          shp  = max (shp,-(length(pos + vec2(0, dir * rad * off)) -rad/3.)); 
          shp  = max (shp,-(length(pos - vec2(0, dir * rad * off)) -rad/3.)); 

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
    p *= .7*floor(resolution.x/200.); // rescale space
 
    
     // III //  Make truchet lines
           //  store tile id & Divide screen into grid 
           //  & store direction in a checkerboard way.
    
    vec2 id = floor(p);
    
           // replacing Shane's float dir = sign(mod(id.x + id.y, 2.) - .5);
           // The sign() seems to be dispensable
    
    float dir = mod(id.x + id.y, 2.)-.5;  
    p = fract(p) - .5;  // or // p -= id + .5; 
        
           //  Truchet tiles orientation randomisation
    
    p.y *= hash21(id) > .5 ? 1. : -1.;
    
           //  Applying symetry on diagonal axis to avoid drawing two arcs
           //  Tricks form @shane
    
    p *= sign(p.x + p.y);
      
           //  Drawing the two arc's strokes directly with a tickness of t
           //  The tricks to draw a contour was taken from a @FabriceNeyret2 
           //  comment in this shader https://www.shadertoy.com/view/MtXyWX
    
    p             -= .5; 
    float t        = .12; 
    float t2       = .05;    
    float line     = abs(length(p ) - .5) - t * .5;
    float line_str = abs(length(p ) - .5) - t2 * .3;
    float line_out = max(line, -line -.008);
    float line_glo = max(line, -line -.8);;
      
           //  Adjusting the arcs clarity (I don't know how to call that)
    
    line     = 1. - smoothstep(.01,.1, sqrt(line));
    line_str = 1. - smoothstep(.01,.1, sqrt(line_str));
  
    // IV  //  RENDER CHAIN
    
            //  Animate flow
     
    vec2 pos = p ;
    
    //if(mouse*resolution.xy.z > 0.){
    //    float m = smoothstep(.0,-1. + 2. * resolution.x, -1. + 2. * mouse*resolution.xy.x);
    //    m*= 20.;
    //    pos *= rot(m*dir);
    //}else{
        pos *= rot(time*dir);
    //}

            //  Part into cells  & convert into polar coordinates
     
    const float num = 8.;                        // partitions number
    float ang = atan(pos.y, pos.x);              // Pixel angle.               
    float ctr = floor(ang / TWO_PI * num ) + .5; // the cell center.

    pos  = rot(ctr  *(PI*2.) / num) *pos;        // Converting to polar coordinates
      
    pos.x -= .5;                                 // p.x = radius, p.y = angle.
                                                 // Translate coordinates
    
            //  render the objects in each slices
      
    float ring  = df_chain(pos, .089, dir, 1.9);              
    float ring2 = smoothstep(0.0, .01, df_circle(pos, .165)); 
    
    float ring3 = smoothstep(0.0, .01, abs(ring));
          ring  = smoothstep(0.0, .01, ring);
    
    
    float base2 = 1. - smoothstep(.0,.01, 
                       min(line_glo, df_chain(pos, .089, dir, 1.9))); 
    
    
    
    
    ///////////////////////////////////////////////////////////////////////////////
    
   
    
    // V  //   Coloring
    
    float tex = .7 * sin(2. * cos(10. * uv.x + uv.y) - hash21(uv));     
                 
    float c2  = 1. - min(line_str, ring2);              // chain interstice
     
    float c1  = min(line_out, ring);                   // create Chain contour
          c1  = min(1. - c1, ring3); 
          c1  = min(c1, c2);
    
    vec4 c  = .4*vec4(max(.4*tex, base2 * cos(sin(ang))));   // base texture with radial gradient
                                                        // the cos(sin(angle) is used 
                                                        // todo the lighning
    
    c *= vec4(c1 * cos(sin(ang)));                      // draw chain contour 

    c /= .7+vec4(1., hash21(uv) * 2., 1., 1.);          // noisy color
    
    c += .7 * vec4(base2 * .35, base2 * .3, .1, 1.);   // a bit gold
    
   
    c += mix(vec4(.4, .7, .55, 1.), c, .6);              // a bit more blue
    
    c -= vec4( .3 * c1);                                // a bit darker
    
    vec2 uu  = 1. - 2. * uv / resolution.xy;           // vigneting
    float v  = 1. - smoothstep(.7, 1.9, length(uu)) * 2.;
    c *= vec4(v);                                       // black
    c /= .8 * vec4(v * .6, 1., .6, 1.);                 // red   

    c -=.6-c1*.7;                                       //adjust outline contrast
  
    c = sqrt(c)*.1+c;

    glFragColor=c;

}
