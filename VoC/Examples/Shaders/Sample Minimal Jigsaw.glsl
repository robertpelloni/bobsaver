#version 420

// original https://www.shadertoy.com/view/wddGzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Minimal Jigsaw
    --------------

    I put together a square 3D jigsaw pattern a while back, and Fizzer 
    noticed that it could be constructed with less effort when considering
    one diagonal (instead of the four sides I was comparing), then put 
    together a cool example demonstrating that. The link is below, for 
    anyone interested.

    Anyway, that idea got me wondering just how little code you could
    use to construct a basic colored jigsaw pattern, so this is my take
    on it. 

    Fizzer took a clever space segmented approach. My mind isn't as 
    sophisticated, so I usually have to code things in a brute force 
    fashion, then look for optimization opportunities via patterns and
    symmetry, and so forth, so that's the method I applied here. Either way, 
    I was pleasantly surprised by how much it was possible to cut things 
    down. Having said that, I still left enough code in there to give the 
    code golfers something to work with. :)

    
    Other Examples:

    // Cleverly constructed, as always.
    Jigsaw Pattern - Fizzer
    https://www.shadertoy.com/view/3tlXR4

    // Jigsaw patterns are possible with all kinds of shapes.
    Isosceles Jigsaw Strips - Shane
    https://www.shadertoy.com/view/3sd3Rj

*/

// IQ's vec2 to float hash, with some decimals taken out. Obviously,
// you wouldn't use these figures for more important things.
float h21(vec2 p){  return fract(sin(dot(p, vec2(27.3, 57.7)))*1e4); }

// A basic diamond shape -- Shuffled a little. 
float di(vec2 p){ p = abs(p); return (p.x + p.y - 1.)*.7 + .05; }

// The jigsaw pattern algorithm -- cut down considerably.
//
// Each cell consists of a diagonal partitioning with one jigsaw piece 
// color on one side and its neighboring color on the other. In addition 
// the diagonals are oriented in such a way that they form diamonds, or
// squares, depending on perspective. The nodule logic involves rendering 
// a circle over a random side of the line and updating the color ID 
// accordingly. 
//
// Trust me, none of it is that hard. The only thing left to do after 
// that was to look for symmetrical patterns in order to minimize 
// instruction count, streamline the syntax, etc.
//
vec3 jigsaw(vec2 p){
    
    // Local cell ID and coordinates.
    vec2 ip = floor(p); p -= ip + .5; 
 
    // Directional helper vectors.
    vec2 m = fract(ip/2.)*2. - .5; // Orientation vector.   
    vec2 dirV = dot(m, p)<0.? -m : m; // Direction vector.
    vec2 rD = (h21(ip) - .5)*dirV;///m; // Random vector.
    
    // Temporary fix for the zero case, which seems to confuse
    // the GPU on occasion, resulting in an absent nodule.
    //if(rD.x == 0.) rD += dirV; 
    
    // The distance functions -- A diamond, and offset nodule.
    float d = di(p - dirV), c = length(p - dirV*.2) - .2;
    
    

    // Add the nodules to a random side of the diagonal.
    if(rD.x<0.){  
        d = max(d, .1 - c);
        if(c<d) ip -= dirV*2.;
    }  
     
    // Return the distance field and ID.
    return vec3(min(d, c), ip + dirV);    
}

void main(void) {

    vec4 fC = glFragColor;
    vec2 u = gl_FragCoord.xy;

    // Aspect correct screen coordinates.
    vec2 R = resolution.xy;
    
    // Resizing and scaling.
    u = (u - R*.5)/R.y*8. + vec2(1, .5)*time;
  
    // The jisaw pattern.
    vec3 d = jigsaw(u);

    // Some ID-based coloring.
    //vec3 col = vec3(1, h21(d.yz)*.65 + .35, h21(d.yz + .5)*.7 + .3);
    //col = mix(col.yzx, col, h21(d.yz + .2));
    // Fabrices addition: It's a really pleasant palette too. 
    vec3 col = .8 + .2*cos(6.3*h21(d.yz) + vec3(0, 23, 21));

    // Apply the jigsaw pattern.
    col = mix(col, vec3(0), smoothstep(0., 8./R.y, d.x));   
     
    // Rough gamma correction.
    fC = vec4(sqrt(col), 1);  

    glFragColor = fC;  
}
