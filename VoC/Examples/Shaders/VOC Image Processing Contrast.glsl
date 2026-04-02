// https://www.shadertoy.com/view/ldVGRt

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

void contrast( inout vec3 color, float adjust ) {
    adjust = adjust + 1.0;
    color.rgb = ( color.rgb - vec3(0.5) ) * adjust + vec3(0.5);
}

void main()
{
	vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 color = texture(image, uv).rgb;
    contrast(color, 1.0);
	glFragColor = vec4(color, 1.0);
}