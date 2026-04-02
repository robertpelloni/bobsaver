#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Rnd(int seedA, int seedB) {
    return fract(sin(float(seedA)*264.245 - float(seedB)*625.345) * 9425.234);
}

void main( void ) {

    glFragColor=vec4(0.0);
    vec2 p = ( gl_FragCoord.xy / resolution.xy ) - 0.5;
    p.y *= resolution.y / resolution.x;
    float pxDist = pow(length(p) * 3.5, 0.2);
    float pxAng = atan(p.y, p.x);
    float pi = 3.14159;

    for (int n=0; n<350; n++) {
        float starAng = Rnd(382, n) * pi * 2.0;
        float starSpeed = 0.04 + pow(Rnd(842, n), 3.0);
        float starDist = fract(Rnd(843, n) + time * 0.5 *  starSpeed) * 1.5 - 0.25;

        if (starAng > pxAng + pi) {starAng -= pi*2.0;}
        if (starAng < pxAng - pi) {starAng += pi*2.0;}
        
        float bri = max(0.0, (1.5 - abs(starAng - pxAng) * 300.0 * pxDist) * pow(pxDist, 5.0));
        float starMag = 2.0 + 3.0 * Rnd(493, n);
        float rainbow = 0.05 * mouse.y;
        glFragColor.r += bri * max(0.0, starMag * starSpeed - 100.0 *  abs(pxDist - starDist));
        glFragColor.g += bri * max(0.0, starMag * starSpeed - 100.0 *  abs(pxDist - starDist + rainbow * starSpeed));
        glFragColor.b += bri * max(0.0, starMag * starSpeed - 100.0 *  abs(pxDist - starDist + rainbow * starSpeed * 2.0));
    }

    glFragColor.b += (pxDist - 0.3) * 0.1;
    glFragColor.g += (pxDist - 0.3) * 0.05;
    glFragColor.a = 1.0;
}
