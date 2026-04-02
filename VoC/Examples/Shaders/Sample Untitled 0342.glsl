#version 420

#define OCTAVES  8.0

uniform float time;
uniform vec2 mouse;
uniform float resolution;

out vec4 glFragColor;

float rand2(vec2 co){
   return fract(cos(dot(co.xy ,vec2(12.9898,78.233))) * 4.5453);
}

float valueNoiseSimple(vec2 vl) {
   float minStep = 1.0 ;

   vec2 grid = floor(vl);
   vec2 gridPnt1 = grid;
   vec2 gridPnt2 = vec2(grid.x, grid.y + minStep);
   vec2 gridPnt3 = vec2(grid.x + minStep, grid.y);
   vec2 gridPnt4 = vec2(gridPnt3.x, gridPnt2.y);

    float s = rand2(gridPnt1);
    float t = rand2(gridPnt3);
    float u = rand2(gridPnt2);
    float v = rand2(gridPnt4);

    float x1 = smoothstep(0., 1., fract(vl.x));
    float interpX1 = mix(s, t, x1);
    float interpX2 = mix(u, v, x1);

    float y = smoothstep(0., 1., fract(vl.y));
    float interpY = mix(interpX1, interpX2, y);

    return interpY;
}

float fractalNoise(vec2 vl) {
    float persistance = 2.;
    float amplitude = 0.6;
    float rez = 0.0;
    vec2 p = vl;

    for (float i = 0.0; i < OCTAVES; i++) {
        rez += amplitude * valueNoiseSimple(p);
        amplitude /= persistance;
        p *= persistance;
    }
    return rez;
}

float complexFBM(vec2 p) {
    float slow = time / 8.; //Determins speed of large slow movements keep between 15 and 5
    float fast = time / (slow / 2.); // determins speed of small fast movements keep between 2.5 and .8, kept proportional to slow
    vec2 offset1 = vec2(slow  , 0.);
    vec2 offset2 = vec2(sin(fast)* 0.1, 0.);

    return 
        // x = darkness?
        (1.9 + 0.35) *
        fractalNoise( p + offset1 + fractalNoise(
            p + fractalNoise(
                p + 1. * fractalNoise(p - offset2)
            )
        )
        );
}

void main( void ) {
    float resolution =1920.0;
    vec2 p =5.0* ( gl_FragCoord.xy / resolution ) -1.0; //scale of noise over all
    vec3 col = vec3(0.5);    //brightness of white? 
    vec3 rez = mix(col.xyz, col.xyz * 0.3, complexFBM(p) * 2.00 + p.y * -0.2 - sin((time * 1.0) * 0.1) * 0.3 - 0.5); //determins something as well as speed of flashing

    glFragColor = vec4(rez,1.0)* vec4(.67,.83,.65,1.); //color 
}
