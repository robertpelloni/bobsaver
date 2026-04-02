#version 420

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

void main(void) {
	vec2 uv = (gl_FragCoord.xy/resolution.xy);
	double gray = dot(texture2D(image,uv).rgb,vec3(0.299, 0.587, 0.114));
    glFragColor = vec4( gray, gray, gray, 1.0 );
}
