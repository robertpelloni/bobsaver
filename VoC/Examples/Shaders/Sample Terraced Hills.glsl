#version 420

// original https://www.shadertoy.com/view/MtdSRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Terraced Hills
    --------------

    This is an abstract representation of the terraced hills you see throughout various parts 
    of the world. In essence, it's just a very basic terrain layout with some edging.

    I wanted to make something nice and simple. The code is reasonably compact, but without 
    sacrificing too much in the way of efficiency or readability.

*/

// 2x2 matrix rotation. Angle vector, courtesy of Fabrice.
mat2 rot2( float th ){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

// The triangle function that Shadertoy user Nimitz has used in various triangle noise demonstrations.
// See Xyptonjtroz - Very cool.
float tri(in float x){return abs(x-floor(x)-.5);} // Triangle function.
vec2 tri(in vec2 x){return abs(x-floor(x)-.5);} // Triangle function.
//vec2 tri(in vec2 x){return cos(x*6.2831853)*0.25+0.25;} // Smooth version. Not used here.

// One simple noise layer made up of a sawtooth combination.
float hLyr(vec2 p) { return dot(tri(p/1.5 + tri(p.yx/3. + .25)), vec2(1)); }

// I've mentioned this before, but you can make some pretty interesting surfaces simply by 
// combining mutations of a rudimentary functional layer. Take the base layer, then rotate, change
// frequency, amplitude, etc, and combine it with the previous layer. Continue ad infinitum...
// or until your GPU makes you stop. :)
float hMap(vec2 p) {
    
    float ret = 0., a = 1.;

    // Combining three layers of the function above.
    for(int i=0; i<3; i++) {
        ret += abs(a)*hLyr(p/a); // Add a portion of the layer to the final result.
        //p = rot2(1.5707963/3.)*p;
        p = mat2(.866025, .5, -.5, .866025)*p; // Rotate the layer.
        a *= -0.3; // Multiplying the amplitude by a negative for an interesting variation.     
    }

    // Squaring and smoothing the result for some peakier peaks. Not mandatory.
    ret = smoothstep(-.2, 1., ret*ret/1.39/1.39);
    
    
    // The last term adds some ridges. Basically, you take the result then blend in a 
    // small periodic portion of it... The code explains it better. 
    
    return ret*.975 + tri(ret*12.)*.05; // Range: [0, 1].. but I'd double check. :)
    //return ret*.99 + clamp(cos((ret)*6.283*24.)*.5+.5, 0., 1.)*.01; // Another way.

}

// Distance function. A flat plane perturbed by a height function of some kind.
float map(vec3 p) {
    
    return (p.y - hMap(p.xz)*.35)*.75;
    
}

// Tetrahedral normal - courtesy of IQ. I'm in saving mode, so am saving a few map calls.
// I've added to the function to include a rough tetrahedral edge calculation.
vec3 normal(in vec3 p, inout float edge){
  
    // Edging thickness. I wanted the edges to be resolution dependent.
    vec2 e = vec2(-1., 1.)*.5/resolution.y;  
    
    float d1 = map(p + e.yxx), d2 = map(p + e.xxy);
    float d3 = map(p + e.xyx), d4 = map(p + e.yyy); 
    float d = map(p);
    
    edge = abs(d1 + d2 + d3 + d4 - d*4.);
    edge = smoothstep(0., 1., sqrt(edge/e.y*2.));
    
    // Recalculating for the normal. I didn't want the sample spacing to change from
    // one resolution to the next. Hence, the fixed number. Just for the record, I tend
    // to work within the 800 by 450 window. 
    e = vec2(-1., 1.)*.001;  
    d1 = map(p + e.yxx), d2 = map(p + e.xxy);
    d3 = map(p + e.xyx), d4 = map(p + e.yyy); 
    
    return normalize(e.yxx*d1 + e.xxy*d2 + 
                     e.xyx*d3 + e.yyy*d4 );   
}

void main(void) {
    

    // Unit direction ray.
    vec3 rd = normalize(vec3(gl_FragCoord.xy - resolution.y*.5, resolution.y));
    
    // Orienting to face a particular direction.
    rd.yz = rot2(.35)*rd.yz;
    
    // Camera point - Placed above the plane and moving alone along the Z-axis. 
    vec3 ro = vec3(time*.4, .5, time*.2);
    
    // Basic raymarching.    
    float t=0., d;
    for(int i=0; i<96; i++) {
        
        d = map(ro + rd*t);
        
        if(abs(d)<.001*(t*.125 + 1.) || t>20.) break;

        // Using a bit more accuracy nearer the camera.
        t += (step(1., t)*.3 + .7)*d;
    }
    
    // Hit point. Note that about a quarter of the screen hits the curved far plane (sky),
    // so a few cycles are wasted, but there's no nested code block, which looks a bit
    // neater... I wouldn't do this for more sophisticated examples, but it's OK here.
    vec3 sp = ro + rd*t;
    
    // Applying direct lighting. It's simpler, but it's more of an aesthetic choice for this
    // particular example.
    vec3 ld = vec3(-0.676, 0.408, 0.613); // Normalized, or pretty close.
    

    // Normal and edge value.
    float edge;
    vec3 n = normal(sp, edge);
    
    float dif = max(dot(ld, n), 0.); // Diffuse.
    float spe = pow(max(dot(reflect(rd, n), ld), 0.), 16.); // specular.

    float sh = hMap(sp.xz); // Using the height map to enhance the peaks and troughs.
    
    // A bit of random, blocky sprinkling for the hills. Cheap, bit it'll do.
    float rnd = fract(sin(dot(floor(sp.xz*512.), vec2(41.73, 289.67)))*43758.5453)*.5 + .5;

    // The fog. Since the foreground color is pretty bland, I've made it really colorful. I've gone
    // for the sunset cliche. 
    vec3 fog = mix(vec3(.75,.77, .78), vec3(1.04, .95, .87), (pow(1.0 + dot(rd, ld), 3.))*.35);
   
    // Using the values above to produce the final color, then mixing in some fog according to distance.
    vec3 c = mix((rnd*(dif + .1)*sh + fog*spe)*(1. - edge*.7), fog*fog, min(1., t*.3));

    // No gamma correction. If you wanted, you could think of it as postprocessing the final
    // color and gamma correction rolled into one. :)
    glFragColor = vec4(c, 1);
}
