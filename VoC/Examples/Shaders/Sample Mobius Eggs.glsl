#version 420

// original https://www.shadertoy.com/view/ldVXDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Mobius Eggs
    -----------

    Pretty standard Mobius transform, followed by a spiral zoom. I've always liked 
    this particular combination, and so do plenty of others, since it's used to
    produce a lot of the interesting geometric pictures you see all over the net.

    This particular example is based off of a couple of snippets I came across in 
    Flexi and Dila's code... I think. I can't quite remember where it came from.
    The rest is just some raytraced, lit spheres. Pretty boring on their own, but 
    made to look more interesting when transformed.

    Anyway, the purpose of this was just to show the process. It's possible to make 
    far more interesting things.    

    // Much simpler, easy to decipher example:
    Logarithmic Mobius Transform - Shane
    https://www.shadertoy.com/view/4dcSWs

    Other examples:

    bipolar complex - Flexi
    https://www.shadertoy.com/view/4ss3DB

    Mobius - Dila
    https://www.shadertoy.com/view/MsSSRV

    Moebius Strip - dr2
    https://www.shadertoy.com/view/lddSW2

*/

// 2x2 hash algorithm. Used to add some light sprinkles to the background.
vec2 hash22(vec2 p) { 

    // More concise, but wouldn't disperse things as nicely as other versions.
    float n = sin(dot(p, vec2(41, 289))); 
    return fract(vec2(8, 1)*262144.*n);

}

// Intersection of a sphere of radius one.
float trace( in vec3 ro, in vec3 rd ){
    
    float b = dot(ro, rd);
    float h = b*b - dot(ro, ro) + 1.;
    if (h<0.) return -1.;
    return -b - sqrt(h);
    
}

// For all intents and purposes, this is just a grid full of raytraced spheres.
// They look like eggs due to the transform warping. All of it is standard, and
// most is just window dressing, like patterns, lighting, etc.
vec3 scene(vec2 uv){

    // Grid cell ID. Used to color the spheres. In this case, white of red.
    vec2 id = mod(floor(uv), 5./2.);
    
    // Partition space (the 2D canvas) into squares.
    uv = fract(uv) - .5;

    
    // Draw a lit, raytraced sphere in each grid cell. From here it's just boring
    // intersection and lighting stuff.
    
    
    // Ray origin, unit ray and light.
    vec3 ro = vec3(0, 0, -2.4);
    vec3 rd = normalize( vec3(uv, 1.));
    vec3 lp = ro + vec3(cos(time), sin(time), 0)*4.;
    
    // Sphere intersection.
    float t = trace( ro, rd );
    
    
    // Dark background.
    vec3 col = vec3(1, .04, .1)*0.003 + length(hash22(uv + 7.31))*.005;
    
    if (t>0.){
    
        
        // Surface point.
        vec3 p = ro + rd*t;
        
        // Normal.
        vec3 n = normalize(p);
        
        // Point light.
        vec3 ld = lp - p;
        float lDist = max(length(ld), 0.001);
        ld /= lDist;
        
        float diff = max(dot(ld, n), 0.); // Diffuse.
        float spec = pow(max(dot(reflect(-ld, n), -rd), 0.), 32.); // Specular.
        
        // Adding a sinusoidal pattern.
        float c = dot(sin(p*8. - cos(p.zxy*8. + 3.14159 + time)), vec3(.166)) + .5;
        float f = c*6.;
        c = clamp(sin(c*3.14159*6.)*2., 0., 1.);
        c = sqrt(c*.75+.25);
        vec3 oCol = vec3(c); // Coloring the object white.
        
        // Coloring the object red, based on ID.
        if(id.x>1.25) oCol *= vec3(1, .04, .1);
        
    
        // Adding some fake environment mapping. Not that great, but it gives
        // a slight reflective sheen.
        p = reflect(rd, n)*.35;
        c = dot(sin(p*8. - cos(p.zxy*8. + 3.14159)), vec3(.166)) + .5;
        f = c*6.;
        c = clamp(sin(c*3.14159*6.)*2., 0., 1.);
        c = sqrt(c*.75+.25);
        vec3 rCol = vec3(min(c*1.5, 1.), pow(c, 3.), pow(c, 16.)); // Reflective color.
        
        // Producing the final lit color.
        vec3 sCol = oCol*(diff*diff + .5) + vec3(.5, .7, 1)*spec*2. + rCol*.05;
       
        // Applying attenuation.
        sCol *= 1.5/(1. + lDist*.25 + lDist*lDist*.05);

        // Simple trick to antialias the edges of a raytraced sphere.
        float edge = max(dot(-rd, n), 0.);
        edge = smoothstep(0., .35, edge); // Hardcoding. A bit lazy.
        // Taper between the sphere edge and the background.
        col = mix(col, min(sCol, 1.), edge); 
        
    }
    

    
    // Clamp and perform some rough gamma correction.
    return sqrt(clamp(col, 0., 1.));
}

// Standard Mobius transform: f(z) = (az + b)/(cz + d). Slightly obfuscated.
vec2 Mobius(vec2 p, vec2 z1, vec2 z2){

    z1 = p - z1; p -= z2;
    return vec2(dot(z1, p), z1.y*p.x - z1.x*p.y)/dot(p, p);
}

// Standard spiral zoom.
vec2 spiralZoom(vec2 p, vec2 offs, float n, float spiral, float zoom, vec2 phase){
    
    p -= offs;
    float a = atan(p.y, p.x)/6.283;
    float d = length(p);
    return vec2(a*n + log(d)*spiral, -log(d)*zoom + a) + phase;
}

/*
// Antialiased circle. The coordinates are mutated, so "fwidth" is used for
// concise, gradient-related, edge smoothing.
float circle(vec2 p) {
    
    p = fract(p) - .5;
    float d = length( p ); return smoothstep(0., fwidth(.4-d)*1.25, .4-d);
}
*/

void main(void) {

    // Screen coordinates.
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy) / resolution.y;

    // Transform the screen coordinates.
    uv = Mobius(uv, vec2(-.75, 0), vec2(.5, 0));
    uv = spiralZoom(uv, vec2(-.5), 5., 3.14159*.2, .5, vec2(-1, 1)*time*.125);
    
    // Pass the transformed coordinates into the scene equation. Uncomment either, or both,
    // or the lines above to see a less transformed version.
    
    // Draw some repeat lit spheres with the transformed coordinates. Just the one sphere 
    // is rendered, but it's repeated across a 2D grid using the "fract(uv)" trick.
    vec3 col = scene(uv*5.);
    
    // Much, much simpler version with plane circles. One could argue that it 
    // looks better too. :)
    //vec3 col = vec3(circle(uv*4.));
    
    // An interesting alternative. Worth looking at. Requires a wrappable texture
    // to be loaded into channel zero.
    //vec3 col = texture2D(iChannel0, uv).xyz; // Texture, if desired.
    
    // Apply a vignette and increase the brightness for that fake spotlight effect.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y) , .125)*1.15;

    
    glFragColor = vec4(min(col, 1.), 1);
    

}
