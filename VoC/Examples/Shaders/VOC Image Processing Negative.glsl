#version 420

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

void main(void) {
	vec2 uv = (gl_FragCoord.xy/resolution.xy);
	vec4 col = texture2D(image,uv);
    glFragColor = vec4(1-col.rgb, 1.0);
}
