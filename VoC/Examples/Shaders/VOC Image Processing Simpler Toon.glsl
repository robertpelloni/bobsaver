// https://www.shadertoy.com/view/ldsfzH

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

// SimpleToon - a simple toon effect by Jakob Thomsen
void main(){
	glFragColor = floor( texture(image, gl_FragCoord.xy/resolution.xy) * 3.) / 3.; 
}