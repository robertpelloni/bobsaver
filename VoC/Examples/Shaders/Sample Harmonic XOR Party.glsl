#version 420

// original https://www.shadertoy.com/view/WdlXW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Grid with animated modulated Circles
// Harmonic XOR-Party

// Please wait for a while and look what's happening!
// Concentric Waves will turn into constantly changing harmonic patterns

float Xor(float a, float b) {
    return a*(1.-b) + b*(1.-a);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y; // set center to the middle of the screen
    vec3 col = vec3(0.,0.,0.); // black screen    
    
    // ---- Play with the values -----------------------------------------------------------------------------------------------

    float r1 = 0.; // 0 <> 1.5 for circles : smallest radius
    float r2 = 0.9; // 0 <> 1.5 for circles : biggest radius

    float c1 = 50.; // base amount of cells
    float c2 = 15.; // max amount of added cells ( c2 < c1 )
    
    float t0 = time*2.; // change global speed
    
    float ta = t0*.2; // change animation speed : animation amplitude
    float tr = t0*.005; // change animation speed : starfield rotation
    float tn = t0*.009; // change animation speed : number of cells

    float h1freq = 1.;
    float h2freq = 2.;
    float h3freq = 3.;
    float h4freq = 4.;
    float th1 = t0*.0002; // change animation speed : diameter of the circles
    // calculate 4 harmonics
    float h1 = h1freq*sin(th1/h1freq);
    float th2 = t0*.1; // change animation speed of the 2nd harmonic 
    float h2 = h2freq*h1*(th2/h2freq); // change amplitude of the 2nd harmonic
    float th3 = t0*.11; // change animation speed of the 3rd harmonic
    float h3 = h3freq*h1*(th3/h3freq); // change amplitude of the 3rd harmonic
    float th4 = t0*.12; // change animation speed of the 4th harmonic
    float h4 = h4freq*h1*(th4/h4freq); // change animation speed of the 4th harmonic

    // build a complex wave with 2, 3 or 4 harmonics
    // float tVarD = h1+h2;
    // float tVarD = h1+h2+h3;
    float tVarD = h1+h2+h3+h4;
    
    // -----------------------------------------------------------------------------------------------
    
    // rotate the matrix
    float a = tr;
    float s = sin(a);
    float c = cos(a);
    uv *= mat2(c, -s, s, c);
    uv *= c1 + (sin(tn)*c2);

    vec2 gv = fract(uv)-.5; // set center of a single box
    vec2 id = floor(uv)+.5; // give each single box an id

    float m = 0.;

    // using the 8 cells surrounding main cell for drawing the circles
    for(float y=-1.; y<=1.; y++) {
        for(float x=-1.; x<=1.; x++) {
            vec2 offs = vec2(x, y);
            float d = length(gv-offs);
            float dist = length(id+offs)*(.25+(tVarD*.25)); // make the diameters pulsate
            float r = mix(r1, r2, sin(dist-ta)*.5+.5); // set min and max = animation amplitude

            m = Xor(m, smoothstep(r, r-.1, d));
        }
    }

    col += m;

    glFragColor = vec4(col, 1.);
}
