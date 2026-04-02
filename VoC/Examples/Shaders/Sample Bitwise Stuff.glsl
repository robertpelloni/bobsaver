#version 420

// original https://www.shadertoy.com/view/XtSSWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool XOR(bool a, bool b) {
    return (a && !b) || (b && !a);
}

bool AND(bool a, bool b) {
    return a && b;
}

int bitwiseOperation(int x, int y) {
    int outval = 0;
    ivec2 xy = ivec2(x,y);
    for (int i=0; i<30; ++i) {
        ivec2 shift = xy / 2;
        
        ivec2 lowestBit = xy - shift * 2;
        
        //outval *= 2;  // if this is disabled, we count the bits rather than interpret the number
        if (XOR(lowestBit.x != 0, lowestBit.y != 0)) {
           outval += 1;
        }
        
        xy = shift;
    }
    return outval;
}

// makes a rotation matrix
mat2 rotate(float theta) {
    float s = sin(theta);
    float c = cos(theta);
    return mat2(
        c, -s,
        s,  c
    );
}

vec2 swirl(vec2 toSwirl, vec2 center, float amonut) {
    float rotateRadius = 1.04;
    vec2 p = toSwirl; // out
    p += center;
    p *= rotate((rotateRadius / -length(p)) * amonut);
    p -= center;
    return p;
}

vec4 main2(in vec2 Coord) {
    
    const float timeScale = 5.0;
    const float repeatPeriod = 10.0;
    float time = time * timeScale;
    time = mod(time, repeatPeriod * timeScale);
    Coord -= resolution.xy / 2.0;
    vec2 p = Coord;
    
    // do some non-linear transformations
    vec2 translate = vec2(0.0, -100.0);
    p = swirl(p, translate, time * 5.0);
    p = swirl(
        p, 
        swirl(-translate, -translate, time * 5.0),
        time * -5.0
    );
 
    int x = int(p.x);
    int y = int(p.y);
    vec2 uv = p.xy / resolution.xy;
    int bit = bitwiseOperation(x, y);
    float val = float(bit);
    float exposure = 0.1;//mouse*resolution.xy.x / 3000.0;
    val = 1.0 - exp(-val * exposure);
    
    return vec4(val);
}

void main(void)
{
    glFragColor = main2(gl_FragCoord.xy);
    
    if (true) {  // antialiasing
        float AAradius = 0.5;
        glFragColor += main2(gl_FragCoord.xy + AAradius * vec2( 1.0,  0.0));
        glFragColor += main2(gl_FragCoord.xy + AAradius * vec2(-1.0,  0.0));
        glFragColor += main2(gl_FragCoord.xy + AAradius * vec2( 0.0,  1.0));
        glFragColor += main2(gl_FragCoord.xy + AAradius * vec2( 0.0, -1.0));
        glFragColor /= 5.0;
    }
    
}
