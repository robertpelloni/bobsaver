#version 420

// original https://www.shadertoy.com/view/MtdBWN

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Pi     3.14159265359
#define Tau    6.28318530718
#define Rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define RadiusIncrease 0.08

float TriangleSd(vec2 uv, float radius)
{
    return max(0.866025*abs(uv.x) + 0.5*uv.y, -uv.y) - 0.5*radius;
}

float Triangle(vec2 uv)
{
    uv = Rot(-0.3*time) * uv;
    return smoothstep(0.782, 1.0, 1.0-TriangleSd(uv, 0.5 + 0.1*cos(time)));
}

float SpiralTurn(vec2 uv, float turn)
{
    // Polar coordinates:
    float r = length(uv);
    float a = Pi+atan(uv.y, uv.x);
    
    // Turn angle:
    a += Tau*turn;
    
    // Polar function:
    float tr = Triangle(uv);
    float am = 0.35*tr*smoothstep(0.0, 0.1, r);
    float p = RadiusIncrease*(a/Tau + am*sin(-4.0*time+0.54*a*a));
    
    return r-p;
}

float SpiralTurnDe(vec2 uv, float turn)
{
    // IQ's |f|/|Grad(f)| distance estimator:
    float f = SpiralTurn(uv, turn);
    vec2 eps = vec2(0.00005, 0);
    vec2 grad = vec2(
        SpiralTurn(uv + eps.xy, turn) - SpiralTurn(uv - eps.xy, turn),
        SpiralTurn(uv + eps.yx, turn) - SpiralTurn(uv - eps.yx, turn)) / (2.0*eps.x);
    
    return f/length(grad);
}

float Spiral(vec2 uv, float eps)
{
    // Modulation source:
    float tr = Triangle(uv);

    // Split in concentric rings:
    float r = length(uv);
    float turn = floor(r/RadiusIncrease);
    
    // Draw a spiral contained in a ring + adjacent ones to handle overlap:
    float thick = 0.0040*tr;
    float aa = 1.2*eps;
    float d;
    d  = smoothstep(thick, thick+aa, abs(SpiralTurnDe(uv, turn)));
    d *= smoothstep(thick, thick+aa, abs(SpiralTurnDe(uv, turn+1.0)));
    d *= smoothstep(thick, thick+aa, abs(SpiralTurnDe(uv, turn-1.0)));
    return d;
}

// Randomly dither colors for smoother gradients
void Dither()
{
    // Position + Time Hash (based on Dave Hoskins hash33):
    vec3 p3 = fract(vec3(gl_FragCoord.xy, frames) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    vec3 hash = fract((p3.xxy + p3.yxx)*p3.zyx);
    
    // RGB Dithering:
    float softness = 255.0; // Should be 255. Lower value for grainy/fuzzy effect.
    glFragColor.rgb = (floor(softness*glFragColor.rgb) + step(hash, fract(softness*glFragColor.rgb)))/softness;
}

void main(void)
{
    // Normalized coordinates:
    float eps = 2.0/resolution.y;
    vec2  uv =  eps*(gl_FragCoord.xy - 0.5*resolution.xy);
    uv.x = -uv.x;
    
    //uv *= Rot(-0.15*time);
    
    // Polar:
    float r = length(uv);
    //float a = atan(uv.y, uv.x);

    
    // Back:
    vec3 back = vec3(0.20, 0.25, 0.3);
    // - Add vignetting:
    back *= mix(0.237, 1.0, pow(smoothstep(2.0, 2.0*0.45, r), 4.0*0.1637));

        
    // Disk:
    vec3 disk = vec3(0.904, 0.902, 0.827);
    
    // - Add Grid:
    float grid = mod(floor(r/RadiusIncrease), 2.0);
    disk = mix(disk, vec3(0.836,0.848,0.840), grid);
    
    // - Add inner shadow:
    disk *= mix(0.023, 1.0, pow(smoothstep(0.9, 0.75, r), 0.4));
    
    // - Add spiral:
    disk = mix(0.2*disk, disk, pow(Spiral(uv, eps), 0.45));

    
    // Combine Back and Disk:
    float mask = smoothstep(0.9+eps, 0.9, r);
    vec3 col = mix(back, disk, mask);

    
    // Output:
    glFragColor = vec4(col,1.0);
    
    
    // Dither post-process:
    Dither();
}
