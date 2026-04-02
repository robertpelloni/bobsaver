#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uniform sampler2D backbuffer;

float waveLength = .009;//aktually fwequensee
float PI = 3.14159265358979323846264;

void main( void ) {
    vec2 uv = gl_FragCoord.xy/resolution;
    //float produkt = 1.;
    float sumx = 0.;
    float sumy = 0.;
    for(float i = 0.4; i < .6; i += 0.05){
        vec2 p1 = vec2(i, .5);

        float d1 = 1. - length(uv - p1);

        float wave1x = sin(d1 / waveLength * PI);
        float wave1y = cos(d1 / waveLength * PI);
        sumx = wave1x + sumx;
        sumy = wave1y + sumy;
        //produkt = produkt * wave1;
    }

    glFragColor = vec4(0.);
    glFragColor.x = sqrt(pow(sumx , 2.) + pow(sumy , 2.)) / (5.);

    // "bumpmapping" and colors by @Flexi23
    vec2 d = 4./resolution;
    float dx = texture2D(backbuffer, uv + vec2(-1.,0.)*d).x - texture2D(backbuffer, uv + vec2(1.,0.)*d).x ;
    float dy = texture2D(backbuffer, uv + vec2(0.,-1.)*d).x - texture2D(backbuffer, uv + vec2(0.,1.)*d).x ;
    d = vec2(dx,dy);
    glFragColor.z = pow(clamp(1.-1.5*length(uv  - mouse + d),0.,1.),4.0);
    glFragColor.y = glFragColor.z*0.5 + glFragColor.x*0.35;

}
