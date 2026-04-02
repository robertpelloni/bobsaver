#version 420

// original https://www.shadertoy.com/view/NsScRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float TWO_PI      = 6.28318530718;
const float PI          = TWO_PI / 2.;

//////////////////// CONTROLS PANEL /////////////////////

// PALETTE
const vec3  BG_COLOR    = vec3(0.4196, 0.1216, 0.4039);
const vec3  LIGHT_COLOR = vec3(0.9000, 0.9000, 0.0000);
const vec3  DARK_COLOR  = vec3(1.0000, 0.0766, 0.2196);

// LAYOUT
const float SPACING     = 0.1; // Gap between each texel.

// BEHAVIOUR
const float useRadials  = 1.0; // Switches the shape of texels between square and circle.

/////////////////////////////////////////////////////////

/////////////////////// FUNCTIONS ///////////////////////

mat2 rotationMatrix(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat2(
        c, -s,
        s,  c
    );
}

float Bitmap(in vec2 uv )
{
    vec2 map = vec2(3.);  

    // Subtract from local UV position, to ensure results lay inside the bounding box.
    uv -= 0.15;
    
    // Multiply the UV by the bitmap size so work can be done in
    // bitmap space coordinates.
    uv *= vec2(map);

    // Compute bitmap texel coordinates.
    vec2 muv = vec2(round(uv));
    
    // Bounding box check. With branches, so we avoid the maths and lookups .   
    if( muv.x<0. || muv.x>map.x-1. ||
        muv.y<0. || muv.y>map.y-1. ) return 0.;

    // Compute bit index.
    float index = map.x*muv.y + muv.x;
    
    // Get the appropriate bit and return it.
    return index;

}

vec2 QuadBox(in vec2 target, in vec2 cs ) {
    cs *= rotationMatrix(-TWO_PI*(target.y/4.)) * target.x;
    
    cs -= SPACING/7.; // Offseting the quadrant from the main widget's central axis.
    
    /////////////////// 3 x 3 TEXEL GRID ////////////////////
    // By further dividing the quadrant, we can focus on each
    // individual texel's orientation and appearence.
    
    float mask = target.x - max(floor(cs).x, floor(cs).y); // Masking the space of the quadrant widget.

    cs *= mask;
    
    float index = Bitmap(cs); // Getting the index of each texel (bottom-right to top-left) from 0 to 8.
    
    cs = fract(cs*vec2(3.));  // Division

    cs *= 1. + SPACING;       // Gaps

    float grid_mask = mask - (max(floor(cs).x, floor(cs).y) + floor(cs).x);

    // Centering the UV of the texel, keeping it normalized.
    cs -= 0.5;
    cs *= 2.;
    
    grid_mask = mix(grid_mask, min(grid_mask , (1. - floor(length(cs)))), step(1., useRadials) );
    
    /////////////////////// ANIMATION ///////////////////////
    // Were the effect takes place.
    
    float start      = -TWO_PI/4.;
    float phase_diff =  PI / 10.;
    
    cs *= rotationMatrix((phase_diff * mod(index, 3.)) - (start + phase_diff * floor(index/3.)) - time);
    
    cs *= grid_mask;

    ////////////// SIMPLE ARCTANGENT POINTER ///////////////
    
    vec2 polar_cs = vec2(atan(cs.x, cs.y)/TWO_PI+0.5, length(cs));
    
    float stencil = (1. - polar_cs.x) * grid_mask;
    
    
    return vec2(stencil, grid_mask);

}

/////////////////////////////////////////////////////////

void main(void)
{
    //////////// COORDINATE SPACE MODIFICATION ////////////
    // The idea is to create a square UV plane,
    // despite the rectangular form of the screen and place it
    // at the center.
    
    vec2  uv = gl_FragCoord.xy/resolution.xy;
    float ar = resolution.y / resolution.x;
    uv      -= 0.5;
    uv      *= vec2(PI, 1./ar);
    
    uv *= vec2(1.2);     // Size adjustment to create a gap between the following widget and top/bottom edges.
    
    uv *= vec2(1., -1.); // Y flip. This step is mandatory.
    
    ////////////////// QUADRANT WIDGETS /////////////////
    // By dividing the above UV plane into four equal squares,
    // we can isolate the individual spaces and easily achieve migration
    // of changes to the neighbouring squares via duplication/rotation.
    
    vec2 quadrants = step(vec2(0.0), uv);

    // 2D Vector with:
    // X: Quadrant Space
    // Y: Index of Rotation
    vec2 down_right = vec2(  step(1., quadrants.x) * step(1., quadrants.y),    4.);
    vec2 down_left  = vec2( (step(1., quadrants.y) - down_right.x),            1.);
    vec2 up_right   = vec2( (step(1., quadrants.x) - down_right.x),            3.);
    vec2 up_left    = vec2( (1. - (down_right.x + down_left.x + up_right.x)),  2.);

    // 2D Vector with:
    // X: Quadrant Texel Mask
    // Y: Grid Space Mask
    vec2 BOX_ONE    = QuadBox(up_left,    uv);
    vec2 BOX_TWO    = QuadBox(up_right,   uv);
    vec2 BOX_THREE  = QuadBox(down_right, uv);
    vec2 BOX_FOUR   = QuadBox(down_left,  uv);

    //////////////////// ASSEMBLY AREA ///////////////////
    // Putting everyting together.
    
    float center_box_grid_mask = step(0.5, max(max(max(BOX_ONE.y, BOX_TWO.y), BOX_THREE.y), BOX_FOUR.y));

    // Sum of all quadrants (this is stil a mask).    
    float CENTER_BOX = max(max(max(BOX_ONE.x, BOX_TWO.x), BOX_THREE.x), BOX_FOUR.x);

    // Applying Colors..
    vec3 col = mix(LIGHT_COLOR, DARK_COLOR, 1. - CENTER_BOX);
    col      = mix(col, BG_COLOR, 1. - center_box_grid_mask);
    
    //////////////// FINAL COLOR OUTPUT /////////////////
    glFragColor = vec4(col,1.0);
}
