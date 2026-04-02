#version 420

// original https://www.shadertoy.com/view/NlcGzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi acos(-1.)
#define M1 1597334677U
#define hash(n) float(n*(n^(n>>15)))/float(0xffffffffU)

void main(void) {
    vec2 R = resolution.xy,
         uv = (2.*gl_FragCoord.xy-R)/R.x;
    
    vec4 O = vec4(0.);
    for (int k = 0; k<3; k++) { //Loop over layers of wires
        for (int i = -7; i<=10; i++) { //Loop over neighboring wires
            vec2 s = uv+vec2(i,0)/40.;
            float sx0 = floor(s.x*40.);

            vec2 p = vec2(0.);
            float f = hash(uint(float(k*100)+s.x*40.+100.)*M1)*0.1;
            for (int j = 1; j<10; j++) { //Create a wave function
                f = f*1.3+.1;
                float t = (s.y*f+time*(1.-s.y*.5)*.1)*12.+f*100.;
                p += vec2(sin(t),(f-.04*time)*cos(t))/f*.1;
            }
            float x = uv.x*40.-p.x*float(1+k)*min(time*.3,1.);
            x = (x-sx0-.5)/sqrt(p.y*p.y+1.)+sx0+.5; //Better thickness
            
            if (x>sx0 && x<1.+sx0)
                O = (pow(cos((hash(uint(x+100.)*M1)*2.4+vec3(-.1,.6,.7))*pi*.6)*.5+.6,vec3(1,2,3))*(1.-pow((fract(x)-.5)*1.9,2.))).rgbb;
            else
                O = O*min((abs(x-sx0-.5)-.2)*.65,1.);
        }
    }
    O = pow(O,vec4(1./2.2));
	glFragColor = O;
}
