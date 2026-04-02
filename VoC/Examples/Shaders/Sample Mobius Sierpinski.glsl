#version 420

// original https://www.shadertoy.com/view/XsGXDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Mobius Sierpinski
    -----------------

    Applying a Mobius transform and spiral zoom to a Sierpinski Carpet pattern.

    Related examples:

    // Nice and simple.
    SierpinskiCarpet - jt
    https://www.shadertoy.com/view/ldc3WH
    
    Mobius Eggs - Shane
    https://www.shadertoy.com/view/ldVXDG

*/

// Standard Mobius transform: f(z) = (az + b)/(cz + d). Slightly obfuscated.
vec2 Mobius(vec2 p, vec2 z1, vec2 z2){

    z1 = p - z1; p -= z2;
    return vec2(dot(z1, p), z1.y*p.x - z1.x*p.y)/dot(p, p);
}

// Standard spiral zoom.
vec2 spiralZoom(vec2 p, vec2 offs, float n, float spiral, float zoom, vec2 phase){
    
    p -= offs;
    float a = atan(p.y, p.x)/6.283 - time*.25;
    float d = log(length(p));
    return vec2(a*n + d*spiral, a - d*zoom) + phase;
}

// Mobius, spiral zoomed, Sierpinski Carpet pattern.
vec3 pattern(vec2 uv){
    
    // A subtlely spot-lit background. Performed on uv prior to tranformation,
    float bg = max(1. - length(uv), 0.)*.025; 
    
    // Transform the screen coordinates. Comment out the following two lines and 
    // you'll be left with a standard Sierpinski pattern.
    uv = Mobius(uv, vec2(-.75, cos(time)*.25), vec2(.5, sin(time)*.25));
    uv = spiralZoom(uv, vec2(-.5), 5., 3.14159*.2, .5, vec2(-1, 1)*time*.25);
    
     
    vec3 col = vec3(bg); // Set the canvas to the background.
    
    // Sierpinski Carpet - Essentially, space is divided into 3 each iteration, and a 
    // shape of some kind is rendered. In this case, it's a smooth rectangle
    // with a bit of shading around the side.
    //
    // There's some extra steps in there (the "l" and "mod" bits) due to the 
    // shading and coloring, but it's pretty simple.
    //
    // By the way, there are other combinations you could use.
    //
    for(float i=0.; i<4.; i++){
        
        uv = fract(uv)*3.; // Subdividing space.
        
        vec2 w = .5 - abs(uv - 1.5); // Prepare to make a square. Other shapes are also possible.
        
        float l = sqrt(max(16.0*w.x*w.y*(1.0-w.x)*(1.0-w.y), 0.)); // Vignetting (edge shading).
        
        w = smoothstep(0., length(fwidth(w)), w); // Smooth edge stepping.
        
        vec3 lCol = vec3(1)*w.x*w.y*l; // White shaded square with smooth edges.
        
        if(mod(i, 3.)<.5) lCol *= vec3(0.1, 0.8, 1); // Color layers zero and three blue.
        
        col = max(col, lCol); // Taking the max of the four layers.
        
    } 
    
    return col;
    
}

void main(void) {

    // Screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    // Transformed Sierpinski pattern.
    vec3 col = pattern(uv);
    
    // Rough gamma correction.
    glFragColor = vec4(sqrt(col), 1);
}
