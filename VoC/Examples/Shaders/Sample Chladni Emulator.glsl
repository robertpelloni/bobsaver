#version 420

// original https://www.shadertoy.com/view/3tsSDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//using a wave tank emulation, with 4 wave engines  placed in symmetry the waves meet in the middle. when wave engines are far away, the lines made by the
//wave engines are nearly straight and the middle is same as in the pic.
//Please share developments from this work on this page in comments. 
//Prizes for you if you can make a linear-tile-version using square waves instead of sines or somthing.
//Creative Commons â€” Attribution 3.0 Antony Stewart
//overall formula is a variable patterned alternataive to perlin noise function
//and can be used for iso-surfaces i.e multiply in 3d with a sphere.

void main(void) //WARNING - variables void (out vec4 color, vec2 UVcoords ) need changing to glFragColor and gl_FragCoord
{
    vec2 UVcoords = gl_FragCoord.xy;
    vec4 color = glFragColor;

   float d3 = resolution.y*.5 ,//number to move pic upwards
         d4 =  resolution.x*.5 ,//number to move pic sideways
         d2 = 8.0 - 4.0 * sin( 5.0+time*.07 ) + mouse.y*resolution.xy.y*0.0021, //number to move 5 wave machines outwards
        d1 = .5; ;// wave width
   UVcoords = .5*(UVcoords - vec2(d4,d3)); //move pic around
    
    
    //function to make color concentric sinewaves like water drop waves radiating from a pt:   
#define S(X, Y, period)   color += sin(length(UVcoords + vec2(X,Y)*d2)*period);    
     //if (color.x<0.0)
    // color += sin(UVcoords.x*100.0*time)/6.0;
    //  color += sin(UVcoords.y*150.0*time)/6.0;  
    // sin(length()*p2)+v2
    //see end for full formula including angular coordinates as well as concentric
    //Tip: to remix the code, you can try mixing 3/4/8 
    //wave machines in different symmetries and vary their distance and amplitudes
  

   
//make 5 wave machines where the color is added t*d2ogether on coordinates of pentagon:
    
    //central wave machine on origin
    S(0.0,0.0,mouse.x*resolution.xy.x*0.002)
        
    //4 other wave machines on axes
    S(0,1.0*d2,d1)  S(0,-1.0*d2,d1)  S(-1.0*d2,-0.0,d1)  S(1.0*d2,0.0,d1)  

    glFragColor = color; 
}
    

//NOTE: original version had concentric wave forms in this fasion:

//float2 xy2 = IN.uv_MainTex + float2(-0.5, -0.5*d3 ) + float2(k1,j1)*d2; 
//position of the point

//float c2 = length(xy2);//polar coordinates (x axis becomes radial)

//ht+=  (sin(c2 * p2)  *v2) ;//angular coordinates (y becomes angle)
    
    

