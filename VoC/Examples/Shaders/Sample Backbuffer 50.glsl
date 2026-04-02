#version 420

// afl_ext 2017
// it will be black for some seconds and then effect begins

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D bb;

out vec4 glFragColor;

float rand2sTime(vec2 co){
    co *= time;
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    vec2 pixel = ( 1.0 / resolution.xy );

    vec3 color = vec3(0.0);
    for(int i=0;i<5;i++){
        vec3 pixel = vec3(1.0 / resolution, 0.0) * float(5 + i);
        float a = texture2D(bb, position + pixel.xz).a * 0.25;
        float b = texture2D(bb, position - pixel.xz).a * 0.25;
        float c = texture2D(bb, position + pixel.zy).a * 0.253;
        float d = texture2D(bb, position - pixel.zy).a * 0.25;
        color -= (a+b+c+d) * 0.25 * 0.01 + 0.005 * (a+b+c+d);
        vec2 dfx = vec2(a-b, c-d);
        color.r += texture2D(bb, position - pixel.xy * dfx * 7.0 * float(5 + i)).a;
    }
    color.r /= 5.0;
    color.r +=  0.01 * ( rand2sTime(position)) * (smoothstep(0.0, 0.01, distance(mouse, position)) * 0.4 + 0.6);
    vec3 xcc = vec3(1.0, 0.8, 0.0) - (1.0 / (pow(color.r * 1.53, 14.0) * 2.0 + 1.0)) * vec3(1.0, 1.1, 0.0);
    xcc = normalize(xcc) * sqrt(length(xcc));
    glFragColor = vec4(xcc, color.r);

}
