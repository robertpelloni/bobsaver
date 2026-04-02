#version 420

// original https://www.shadertoy.com/view/lsjBRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// simple noise from: https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float rand(float n){return fract(sin(n) * 43758.5453123);}
float noise(float p){
    float fl = floor(p);
      float fc = fract(p);
    return mix(rand(fl), rand(fl + 1.0), fc);
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    uv.x += 0.2 * sin(time + uv.y * 4.);
    float numLines = 15. + gl_FragCoord.y * 0.4;
    float colNoise = noise(0.6 * uv.x * numLines);
    float colStripes = 0.5 + 0.5 * sin(uv.x * numLines * 0.75);
    float col = mix(colNoise, colStripes, 0.5 + 0.5 * sin(time));
    float aA = 1./(resolution.x * 0.005) ;
    col = smoothstep(0.5 - aA, 0.5 + aA, col);
    glFragColor = vec4(vec3(col),1.0);
}
    
