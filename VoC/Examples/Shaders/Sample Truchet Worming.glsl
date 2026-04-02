#version 420

// original https://www.shadertoy.com/view/4ljcRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Worming by julien Vergnaud @duvengar-2017
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
    
    p              -= .5; 
    float t         = .12; 
    float t2        = .05;    
    float line      = abs(length(p ) - .5) - t *1.5 ;
    float line_str  = abs(length(p ) - .5) - t2 * .3;
    float line_out  = max(line, -line -.01);
    float line_glow = abs(length(p ) - .5) - t2 * 2.;
      
           //  Adjusting the arcs clarity (I don't know how to call that)
    
    line     = 1. - smoothstep(.01,.1, sqrt(line));
    line_str = 1. - smoothstep(.01,.3, sqrt(line_str));
    line_glow = 1. - smoothstep(.01,.5, sqrt(line_glow));
  
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
     
    const float num = 16.;                       // partitions number
    float ang = atan(pos.y, pos.x);              // Pixel angle.               
    float ctr = floor(ang / TWO_PI * num ) + .5; // the cell center.

    pos  = rot(ctr  *(PI*2.) / num) *pos;        // Converting to polar coordinates
      
    pos.x -= .5;                                 // p.x = radius, p.y = angle.
                                                 // Translate coordinates
    
            //  render the objects in each slices
      
              
    float ring2 = smoothstep(0.0, .01, df_circle(pos, .165)); 
    
        
    
    ///////////////////////////////////////////////////////////////////////////////
    
   
    
    // V  //   Coloring
    
    float tex = .7 * sin(2. * cos(3. * uv.x + uv.y) - hash21(uv));     
 

  
    vec4 c = vec4(.0);
 
    c = .1*vec4(tex-.5);                                              // small amout off texture
    
    c += vec4(line -smoothstep(.0,.08,line_out*cos(sin(ang*45.))));   // base shape 
    
    c += mix(vec4(.2, .9, .8, 1.),c, .2);                             //base color
    c += mix(vec4(.2, .9, .8, 1.),c, .2); 
     
    c += .45*vec4(cos(sin(ang)));                                     // base lighting based on angle  
    c *= .45*vec4(cos(sin(ang))); //
    
    c *= mix(c,vec4(cos(sin(ang*5.)),cos(sin(ang*5.)),1.,1.),.5);     // more color based angle
                   
    c += line * vec4(cos(sin(ang*2.)), .0, 0., 0.);                   // angle*2 is red
    c *= 1.-ring2+(line_str*cos(sin(ang*10.)));
    c *= .5 + vec4(.2,.9,.7,.0);                                      // color balance
    
    c+= (smoothstep(-.1,.7,tex*line_out));                            // backgground texture
    c -= .4*mix(c,vec4(-.1*cos(sin(ang*3.)),.1,-.1*cos(sin(ang*3.)),1.),.5); 
     vec2 uu  = 1. - 2. * uv / resolution.xy;                        // vigneting
    float v  = 1. - smoothstep(.7, 1.4, length(uu*uu*uu)) * 2.;
    c *= vec4(v);   
    c = mix(c,vec4(.0,.0,.1,1.),.3);
    c += .4*vec4(smoothstep(.0,.9,line_glow*ring2));                  // a bit of glow
    c /= .7/pow(c,c);                                                 // lighten more

    glFragColor=c;

}
