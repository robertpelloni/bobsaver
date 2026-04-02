#version 420

// original https://www.shadertoy.com/view/csdXW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define a(a,b,f,o) mix(a,b,sin(o+e*f)*.5+.5)
#define s(a) mat2(cos(a+vec4(0,33,11,0)))

void main(void) { //WARNING - variables void (out vec4 O, vec2 F) { need changing to glFragColor and gl_FragCoord.xy
    vec4 O = vec4(0.0);
	vec2 F = gl_FragCoord.xy;

	float c , 
          o , 
          d = 3., 
          e = time*0.1;
    vec2  r = resolution.xy; 
    
    for (;o++<2e2 && d>.001;) {
        vec3 p = abs(.7*c*normalize(vec3((F+F-r)/r.y, 1)));
        p.xy *= s(e);
        p.zy += e + c*cos(2.*e);
        p = fract(p)-.5;
        p.xy *= s(c);
        p.xz *= s(e*2.);
        p.y = max(abs(p.y)-a(0.,.2,1.,),0.);
        c += d = (length(vec2(length(p.xy)-.2,p.z)) 
                 -a(.04,.1,.5,4.) - c*.01)*.5;
    }

    float glowIntensity = 0.25 * (cos(time * 1.0 * 2.0 * 3.14159) * -0.5 + 0.5);
    O.rgb = 1.4*(cos(c*110. + .99*vec3(0,1.+c*.2,2))+.3)/exp(c*0.0914);
    O.rgb += glowIntensity * vec3(0.25, 0.35, 0.5) * pow(c, 2.0);

	glFragColor = O;
}
