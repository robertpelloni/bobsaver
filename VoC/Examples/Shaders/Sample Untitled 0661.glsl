#version 420

// original https://www.shadertoy.com/view/NldGDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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

// based on comments from FabriceNeyret2
// https://www.shadertoy.com/view/7d3SDS
// super elegant
vec2 bary(vec2 A, vec2 B, vec2 C, vec2 P){
    
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
    float f1 = S(0.,eps, tri.y-tri.x - 0.02);
    //border of area1 and area3 (uv.z-uv.y)
    float f2 = S(0.,eps, tri.z-tri.x - 0.02);
    return vec2(id.x,f1*f2);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 3.*(gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    uv.x += time/4.;
    uv *= skew;
    vec2 uvFL = floor(uv);
    uv = fract(uv);
    
    vec2 f = 1.0 - S(0., eps, abs(uv-0.5)-0.48 );
    float fd =  S(0., eps, abs(uv.x-uv.y)-0.02 );
    
    float side = sign(uv.x-uv.y);
    
    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(vec3(0,2,4));
    
    vec2 stuff = bary(vec2(0.), 
                       vec2(1.,side<0.), 
                       vec2(side>0.,1.),
                       uv);
                       
    col = 0.5 + 0.5*cos(vec3(1.,2.,4.)/3. + 
          badHash(uvFL+side*0.5 + stuff.x/3.)*80. + time/2. );
  
    col *= f.x;
    col *= f.y;
    col *= fd;
    col *= stuff.y;
    // Output to screen
    glFragColor = vec4(col,1.0);
}
