#version 420

// original https://www.shadertoy.com/view/tscBDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Logarithmic Spiral Center
    -------------------------

    This finds your final position when recursively applying a
    translation rotation scale matrix, but without doing the
    actual recursion.

    It looks at the triangle formed by the first two points and
    the center of the spiral, then calculates the center from known
    side and angle relations...

               4---3
              /     \
             5  x    \
              \_/     2
                     /
                    /  
                   /   
        0---------1 

    triangles formed by first three points and the spiral center:       

                x_    
               /| ```-2
             /` |    /
           /`    |  /  
         /`      | /   
        0---------1 

    note that the segment angle is the same as the iteration rotation:

                x_    
               /| ```-2
             /`y|    /
           /`    |  /  
         /`      | /y 
        0---------1 - - - -

    and that the adjacent sides are related by the iteration scale (s):

                x     
               /|
          a  /`y| b
           /`    |
         /`      | 
        0---------1
             c

        b = a * s

    side c is given by law of cosines:

        c = sqrt(a^2 + b^2 - 2 * a * b * cos(y))

       substituting a * s for b:

        c = sqrt(a^2 + (a * s)^2 - 2 * a * (a * s) * cos(y))

    solve for a:
    https://www.wolframalpha.com/widgets/view.jsp?id=c778a2d8bf30ef1d3c2d6bc5696defad
    
        a = c / sqrt(s^2 - 2 * s * cos(y) + 1)

    and get b:
    
        b = a * s;

    find opposite angle to side b using sine law:

                x     
               /|
          a  /`y| b
           /`    |
         /`k     | 
        0---------1
             c

        k = a * sin(b * sin(y) / c);

    find center using side a and angle k...
    

*/

vec2 spiralCenter(vec2 translation, float rotation, float scale) {
    // find sides and angles of segment triangle
    float c = length(translation);
    float a = c / sqrt((scale * scale) - 2. * scale * cos(rotation) + 1.);
    float b = a * scale;
    float k = asin(b * sin(-rotation) / c);
    // add angle from translation and calculate center
    k += atan(translation.x, translation.y);
    vec2 center = vec2(sin(k), cos(k)) * a;
      return center;
}

// shortened version from FabriceNeyret2
// https://www.shadertoy.com/view/WdVczz
// I'd like to explain this, but I don't know the steps taken
vec2 spiralCenter2(vec2 translation, float rotation, float scale) { 
    float l = sqrt(scale * scale - 2. * scale * cos(rotation) + 1.);
    float S = sin(rotation) * scale / l;
    float C = sqrt(1. - S * S);
    return mat2(-S, C, C, S) * translation.yx / l;
}

// Matrix functions
// --------------------------------------------------------

mat3 translateM(vec2 t) {
    return mat3(1, 0, t.x, 0, 1, t.y, 0, 0, 1);
}

mat3 rotateM(float a) {
    return mat3(cos(a), -sin(a), 0, sin(a), cos(a), 0, 0, 0, 1);
}

mat3 scaleM(vec2 s) {
    return mat3(s.x, 0, 0, 0, s.y, 0, 0, 0, 1);
}

mat3 trsMatrix(vec2 translation, float rotation, float scale) {
    return scaleM(vec2(scale)) * rotateM(rotation) * translateM(translation);
}

vec2 mul(vec2 p, mat3 m) {
   return (vec3(p, 1) * m).xy;
}

// Drawing
// --------------------------------------------------------

vec3 col;

void draw(float d, vec4 c) {
    d /= fwidth(d);
    d = clamp(d, 0., 1.);
    d = 1. - d;
    d *= c.a;
    col = mix(col, c.rgb, d);
}

void draw(float d, vec3 c) {
    draw(d, vec4(c, 1));
}

float line(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

// Demo
// --------------------------------------------------------

#define PI 3.1415926

void main(void)
{
    vec2 p = (-resolution.xy + 2.*gl_FragCoord.xy)/resolution.y;

    p -= vec2(-1,0);
    
    col = vec3(.014,.01,.02);
    
    float beat = sin(time) * .5 + .5;
    float beat2 = sin(time / 2.) * .5 + .5;
    
    
    // Translation, rotation, scale for each iteration
    
    float a = mix(PI / 2., -PI / 2., beat) * (beat2) + PI / 2.;
      vec2 trs = vec2(sin(a), cos(a)) * mix(.75, .4, beat2);
    float rot = mix(1., -1., beat);
    float scl = mix(.5, .99, beat2);
    
    
    // Calculate center
    
    vec2 center = spiralCenter(trs, rot, scl);    

    
    // Draw spiral
    
    mat3 mat = trsMatrix(trs, rot, scl);
    mat3 compound = mat;   
    vec2 pt = vec2(0);
    vec2 lastPt = pt;
    
    int n = 20;
    for (int i = 0; i < n; i++) {
        
        float t = float(i) / float(n);
        t = pow(t, .5);
        float fade = smoothstep(1., .75, t);

        draw(line(p, center, pt) - .0025, vec4(1, 1, 1, .1 * fade));
        draw(length(p - pt) - .015, vec4(0,.33,.33, fade));
        draw(line(p, lastPt, pt) - .01, vec4(0,.33,.33, .2 * fade));
        
        lastPt = pt;
        pt = mul(vec2(0), compound);
        compound = mat * compound;
    }
    
    
    // Draw center

    draw(length(p - center) - .03, vec3(1));    
    
    
    col = pow(col, vec3(1./2.2));
    glFragColor = vec4(col,1.0);
}
