#version 420

// original https://www.shadertoy.com/view/Nl33WM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
This is an illustration of the stratificational nexus 
of a welfare state regime. The darker patches are all 
equally poor, aided by government funding. 

The lighter patches are unevenly wealthy.

This is all bull%&*$ btw lol.
------------------------------------------------------

The magic of this shader is the movement 
aided by the smoothmin function and a hacked together
animation sequence.
*/

//barycentric
#define eps 8./resolution.y
#define S smoothstep

//#define cross2D(a,b) a.y*b.x-a.x*b.y
#define cross2D(a,b) (a).y*(b).x-(a).x*(b).y
//skew matrix often written as 
//mat2 skew = mat2(1.1547, 0., 1.1547/2., 1.);
mat2 skew = mat2(2./sqrt(3.), 0., 1./sqrt(3.), 1.); 

//This hash is pretty bad
float badHash(vec2 x){
    return fract(sin(dot(vec2(23.,72.),x)*134.)*43143.);
}
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
// based on comments from FabriceNeyret2
// https://www.shadertoy.com/view/7d3SDS
// super elegant
vec2 bary(vec2 A, vec2 B, vec2 C, vec2 P,float smoothID){
    
    //We want areas for the three triangles created
    //with out point P and the 3 sides
    //we get a triangle with vectors AtoB and AtoP
    //Repeat with B and C
    vec3 tri = vec3(length(cross2D(B-A,P-A)),
                    length(cross2D(C-B,P-B)),
                    length(cross2D(A-C,P-C))
                    );
    //If P is in the middle, all areas are equal
    //If P lays between two sub triangles, those areas
    //will be equal and there will be one other area
    
    
    //chill sort to find the smallest area triangle
   
    //id which we will swap simultenously
    vec3 id = vec3(1.,2.,3.);
   
    //swap to get minumum at x
    //swap remaining two to get minumum at y
    if(tri.z < tri.y) tri = tri.xzy, id = id.xzy;
    if(tri.y < tri.x) tri = tri.yxz, id = id.yxz;
    if(tri.z < tri.y) tri = tri.xzy, id = id.xzy;
    //with tri sorted, can do smoothstep without abs
    
    
    //Those areas become a coordinate system because together 
    //they tell us relatively how close P is to any of 
    //the three sides.
    
    //so "borders" are like with uv.x-uv.y but now 3d 
    //border of area1 and area2 like (uv.y-uv.x)
    float f1 = tri.y-tri.x - 0.04;
    //border of area1 and area3 (uv.z-uv.y)
    float f2 = tri.z-tri.x - 0.04;
    return vec2(id.x, smin(f1,f2,smoothID*0.9));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 3.*(gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    uv.x += time/4.;
    
    
    uv *= skew;
    vec2 uvFL = floor(uv);
    uv = fract(uv);
    vec2 f = 1.0 - S(0., eps, abs(uv-0.5)-0.47 );
    float fd =  S(0., eps, abs(uv.x-uv.y)-0.02 );
    float side = sign(uv.x-uv.y);
    
    
    //the cool stuff
    float smoothSeed = badHash(uvFL+float(side>0.)*0.5)*80.;
    float smoothID = sin(smoothSeed +time
    *4.)*0.5+0.5;
    float closed = smoothstep(0.,0.5,sin(time/2.+smoothSeed)*0.5+0.5);
    smoothID *= closed;

    vec3 col;
    
    //get stuff from barycentric function
    //stuff.x = the sub triangle id (1 to 3), stuff.y are outlines
    vec2 stuff = bary(vec2(0.), 
                       vec2(1.,side<0.), 
                       vec2(side>0.,1.),
                       uv,
                       smoothID); //<--smoothID is for open/close anim
    
    //initial coloring
    col = 0.6 + 0.3*cos(vec3(1.,2.,4.)/3. + 
          badHash(uvFL+side*0.5 + stuff.x/3.)*80. + time );
  
  
    //do all the coloring(outlines, color when closed/not closed, etc)
    col = mix(col, vec3(0.2), 1.-closed);
    col += vec3(1.,0.,0.)*closed*0.18;
    col *= f.x;
    col *= f.y;
    col *= fd;
    col -= S(0.8,1.,(abs(sin(stuff.y*30.+2.))))*0.5;
    col -= floor(stuff.y*30.)/24.;
    col *= S(0.,eps,stuff.y);
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
