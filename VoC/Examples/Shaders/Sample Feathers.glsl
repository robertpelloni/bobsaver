#version 420

// original https://www.shadertoy.com/view/tlcBW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S smoothstep

mat2 Rot(float a){
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

// Returns 2 random floats between 0. and 1.
vec2 HASH12(float i)
{
    float x = fract(1234.789*sin(i * 3245.234));
    float y = fract(7846.15*cos(i * 9087.45));
    return vec2(x, y); 
}

// Return 1 random float between 0. and 1.
float HASH11(float i)
{
    float x = fract(4677.65 * sin(i*4356.23));
    return x;
}

float Feather(vec2 p) {
        // Draw the feather base shape
       float d = length(p-vec2(0., clamp(p.y, -.3, .3)));
       float r = mix(.1, .005, S(-.3, .3, p.y));
       float m = S(.01, .0, d-r);
       // Draw the feather strands
       float side = sign(p.x);
       float x = .9*abs(p.x)/r;
       float wave = (1.-x)*sqrt(x) + x*(1.-sqrt(1.-x));
       float numStrands = 500.;
       float y = (p.y-wave*.2) * numStrands + side*56.;
       float id = floor(y+20.);
       float n = fract(sin(id*564.32)*763.);            // Get a random number
       float shade = mix(.3, 1., n);
       float strandLength = mix(.7, 1., fract(n*10.));
       
       float strand = S(.95, .05, abs(fract(y) - .5)-.3);
       strand *= S(.1, .0, x-strandLength);
       
       d = length(p-vec2(0., clamp(p.y, -.45, .1)));
       float stem = S(.004, .0, d+p.y*.0125);
       
       return max(m * strand * shade, stem);
}

void main(void)
{
    // Normalized pixel coordinates (from -.5 to .5)
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy)/resolution.y;
    // Draw the background color
    vec3 col = vec3(222. / 255., 248. / 255., 1.);
    vec3 c1 = vec3(32. / 255., 165. / 255., 201. / 255.);
    col = mix(c1, col, (uv.y + .5));
    
    int fc = 250;
    // Draw the Features
    for(int i = 0; i < fc; i++)
    {
        // Setup feather UV
        vec2 fUV = uv;
        
        // Scale the feather
        float rand1 = HASH11(float(i));           // Random between 0 and 1
        rand1 = 10. * rand1 + .5;
        float uvScale = 2. * rand1;
        fUV *= uvScale;
        
        
        // Set the Start time for x and y animation
        vec2 rand2 = HASH12(float(i));
        // Apply "gravity" to each feather
        float yScale = uvScale * 3.;
        fUV.y -= yScale * .5;
        float t1 = time + rand2.y * 250.;
        fUV.y += 2. * yScale * sin(fract(t1*.25/yScale));       // Move largers feathers faster
        // Apply octaves to y
        float y1 = .001 * yScale * sin(fract(t1 * .25/yScale) * 2. * 3.141593);
        float y2 = .005 * yScale * sin(2. * fract(t1 * .125/yScale) * 2. * 3.141593);
        fUV.y += y1 + y2;
        // Apply random x-distribution
        float t2 = (time + rand2.x + 250.) * .5;
        float x1 = uvScale * sin(fract(t2*.25/uvScale) * 2. * 3.141593);
        float x2 = .05 * uvScale * sin(2. * fract(t2*.05/uvScale) * 2. * 3.141593);
        float x3 = .025 * uvScale * sin(4. * fract(t2*.025/uvScale) * 2. * 3.141593);
        float x4 = .0125 * uvScale * sin(8. * fract(t2*.0125/uvScale) * 2. * 3.141593);
        fUV.x -= x1 + x2 + x3 + x4;
        
        
        // Rotate the feather's UV
        float fR = fract(rand2.x * 1012.) * time;
        fUV *= Rot(fR * 2. * 3.141593 * .25);

        // Bend the feather
        fUV -= vec2(0, -.45);
        float d = length(fUV);
        float rb = fract(rand1 * 2451.);        // Random number between 0. and 1.
        fUV *= Rot(sin(time * rb) * d);
        fUV += vec2(0, -.45);

        col = mix(vec3(col), vec3(1), Feather(fUV));
    }
    // Output to screen
    glFragColor = vec4(col,1.0);
}
