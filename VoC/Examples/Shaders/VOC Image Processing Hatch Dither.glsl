// https://www.shadertoy.com/view/WdXXRX

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

void main() {
	vec4 O = gl_FragColor;
	vec2 u = gl_FragCoord.xy;
	
    vec2 R = resolution.xy;
    
    float N = 16., a = pow(length(texture(image, u/R).rgb),1.3), x = floor(a*N)/N;
    
    vec3 p = vec3((u+u-R)/R.y,1) * (4. + N * x);
    
    
    p = vec3(fract(p.xy),p.z)*2.-vec3(1,1,0);
    O += x * smoothstep(1.5/R.y,0., (.5*min(abs(p.y-p.x),abs(p.x+p.y))-1./R.y) /p.z );
	
	glFragColor = O;
}
