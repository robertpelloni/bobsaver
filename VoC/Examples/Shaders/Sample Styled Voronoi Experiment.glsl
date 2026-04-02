#version 420

// original https://www.shadertoy.com/view/slyfzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2022-10-03 cac- Styled Voronoi Experiment
//
// inspired from simplified https://www.shadertoy.com/view/MtlyR8 (Voronoï with various metrics)
// + tilability, multiple seed per cell

//visuals are extra sensitive to large changes in these values
#define C 99.  // cell size
#define B  8.  // number of blob per cell. B=1 -> Poisson disk. Large or random B -> Poisson
#define R  .5  // jittering blob location. .5 = anywhere in the tile. could be < or >
#define dr 0.85  // blob radius fluctuates in [1-r,1+r]
// nice values are  between 0.65-> 1.99
#define N  5   // tested neighborhood. Make it odd > 3 if R is high , larger search needed due to larger and shifted blobs

#define srnd(p)  ( 2.* fract(43758.5453*sin( dot(p, vec2(12.9898, 78.233) )      ) ) - 1. )
#define srnd2(U) ( 2.* fract(4567.89* sin(4567.8*(U)* mat2(1,-13.17,377.1,-78.7) ) ) - 1. )

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    //https://www.shadertoy.com/view/ll2GD3
    return a + b*cos( 6.28318*(c*t+d) );
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;
	vec4 O = vec4(0.0);
	vec2 scr_uv = gl_FragCoord.xy / resolution.xy;  
    vec2 suv = gl_FragCoord.xy / resolution.xy;  
    suv *=  1.0 - suv.yx;   //vec2(1.0)- uv.yx; -> 1.-u.yx; Thanks FabriceNeyret !  

    float H = resolution.y*1.50,
          S = round(H/C);             // make number of cells integer for tilability
          
    U.y += (time*33.0);//vertical scroll    
    U /= H;
    U *= S; 
    float m=1e9,m2, v,w, r, r0=1e2;
    
    for (int k=0; k<N*N; k++)                  // neihborhood search
        for (float i=0.; i<B; i++) {                // loop over blobs
            vec2 iU = floor(U),
                  g = mod( iU + vec2(k%N,k/N)-1. , S),  // cell location within neighborhood
                  p = g+.05 + R* srnd2((g+i)*.71)
                      +.1*sin(time+vec2(1.6,0)+3.14*srnd(g+i+i))         // time jittering
                  ;         // blob location
            
            p = mod( p - U +S/2. , S) - S/2.;           // distance to blob center                                  
            r =  1. + dr* srnd(g+i*.91+.01);            // blob radius
            
            // radius growth animation, cellular pulsing 
            r += sin(time *0.1 *srnd(g+i+i))*fract(srnd(g+i+i))*0.1;         
            r = clamp(r, 0.01 , 0.999);// shouldnt need this, but the above radius code can vary wildly
            r+= 0.951;//scalar value offsetting, hack to adjust visuals
            v = length(p) / r*r*r*r*r*r;  
  
         if (v < m) m2 = m, m = v;        // keep 1st and 2nd min distances to node
            else if (v < m2) m2 = v;  
    }

    v = m2-m;                            
    vec4 map_6 =  vec4( 1.-m );            
    vec4 map_9 =  vec4( 1.-m-v );
    O = vec4(.025,.05,.1,0)/v;

    //capture grayscale version of mapping before extra modification
    float graySrc = dot(O.rgb, vec3(0.2126, 0.7152, 0.0722));

    O = (vec4(0.71,0.3,0.1,0)*vec4(smoothstep(-0.31,1.,1.*v)));//smoothstep away the cell borders

    vec3 col = pal( v+U.x/S, vec3(0.8,0.5,0.4),vec3(0.2,0.4,0.2),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25));
    vec3 col2a = pal( -m2-v+U.x+U.y/S, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20));   

    if(scr_uv.x < 0.5)
       col2a = pal( m2-v+U.x+U.y/S, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20));

    /*
    // alternate space warp visualizations
       m2-v+U.y*U.x/S
       m2-v+U.y-U.x/S
    */

  //  vec3 col2 = pal( m2-v+U.y-U.x*U.x/S, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30) );   

   
  // vec4 baseColor = O.rgba;
  // O*=O*0.5;
   O.rgb *= col/col2a*vec3(0.23,0.5,0.13);
   
  // O.bg -= v*v*v*v;
   O.r += v*(v*0.2);
   O.b += v*(v*0.16);
   O.g += v*(v*0.13);
   
    //channel contrasting
    // O.b *= m2;
    //  O.r /= m2;
    // O.g -= col2.b;
   
       O.rgb = O.gbr;//channel swizzle for nicer starter palette
       O.rgb = smoothstep(0.0, 1.3, O.rgb);
   
    //---------------------
    // grayscale conversion
    float gray = dot(O.rgb, vec3(0.2126, 0.7152, 0.0722));
    // regamma
    float gammaGray = sqrt(gray);  
    
    
    if(scr_uv.x > 0.5)
    {
        O.rgb -= vec3(graySrc);//subrtractive effect to break up lines using src mapping
        O.rgb = O.bgr*vec3(0.35,1,1)*m2*-m2;
        
    }
    else
    {
        if(scr_uv.x < 0.25) O.b *= (m2*0.5)*m2*m2*m2;//extra edge glow on far left one
        
        
        O.rgb += vec3(gammaGray);// glow the lefthand side versions
    }
   
   O.r += map_6.r+map_9.r;//visual style
   
   //O.rgb += min(O.rgb,map_3.rgb);
   
   if(scr_uv.x < 0.25)
   {
         O.rgb *= col/m2;
         O.rgb = O.brg;
         O.b -= 12.0*graySrc;
   }
   
   
   
   
//Post   
    float vig = suv.x*suv.y * 15.0; // multiply with sth for intensity    
    vig = pow(vig, 0.125); // change pow for modifying the extend of the  vignette
    O.rgb *= vec3(vig);//final mix

    //section dividers
    O.rgb *= smoothstep( 0.003, 0.005, abs(scr_uv.x-0.5) );
    O.rgb *= smoothstep( 0.003, 0.005, abs(scr_uv.x-0.25) );

	glFragColor = O;

}
