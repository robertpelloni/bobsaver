#version 420

// original https://www.shadertoy.com/view/4dsfDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Smooth Voronoi Borders
    ----------------------

    Producing some round-looking Voronoi borders with some simple alterations to the regular 
    Voronoi formula. As an aside, the results are presented in a faux 3D style. Essentially,
    it's a 2D effect.

    Dr2 has been putting up some rounded Voronoi border examples lately, and Abje produced
    a really cool one using a very simple tweak.

    Dr2's variation is fast and nicely distributed,    and as such, translates well to a 
    raymarching environment. Abje's tweak can be combined with either IQ or Tomk's line
    distance Voronoi examples to produce really good quality rounded borders - I intend to 
    produce an example later that I hope does it justice.

    This is yet another variation that I put together ages ago. I've outlined the method in
    the Voronoi function - not that it needs much explaining. It does the job under the
    right circumstances and it's reasonably cheap and simple to implement. However, for
    robustness, I'd suggest using one of the aforementioned methods.

    By the way, all variations basically do the same thing, and rely on the idea of
    incorporating a smooth distance metric into a Voronoi-like formula, which IQ wrote about 
    in his article on smooth Voronoi.

    On a side note, Fabrice Neyret incorporated a third order distance to produce a rounded 
    border effect also, which I used for an example a while back.

    Anyway, just for fun, I like to make 3D looking effects using nothing more than 2D layers. 
    In this case, I went for a vector layered kind of aesthetic. For all intents and purposes, 
    this example is just a few layers strategically laced together. It's all trickery, so 
    there's very little physics involved.

    Basically, I've taken a Voronoi sample, then smoothstepped it in various ways to produce 
    the web-like look. I've also taken two extra nearby samples in opposite directions, 
    then combined the differences to produce opposing gradients to give highlights, the red 
    and blue environmental reflections, etc. There's an offset layer for fake shadowing,
    the function value is used for fake occusion... It's all fake, and pretty simple too. :)

    // Other examples:

    // Faster method, and more evenly distributed.
    Smoothed Voronoi Tunnel - Dr2
    https://www.shadertoy.com/view/4slfWl

    // I like this method, and would like to cover it at some stage.
    Round Voronoi - abje
    https://www.shadertoy.com/view/ldXBDs

    // Smooth Voronoi distance metrics. Not about round borders in particular, but it's
    // the idea from which everything is derived.
    Voronoise - Article, by IQ
    http://iquilezles.org/www/articles/voronoise/voronoise.htm

    // A 3rd order nodal approach - I used it in one of my examples a while back. 
    2D trabeculum - FabriceNeyret2
    https://www.shadertoy.com/view/4dKSDV

*/

// vec2 to vec2 hash.
vec2 hash22(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(41, 289)));
    //return fract(vec2(262144, 32768)*n); 
    
    // Animated.
    p = fract(vec2(262144, 32768)*n); 
    // Note the ".333," insted of ".5" that you'd expect to see. When edging, it can open 
    // up the cells ever so slightly for a more even spread. In fact, lower numbers work 
    // even better, but then the random movement would become too restricted. Zero would 
    // give you square cells.
    return sin( p*6.2831853 + time)*.333 + .333; 
    //return sin( p*6.2831853 + time*2.)*(cos( p*6.2831853 + time*.5)*.3 + .5)*.45 + .5; 
    
}

//smoothmin function by iq
float smin( float a, float b, float k )
{
    float h = clamp(.5 + .5*(b - a)/k, 0., 1.);
    return mix(b, a, h) - k*h*(1. - h);
}

// 2D 2nd-order Voronoi: Obviously, this is just a rehash of IQ's original. I've tidied
// up those if-statements. Since there's less writing, it should go faster. That's how 
// it works, right? :)
//
// This is exactly like a regular Voronoi function, with the exception of the smooth
// distance metrics.
float Voronoi(in vec2 p){
    
    // Partitioning the grid into unit squares and determining the fractional position.
    vec2 g = floor(p), o; p -= g;
    
    // "d.x" and "d.y" represent the closest and second closest distances
    // respectively, and "d.z" holds the distance comparison value.
    vec3 d = vec3(2); // 8., 2, 1.4, etc. 
    
    // A 4x4 grid sample is required for the smooth minimum version.
    for(int j = -1; j <= 2; j++){
        for(int i = -1; i <= 2; i++){
            
            o = vec2(i, j); // Grid reference.
             // Note the offset distance restriction in the hash function.
            o += hash22(g + o) - p; // Current position to offset point vector.
            
            // Distance metric. Unfortunately, the Euclidean distance needs
            // to be used for clean equidistant-looking cell border lines.
            // Having said that, there might be a way around it, but this isn't
            // a GPU intensive example, so I'm sure it'll be fine.
            d.z = length(o); 
            
            // Up until this point, it's been a regular Voronoi example. The only
            // difference here is the the mild smooth minimum's to round things
            // off a bit. Replace with regular mimimum functions and it goes back
            // to a regular second order Voronoi example.
            d.y = max(d.x, smin(d.y, d.z, .4)); // Second closest point with smoothing factor.
            d.x = smin(d.x, d.z, .2); // Closest point with smoothing factor.
                       
        }
    }    
    
    // Return the regular second closest minus closest (F2 - F1) distance.
    return d.y - d.x;
    
}

 

void main(void)
{
    // Screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/ resolution.y;
    //
    // Mild, simplistic fisheye effect.
    uv *= (.9 + length(uv)*.2);
    //
    // Scrolling action.
    uv -= time*vec2(1, .25)/8.;
    
    
    // The function samples. Six 4x4 grid Voronoi function calls. That amount of work would
    // break an old computer, but it's nothing for any reasonably moder GPU.
    //
    // Base function value.
    float c = Voronoi(uv*5.);
    // Nearby samples to the bottom right and bottom left.
    float c2 = Voronoi(uv*5. - .002); 
    float c3 = Voronoi(uv*5. + .002);
    // A more distant sample - used to fake a shadow and highlight.
    float c4 = Voronoi(uv*5. + vec2(.7, 1)*.2);
    // Slight warped finer detailed (higher frequency) samples.
    float c15 = Voronoi(uv*15. + c);
    float c45 = Voronoi(uv*45. + c*2.);

  
    // Shading the Voronoi pattern.
    //
    // Base shading and a mild spotty pattern.
    vec3 col = vec3(c*c)*(.9 + (c15 - smoothstep(.2, .3, c15))*.2);
    //
    // Mixing in some finer cloudy detail.
    float sv = c15*.66 + (1. - c45)*.34; // Finer overlay pattern.
    col = col*.8 + sv*sqrt(sv)*.4; // Mix in a little of the overlay.
    
    
    // Simple pixelated grid overlay for a mild pixelated effect.
    vec2 sl = mod(gl_FragCoord.xy, 2.);
    //
    // It looks more complicated than it is. Mildly darken every second vertical 
    // and horizontal pixel, and mildly lighten the others.
    col *= 4.*(1. + step(1., sl.x))*(1. + step(1., sl.y))/9.;
    
    
    // Adding a red highlight to the bottom left and a blue highlight to the top right. The 
    // end result is raised bubbles with environmental reflections. All fake, of course...  
    // Having said that, there is a little directional derivative science behind it.
    float b1 = max((c2 - c)/.002, 0.); // Gradient (or bump) factor 1.
    float b2 = max((c3 - c)/.002, 0.); // Gradient (or bump) factor 2.
    //
    // A touch of deep red and blue, with a bit of extra specularity.
    col += vec3(1, .0, .0)*b2*b2*b2*.15 + vec3(0, .0, 1)*b1*b1*b1*.15; 
    //
    // Slightly more mild orange and torquoise with less specularity.
    col += vec3(1, .7, .4)*b2*b2*.3 + vec3(.4, .6, 1)*b1*b1*.3; 
     
    // Distant sampled overlay for a shadowy highlight effect. Made up. There'd be better ways.
    float bord2 = smoothstep(0., fwidth(c4)*3., c4 - .1);
    col = max(col + (1.-bord2)*.25, 0.);
    
    // The web-like overlay. Tweaked to look a certain way.
    float bord3 = smoothstep(0., fwidth(c)*3., c - .1) - smoothstep(0., fwidth(c)*2., c - .08);
    col *= 1. + bord3*1.5;
     
    // Another darker patch overlay to give a shadowy reflected look. Also made up. 
    float sh = max(c4 - c, 0.);
    col *= (1. - smoothstep(0.015, .05, sh)*.4);
   
    // For some reason, I wanted a bit more shadow down here... I'm sure I had my reasons. :) 
    col -= (1.-bord2)*.1;
 
    // Smoothstepping the original function value, then multiplying for oldschool, fake occlusion. 
    col *= smoothstep(0., .15, c)*.85 + .15;
 
    // Postprocessing. Mixing in bit of ramped up color value to bring the color out more.
    col = mix(col, pow(col, vec3(4)), .333);
    

    // Rought gamma correction and screen presentation.
    glFragColor = vec4(sqrt(col), 1);
    
}
