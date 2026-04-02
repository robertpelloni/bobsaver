// original https://www.shadertoy.com/view/4Xfcz7
#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// Just a doodle
//
// (c) timestamp @ shadertoy.com
//
// Basically a terminated spiral subjected to shift-abs-circle_Invert cycle
//

void main(void) {
    vec2 I = gl_FragCoord.xy;
    float A = .65 + sin(time * .3) * .5;
    mat2 m = mat2(cos(A), -sin(A), sin(A), cos(A));
    vec4 O = vec4(0.);
    for(vec2 aa; aa.x < 2.; aa.x+= .667) 
    for(aa.y=0.; aa.y < 2.; aa.y+= .667) {
        float a, k, y, i, r, f = 1.;
        vec2 p = (I + I + aa - resolution.xy) / resolution.y * 8.;        
        for(i = 0.; i < 20.; i++) {    
            a = (atan(p.y, p.x) / 3.14 + 1.) * .5;
            k = log(length(p) / (sin(p.x) * .1 + 1.2)) * 1.3 - a;
            y = fract(k);
            p = abs(p * m - vec2(-.33, .43)) - (vec2(.5,-.3) + vec2(sin(time * .12), cos(time * .31)) * .3);
            p = p / dot(p,p);        
            if(i <= 2. || floor(k) >= 3. || y >= .13 + i / 1e2) continue;
            if(y >= .11) { f *= ((y - .11) / (.02 + i / 1e2)); continue; }
            r = max( abs(fract(a * 60.) - .5), abs(y - .055) / .055 ); 
            if(r > .2) break;
            if(r > .17) { f = 0.; break; }
            f *= .55;
        }

        if(abs(y - .055) < .045)
            O.xyz += (vec3(.5,.1,.65) + sin(i * vec3(1,1.7,1.211)) * vec3(.5,.1,.35)) * (1. - (i / 20.)) * f;
    }
    O.xyz = pow(O.xyz / 9., vec3(.45));
    glFragColor = O;
}